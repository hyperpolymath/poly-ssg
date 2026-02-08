// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Polyglot SSG MCP Server - Deno Entry Point
// Usage:
//   Local:  deno task start
//   HTTP:   deno task serve
//   Deploy: deno deploy (auto-detects HTTP mode)

open Mcp
open Server

// ============================================================================
// Adapter Imports (from compiled ReScript modules)
// ============================================================================

// The adapters are imported dynamically from the compiled ES6 output
// Each adapter module exports: name, language, description, connect, disconnect, isConnected, tools

@val @scope(("import", "meta"))
external importMeta: {..} = "default"

// Dynamic import for ES modules
@val external import_: string => promise<'a> = "import"

// ============================================================================
// Main Server
// ============================================================================

let createServer = (adapters: array<adapterModule>) => {
  let server = createMcpServer({
    name: "polyglot-ssg-mcp",
    version: packageVersion,
    description: "Unified MCP server for 29 static site generators across 20 languages",
  })

  // Register meta tools
  let emptySchema = Dict.make()
  Dict.set(emptySchema, "type", JSON.Encode.string("object"))
  Dict.set(emptySchema, "properties", JSON.Encode.object(Dict.make()))

  tool(
    server,
    "ssg_list",
    "List all available SSG adapters with their languages and connection status",
    emptySchema,
    async (_params: JSON.t) => {
      let handler = ssgListTool(adapters)
      let result = await handler()
      Obj.magic(result)
    },
  )

  tool(
    server,
    "ssg_detect",
    "Auto-detect which SSGs are installed on the system",
    emptySchema,
    async (_params: JSON.t) => {
      let handler = ssgDetectTool(adapters)
      let result = await handler()
      Obj.magic(result)
    },
  )

  let helpSchema = Dict.make()
  Dict.set(helpSchema, "type", JSON.Encode.string("object"))
  let helpProps = Dict.make()
  let ssgProp = Dict.make()
  Dict.set(ssgProp, "type", JSON.Encode.string("string"))
  Dict.set(ssgProp, "description", JSON.Encode.string("SSG name (e.g., 'zola', 'hakyll', 'franklin')"))
  Dict.set(helpProps, "ssg", JSON.Encode.object(ssgProp))
  Dict.set(helpSchema, "properties", JSON.Encode.object(helpProps))
  Dict.set(helpSchema, "required", JSON.Encode.array([JSON.Encode.string("ssg")]))

  tool(
    server,
    "ssg_help",
    "Get help for a specific SSG",
    helpSchema,
    async (params: JSON.t) => {
      let handler = ssgHelpTool(adapters)
      let result = await handler(params)
      Obj.magic(result)
    },
  )

  tool(
    server,
    "ssg_version",
    "Get version information for polyglot-ssg-mcp",
    emptySchema,
    async (_params: JSON.t) => {
      let handler = ssgVersionTool(adapters)
      let result = await handler()
      Obj.magic(result)
    },
  )

  // Register adapter tools
  Array.forEach(adapters, adapter => {
    Array.forEach(adapter.tools, t => {
      // Extract properties from inputSchema
      let schemaProps = switch JSON.Decode.object(t.inputSchema) {
      | Some(obj) =>
        switch Dict.get(obj, "properties") {
        | Some(props) =>
          switch JSON.Decode.object(props) {
          | Some(p) => p
          | None => Dict.make()
          }
        | None => Dict.make()
        }
      | None => Dict.make()
      }

      tool(
        server,
        t.name,
        t.description,
        schemaProps,
        async (params: JSON.t) => {
          let result = await executeAdapterTool(adapter, t, params)
          Obj.magic(result)
        },
      )
    })
  })

  server
}

// ============================================================================
// STDIO Mode
// ============================================================================

let startStdioMode = async (server: mcpServer, adapters: array<adapterModule>) => {
  logStartup(Stdio, adapters)
  let transport = createStdioTransport()
  await connect(server, transport)
}

// ============================================================================
// HTTP Mode
// ============================================================================

