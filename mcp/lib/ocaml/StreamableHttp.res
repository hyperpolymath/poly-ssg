// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Streamable HTTP Transport for MCP
// Implements the MCP Streamable HTTP transport (June 2025 spec)
// https://modelcontextprotocol.io/specification/2025-06-18/basic/transports

open Http

let protocolVersion = "2025-06-18"

// ============================================================================
// Logging
// ============================================================================

module LogLevel = {
  let debug = 0
  let info = 1
  let warn = 2
  let error = 3
}

let currentLogLevel = ref(LogLevel.info)

let setLogLevel = level => {
  currentLogLevel := level
}

let log = (level: int, message: string, context: option<JSON.t>) => {
  if level >= currentLogLevel.contents {
    let levelName = switch level {
    | 0 => "DEBUG"
    | 1 => "INFO"
    | 2 => "WARN"
    | _ => "ERROR"
    }
    let entry = Dict.make()
    Dict.set(entry, "timestamp", JSON.Encode.string(Date.make()->Date.toISOString))
    Dict.set(entry, "level", JSON.Encode.string(levelName))
    Dict.set(entry, "message", JSON.Encode.string(message))
    switch context {
    | Some(ctx) => Dict.set(entry, "context", ctx)
    | None => ()
    }
    Console.error(JSON.stringify(JSON.Encode.object(entry)))
  }
}

// ============================================================================
// Circuit Breaker (Fault Tolerance)
// ============================================================================

type circuitState = Closed | Open | HalfOpen

type circuitBreakerConfig = {
  failureThreshold: int,
  resetTimeoutMs: int,
  halfOpenRequests: int,
}

type circuitBreaker = {
  mutable state: circuitState,
  mutable failures: int,
  mutable lastFailureTime: option<float>,
  mutable halfOpenAttempts: int,
  config: circuitBreakerConfig,
}

let makeCircuitBreaker = (~failureThreshold=5, ~resetTimeoutMs=30000, ~halfOpenRequests=1, ()) => {
  state: Closed,
  failures: 0,
  lastFailureTime: None,
  halfOpenAttempts: 0,
  config: {
    failureThreshold,
    resetTimeoutMs,
    halfOpenRequests,
  },
}

let canExecute = (cb: circuitBreaker) => {
  switch cb.state {
  | Closed => true
  | Open =>
    switch cb.lastFailureTime {
    | Some(lastTime) =>
      if Date.now() -. lastTime > Float.fromInt(cb.config.resetTimeoutMs) {
        cb.state = HalfOpen
        cb.halfOpenAttempts = 0
        log(LogLevel.info, "Circuit breaker transitioning to HALF_OPEN", None)
        true
      } else {
        false
      }
    | None => false
    }
  | HalfOpen => cb.halfOpenAttempts < cb.config.halfOpenRequests
  }
}

let recordSuccess = (cb: circuitBreaker) => {
  if cb.state == HalfOpen {
    log(LogLevel.info, "Circuit breaker closing after successful request", None)
  }
  cb.failures = 0
  cb.state = Closed
  cb.halfOpenAttempts = 0
}

let recordFailure = (cb: circuitBreaker) => {
  cb.failures = cb.failures + 1
  cb.lastFailureTime = Some(Date.now())
  if cb.state == HalfOpen {
    cb.halfOpenAttempts = cb.halfOpenAttempts + 1
  }
  if cb.failures >= cb.config.failureThreshold {
    cb.state = Open
    let ctx = Dict.make()
    Dict.set(ctx, "failures", JSON.Encode.int(cb.failures))
    log(LogLevel.warn, "Circuit breaker OPEN", Some(JSON.Encode.object(ctx)))
  }
}

let getCircuitState = (cb: circuitBreaker) => {
  let result = Dict.make()
  let stateStr = switch cb.state {
  | Closed => "CLOSED"
  | Open => "OPEN"
  | HalfOpen => "HALF_OPEN"
  }
  Dict.set(result, "state", JSON.Encode.string(stateStr))
  Dict.set(result, "failures", JSON.Encode.int(cb.failures))
  JSON.Encode.object(result)
}

