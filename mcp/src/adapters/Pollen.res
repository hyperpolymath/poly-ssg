// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Pollen adapter - Programmable publishing system in Racket
// https://docs.racket-lang.org/pollen/

open Adapter

let name = "Pollen"
let language = "Racket"
let description = "Programmable publishing system for making books in Racket"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("raco", ["pollen", "version"], None)
    state.connected = result.success
    result.success
  } catch {
  | _ => {
      state.connected = false
      false
    }
  }
}

let disconnect = async () => {
  state.connected = false
}

let isConnected = () => state.connected

let makeSchema = (props: dict<JSON.t>, required: array<string>) => {
  let schema = Dict.make()
  Dict.set(schema, "type", JSON.Encode.string("object"))
  Dict.set(schema, "properties", JSON.Encode.object(props))
  if Array.length(required) > 0 {
    Dict.set(schema, "required", JSON.Encode.array(Array.map(required, JSON.Encode.string)))
  }
  JSON.Encode.object(schema)
}

let makeProp = (typeName: string, desc: string) =>
  JSON.Encode.object(
    Dict.fromArray([("type", JSON.Encode.string(typeName)), ("description", JSON.Encode.string(desc))]),
  )

let tools: array<tool> = [
  {
    name: "pollen_start",
    description: "Start Pollen project server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 8080)"))
      makeSchema(props, [])
    },
  },
  {
    name: "pollen_render",
    description: "Render Pollen source files",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "parallel", makeProp("boolean", "Render in parallel"))
      makeSchema(props, [])
    },
  },
  {
    name: "pollen_publish",
    description: "Publish rendered files to output directory",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "output", makeProp("string", "Output directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "pollen_reset",
    description: "Reset Pollen cache",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "pollen_version",
    description: "Get Pollen version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeStart = async (path: option<string>, port: option<int>) => {
  let args = ["pollen", "start"]
  let args = switch port {
  | Some(p) => Array.concat(args, [Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("raco", args, path)
}

let executeRender = async (path: option<string>, parallel: option<bool>) => {
  let args = ["pollen", "render"]
  let args = switch parallel {
  | Some(true) => Array.concat(args, ["-p"])
  | _ => args
  }
  await Deno.Command.run("raco", args, path)
}

let executePublish = async (path: option<string>, output: option<string>) => {
  let args = ["pollen", "publish"]
  let args = switch output {
  | Some(o) => Array.concat(args, [o])
  | None => args
  }
  await Deno.Command.run("raco", args, path)
}

let executeReset = async (path: option<string>) => {
  await Deno.Command.run("raco", ["pollen", "reset"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("raco", ["pollen", "version"], None)
}
