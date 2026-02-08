// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Fornax adapter - Static site generator in F#
// https://ionide.io/Tools/fornax.html

open Adapter

let name = "Fornax"
let language = "F#"
let description = "Static site generator using type-safe F# DSL"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("fornax", ["version"], None)
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
    name: "fornax_new",
    description: "Create a new Fornax project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new project"))
      makeSchema(props, [])
    },
  },
  {
    name: "fornax_build",
    description: "Build the Fornax site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "fornax_watch",
    description: "Start Fornax watch server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 8080)"))
      makeSchema(props, [])
    },
  },
  {
    name: "fornax_clean",
    description: "Clean build output",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "fornax_version",
    description: "Get Fornax version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeNew = async (path: option<string>) => {
  let args = ["new"]
  let args = switch path {
  | Some(p) => Array.concat(args, [p])
  | None => args
  }
  await Deno.Command.run("fornax", args, None)
}

let executeBuild = async (path: option<string>) => {
  await Deno.Command.run("fornax", ["build"], path)
}

let executeWatch = async (path: option<string>, port: option<int>) => {
  let args = ["watch"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("fornax", args, path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("fornax", ["clean"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("fornax", ["version"], None)
}