// ============================================================================
// Rate Limiter
// ============================================================================

type rateLimiterConfig = {
  windowMs: int,
  maxRequests: int,
}

type rateLimiter = {
  config: rateLimiterConfig,
  requests: Dict.t<array<float>>,
}

let makeRateLimiter = (~windowMs=60000, ~maxRequests=100, ()) => {
  config: {windowMs, maxRequests},
  requests: Dict.make(),
}

let isAllowed = (rl: rateLimiter, sessionId: string) => {
  let now = Date.now()
  let windowStart = now -. Float.fromInt(rl.config.windowMs)
  let timestamps = switch Dict.get(rl.requests, sessionId) {
  | Some(ts) => Array.filter(ts, t => t > windowStart)
  | None => []
  }
  if Array.length(timestamps) >= rl.config.maxRequests {
    false
  } else {
    let newTimestamps = Array.concat(timestamps, [now])
    Dict.set(rl.requests, sessionId, newTimestamps)
    true
  }
}

let cleanupRateLimiter = (rl: rateLimiter) => {
  let now = Date.now()
  let windowStart = now -. Float.fromInt(rl.config.windowMs)
  let keys = Dict.keysToArray(rl.requests)
  Array.forEach(keys, sessionId => {
    switch Dict.get(rl.requests, sessionId) {
    | Some(timestamps) =>
      let valid = Array.filter(timestamps, t => t > windowStart)
      if Array.length(valid) == 0 {
        Dict.delete(rl.requests, sessionId)
      } else {
        Dict.set(rl.requests, sessionId, valid)
      }
    | None => ()
    }
  })
}

// ============================================================================
// Session Store
// ============================================================================

type session = {
  id: string,
  createdAt: float,
  mutable lastAccess: float,
  mutable initialized: bool,
  mutable pendingMessages: array<JSON.t>,
  mutable eventCounter: int,
  mutable requestCount: int,
  mutable errorCount: int,
}

type sessionStore = {
  sessions: Dict.t<session>,
  ttlMs: int,
}

let makeSessionStore = (~ttlMs=1800000, ()) => {
  sessions: Dict.make(),
  ttlMs,
}

let createSession = (store: sessionStore) => {
  let sessionId = generateSessionId()
  let now = Date.now()
  let session = {
    id: sessionId,
    createdAt: now,
    lastAccess: now,
    initialized: false,
    pendingMessages: [],
    eventCounter: 0,
    requestCount: 0,
    errorCount: 0,
  }
  Dict.set(store.sessions, sessionId, session)
  let ctx = Dict.make()
  Dict.set(ctx, "sessionId", JSON.Encode.string(sessionId))
  log(LogLevel.debug, "Session created", Some(JSON.Encode.object(ctx)))
  session
}

let getSession = (store: sessionStore, sessionId: string) => {
  switch Dict.get(store.sessions, sessionId) {
  | Some(session) =>
    session.lastAccess = Date.now()
    Some(session)
  | None => None
  }
}

let deleteSession = (store: sessionStore, sessionId: string) => {
  let ctx = Dict.make()
  Dict.set(ctx, "sessionId", JSON.Encode.string(sessionId))
  log(LogLevel.debug, "Session deleted", Some(JSON.Encode.object(ctx)))
  Dict.delete(store.sessions, sessionId)
}

let cleanupSessions = (store: sessionStore) => {
  let now = Date.now()
  let ttl = Float.fromInt(store.ttlMs)
  let keys = Dict.keysToArray(store.sessions)
  let cleaned = ref(0)
  Array.forEach(keys, id => {
    switch Dict.get(store.sessions, id) {
    | Some(session) =>
      if now -. session.lastAccess > ttl {
        Dict.delete(store.sessions, id)
        cleaned := cleaned.contents + 1
      }
    | None => ()
    }
  })
  if cleaned.contents > 0 {
    let ctx = Dict.make()
    Dict.set(ctx, "count", JSON.Encode.int(cleaned.contents))
    log(LogLevel.debug, "Sessions cleaned up", Some(JSON.Encode.object(ctx)))
  }
}