let startHttpMode = async (adapters: array<adapterModule>) => {
  let port = switch Deno.Env.get("PORT") {
  | Some(p) =>
    switch Int.fromString(p) {
    | Some(n) => n
    | None => 8000
    }
  | None => 8000
  }

  let host = switch Deno.Env.get("HOST") {
  | Some(h) => h
  | None => "0.0.0.0"
  }

  logStartup(Http, adapters)
  Console.error("Listening on http://" ++ host ++ ":" ++ Int.toString(port) ++ "/mcp")

  // Build tools list for HTTP mode
  let allTools = []

  // Meta tools info
  let metaTools = [
    ("ssg_list", "List all available SSG adapters with their languages and connection status"),
    ("ssg_detect", "Auto-detect which SSGs are installed"),
    ("ssg_help", "Get help for a specific SSG"),
    ("ssg_version", "Get version information"),
  ]

  Array.forEach(metaTools, ((name, description)) => {
    let t = Dict.make()
    Dict.set(t, "name", JSON.Encode.string(name))
    Dict.set(t, "description", JSON.Encode.string(description))
    Array.push(allTools, JSON.Encode.object(t))
  })

  // Adapter tools
  Array.forEach(adapters, adapter => {
    Array.forEach(adapter.tools, t => {
      let toolInfo = Dict.make()
      Dict.set(toolInfo, "name", JSON.Encode.string(t.name))
      Dict.set(toolInfo, "description", JSON.Encode.string(t.description))
      Dict.set(toolInfo, "inputSchema", t.inputSchema)
      Array.push(allTools, JSON.Encode.object(toolInfo))
    })
  })

  let languageCount = Array.length(getUniqueLanguages(adapters))

  // HTTP handler
  let handler = async (request: Http.request) => {
    let url = Http.makeUrl(request.url)

    // Health endpoint
    if url.pathname == "/health" {
      let health = Dict.make()
      Dict.set(health, "status", JSON.Encode.string("ok"))
      Dict.set(health, "version", JSON.Encode.string(packageVersion))
      Dict.set(health, "ssgs", JSON.Encode.int(Array.length(adapters)))
      Dict.set(health, "languages", JSON.Encode.int(languageCount))
      Http.jsonResponse(JSON.Encode.object(health), {"status": 200})
    } else if url.pathname == "/" || url.pathname == "/info" {
      // Info endpoint
      let ssgList = Array.map(adapters, a => {
        let item = Dict.make()
        Dict.set(item, "name", JSON.Encode.string(a.name))
        Dict.set(item, "language", JSON.Encode.string(a.language))
        JSON.Encode.object(item)
      })

      let info = Dict.make()
      Dict.set(info, "name", JSON.Encode.string("polyglot-ssg-mcp"))
      Dict.set(info, "version", JSON.Encode.string(packageVersion))
      Dict.set(info, "protocol", JSON.Encode.string("MCP Streamable HTTP"))
      Dict.set(info, "protocolVersion", JSON.Encode.string("2025-06-18"))
      Dict.set(info, "endpoint", JSON.Encode.string("/mcp"))
      Dict.set(info, "ssgs", JSON.Encode.array(ssgList))
      Dict.set(
        info,
        "documentation",
        JSON.Encode.string("https://github.com/hyperpolymath/polyglot-ssg-mcp"),
      )
      Http.jsonResponse(JSON.Encode.object(info), {"status": 200})
    } else if url.pathname == "/mcp" {
      // MCP endpoint - handle JSON-RPC
      // For now, return method not found - full implementation in StreamableHttp transport
      let error = Dict.make()
      Dict.set(error, "error", JSON.Encode.string("Use POST for MCP requests"))
      Http.jsonResponse(JSON.Encode.object(error), {"status": 405})
    } else {
      Http.makeResponse(Nullable.make("Not Found"), {"status": 404})
    }
  }

  Http.serve({port, hostname: host}, handler)
}

// ============================================================================
// Entry Point
// ============================================================================

// List of all adapter module paths (relative to compiled output)
let adapterModules = [
  "./adapters/Babashka.res.js",
  "./adapters/Cobalt.res.js",
  "./adapters/Coleslaw.res.js",
  "./adapters/Corral.res.js",
  "./adapters/Cryogen.res.js",
  "./adapters/Documenter.res.js",
  "./adapters/Ema.res.js",
  "./adapters/Fornax.res.js",
  "./adapters/Franklin.res.js",
  "./adapters/Frog.res.js",
  "./adapters/Hakyll.res.js",
  "./adapters/Laika.res.js",
  "./adapters/Marmot.res.js",
  "./adapters/MdBook.res.js",
  "./adapters/NimblePublisher.res.js",
  "./adapters/Nimrod.res.js",
  "./adapters/Orchid.res.js",
  "./adapters/Perun.res.js",
  "./adapters/Pollen.res.js",
  "./adapters/Publish.res.js",
  "./adapters/Reggae.res.js",
  "./adapters/ScalaTex.res.js",
  "./adapters/Serum.res.js",
  "./adapters/StaticWebPages.res.js",
  "./adapters/Tableau.res.js",
  "./adapters/Wub.res.js",
  "./adapters/YOCaml.res.js",
  "./adapters/Zola.res.js",
  "./adapters/Zotonic.res.js",
]

// Dynamically import all adapter modules
let loadAdapters = async () => {
  let adapters: array<adapterModule> = []

  await Array.forEachAsync(adapterModules, async (path) => {
    try {
      let mod = await import_(path)
      let adapter: adapterModule = {
        name: Obj.magic(mod)["name"],
        language: Obj.magic(mod)["language"],
        description: Obj.magic(mod)["description"],
        connect: Obj.magic(mod)["connect"],
        disconnect: Obj.magic(mod)["disconnect"],
        isConnected: Obj.magic(mod)["isConnected"],
        tools: Obj.magic(mod)["tools"],
      }
      Array.push(adapters, adapter)
    } catch {
    | error => {
        Console.error("Failed to load adapter: " ++ path)
        Console.error(error)
      }
    }
  })

  adapters
}

// Detect if running in Deno Deploy (HTTP mode) or local (STDIO mode)
let isDenoDeployEnv = () => {
  switch Deno.Env.get("DENO_DEPLOYMENT_ID") {
  | Some(_) => true
  | None =>
    switch Deno.Env.get("HTTP_MODE") {
    | Some("true") | Some("1") => true
    | _ => false
    }
  }
}

let main = async () => {
  Console.error("polyglot-ssg-mcp starting...")

  // Load all adapters
  let adapters = await loadAdapters()
  Console.error("Loaded " ++ Int.toString(Array.length(adapters)) ++ " SSG adapters")

  if Array.length(adapters) == 0 {
    Console.error("Warning: No adapters loaded. Check adapter module paths.")
  }

  // Create the server
  let server = createServer(adapters)

  // Start in appropriate mode
  if isDenoDeployEnv() {
    await startHttpMode(adapters)
  } else {
    await startStdioMode(server, adapters)
  }
}

let _ = main()
