// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// HTTP/SSE bindings for Deno

type headers

type request = {
  method: string,
  url: string,
  headers: headers,
}

@send external get: (headers, string) => Nullable.t<string> = "get"

type response

@new external makeResponse: (Nullable.t<string>, {..}) => response = "Response"

@scope("Response") @val
external jsonResponse: ('a, {..}) => response = "json"

type serveOptions = {
  port: int,
  hostname: string,
}

type serveHandler = request => promise<response>

@scope("Deno") @val
external serve: (serveOptions, serveHandler) => unit = "serve"

// URL parsing
type url = {pathname: string}

@new external makeUrl: string => url = "URL"

// TextEncoder for SSE
type textEncoder

@new external makeTextEncoder: unit => textEncoder = "TextEncoder"

@send external encode: (textEncoder, string) => Js.TypedArray2.Uint8Array.t = "encode"

// ReadableStream for SSE
type readableStreamController<'a>

@send external enqueue: (readableStreamController<'a>, 'a) => unit = "enqueue"
@send external close: readableStreamController<'a> => unit = "close"

type readableStreamInit<'a> = {start: readableStreamController<'a> => unit}

type readableStream<'a>

@new external makeReadableStream: readableStreamInit<'a> => readableStream<'a> = "ReadableStream"

// Crypto for session IDs
@scope(("crypto")) @val
external getRandomValues: Js.TypedArray2.Uint8Array.t => Js.TypedArray2.Uint8Array.t = "getRandomValues"

// TypedArray bindings
@new external makeUint8Array: int => Js.TypedArray2.Uint8Array.t = "Uint8Array"

@send
external uint8ArrayReduce: (
  Js.TypedArray2.Uint8Array.t,
  (string, int) => string,
  string,
) => string = "reduce"

// Helper to convert byte to hex string
let byteToHex = (byte: int) => {
  let hex = "0123456789abcdef"
  let high = String.charAt(hex, byte / 16)
  let low = String.charAt(hex, mod(byte, 16))
  high ++ low
}

let generateSessionId = () => {
  let array = makeUint8Array(32)
  let _ = getRandomValues(array)
  uint8ArrayReduce(array, (acc, byte) => {
    acc ++ byteToHex(byte)
  }, "")
}