let nextEventId = (session: session) => {
  session.eventCounter = session.eventCounter + 1
  session.id ++ "-" ++ Int.toString(session.eventCounter)
}

let getSessionStats = (store: sessionStore) => {
  let result = Dict.make()
  Dict.set(result, "activeSessions", JSON.Encode.int(Dict.keysToArray(store.sessions)->Array.length))
  JSON.Encode.object(result)
}

// ============================================================================
// SSE Utilities
// ============================================================================

let formatSSEEvent = (data: JSON.t, eventId: option<string>) => {
  let event = "event: message\n"
  let event = event ++ "data: " ++ JSON.stringify(data) ++ "\n"
  let event = switch eventId {
  | Some(id) => event ++ "id: " ++ id ++ "\n"
  | None => event
  }
  event ++ "\n"
}

type sseStream = {
  stream: readableStream<Js.TypedArray2.Uint8Array.t>,
  send: (JSON.t, option<string>) => unit,
  close: unit => unit,
}

let createSSEStream = () => {
  let encoder = makeTextEncoder()
  let controllerRef: ref<option<readableStreamController<Js.TypedArray2.Uint8Array.t>>> = ref(None)

  let stream = makeReadableStream({
    start: controller => {
      controllerRef := Some(controller)
    },
  })

  let send = (data: JSON.t, eventId: option<string>) => {
    switch controllerRef.contents {
    | Some(controller) =>
      let event = formatSSEEvent(data, eventId)
      enqueue(controller, encode(encoder, event))
    | None => ()
    }
  }

  let closeStream = () => {
    switch controllerRef.contents {
    | Some(controller) => close(controller)
    | None => ()
    }
  }

  {stream, send, close: closeStream}
}

// ============================================================================
// Transport Options
// ============================================================================

type transportOptions = {
  path: string,
  allowedOrigins: option<array<string>>,
  enableCors: bool,
  sessionTtlMs: int,
  requestTimeoutMs: int,
  enableRateLimiting: bool,
  rateLimitWindowMs: int,
  rateLimitMaxRequests: int,
  enableCircuitBreaker: bool,
}

let defaultOptions: transportOptions = {
  path: "/mcp",
  allowedOrigins: None,
  enableCors: true,
  sessionTtlMs: 1800000,
  requestTimeoutMs: 30000,
  enableRateLimiting: true,
  rateLimitWindowMs: 60000,
  rateLimitMaxRequests: 100,
  enableCircuitBreaker: true,
}

// ============================================================================
// Transport State
// ============================================================================

type messageHandler = JSON.t => promise<option<JSON.t>>
type closeHandler = unit => unit

type transportState = {
  options: transportOptions,
  sessions: sessionStore,
  circuitBreaker: circuitBreaker,
  rateLimiter: rateLimiter,
  mutable messageHandler: option<messageHandler>,
  mutable closeHandler: option<closeHandler>,
}

let makeTransport = (~options=defaultOptions, ()) => {
  options,
  sessions: makeSessionStore(~ttlMs=options.sessionTtlMs, ()),
  circuitBreaker: makeCircuitBreaker(),
  rateLimiter: makeRateLimiter(
    ~windowMs=options.rateLimitWindowMs,
    ~maxRequests=options.rateLimitMaxRequests,
    (),
  ),
  messageHandler: None,
  closeHandler: None,
}

let onMessage = (transport: transportState, handler: messageHandler) => {
  transport.messageHandler = Some(handler)
}

let onClose = (transport: transportState, handler: closeHandler) => {
  transport.closeHandler = Some(handler)
}

// ============================================================================
// Response Helpers
// ============================================================================

let jsonResponse = (
  ~transport: transportState,
  ~data: JSON.t,
  ~status=200,
  ~sessionId: option<string>=None,
) => {
  let headers = Dict.make()
  Dict.set(headers, "Content-Type", "application/json")
  Dict.set(headers, "MCP-Protocol-Version", protocolVersion)

  switch sessionId {
  | Some(id) => Dict.set(headers, "Mcp-Session-Id", id)
  | None => ()
  }

  if transport.options.enableCors {
    Dict.set(headers, "Access-Control-Allow-Origin", "*")
    Dict.set(
      headers,
      "Access-Control-Allow-Headers",
      "Content-Type, Mcp-Session-Id, MCP-Protocol-Version, Accept",
    )
    Dict.set(headers, "Access-Control-Expose-Headers", "Mcp-Session-Id, MCP-Protocol-Version")
  }

  makeResponse(Nullable.make(JSON.stringify(data)), {"status": status, "headers": headers})
}

let acceptedResponse = (~transport: transportState, ~sessionId: option<string>=None) => {
  let headers = Dict.make()
  Dict.set(headers, "MCP-Protocol-Version", protocolVersion)

  switch sessionId {
  | Some(id) => Dict.set(headers, "Mcp-Session-Id", id)
  | None => ()
  }

  if transport.options.enableCors {
    Dict.set(headers, "Access-Control-Allow-Origin", "*")
  }

  makeResponse(Nullable.null, {"status": 202, "headers": headers})
}

let sseResponse = (~transport: transportState, ~session: session, ~messages: array<JSON.t>) => {
  let sse = createSSEStream()

  Array.forEach(messages, msg => {
    sse.send(msg, Some(nextEventId(session)))
  })
  sse.close()

  let headers = Dict.make()
  Dict.set(headers, "Content-Type", "text/event-stream")
  Dict.set(headers, "Cache-Control", "no-cache")
  Dict.set(headers, "Mcp-Session-Id", session.id)
  Dict.set(headers, "MCP-Protocol-Version", protocolVersion)

  if transport.options.enableCors {
    Dict.set(headers, "Access-Control-Allow-Origin", "*")
    Dict.set(headers, "Access-Control-Expose-Headers", "Mcp-Session-Id, MCP-Protocol-Version")
  }

  makeResponse(Nullable.null, {"status": 200, "headers": headers})
}

let corsResponse = (
  ~transport: transportState,
  ~request: request,
  ~status=200,
  ~extraHeaders=Dict.make(),
) => {
  let headers = extraHeaders
  if transport.options.enableCors {
    let origin = switch get(request.headers, "Origin")->Nullable.toOption {
    | Some(o) => o
    | None => "*"
    }
    Dict.set(headers, "Access-Control-Allow-Origin", origin)
    Dict.set(headers, "Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
    Dict.set(
      headers,
      "Access-Control-Allow-Headers",
      "Content-Type, Mcp-Session-Id, MCP-Protocol-Version, Accept, Last-Event-ID",
    )
    Dict.set(headers, "Access-Control-Expose-Headers", "Mcp-Session-Id, MCP-Protocol-Version")
    Dict.set(headers, "Access-Control-Max-Age", "86400")
  }
  makeResponse(Nullable.null, {"status": status, "headers": headers})
}

let errorResponse = (~transport: transportState, ~message: string, ~status: int) => {
  let data = Dict.make()
  Dict.set(data, "error", JSON.Encode.string(message))
  jsonResponse(~transport, ~data=JSON.Encode.object(data), ~status)
}

// ============================================================================
// Health Check
// ============================================================================

let getHealth = (transport: transportState) => {
  let status = switch transport.circuitBreaker.state {
  | Open => "degraded"
  | _ => "healthy"
  }
  let result = Dict.make()
  Dict.set(result, "status", JSON.Encode.string(status))
  Dict.set(result, "circuitBreaker", getCircuitState(transport.circuitBreaker))
  Dict.set(result, "sessions", getSessionStats(transport.sessions))
  JSON.Encode.object(result)
}
