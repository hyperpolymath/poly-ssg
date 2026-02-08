// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Nimrod adapter - Static site generator in Nim
// Nim-based static site generation

open Adapter

let name = "Nimrod"
let language = "Nim"
let description = "Static site generator written in Nim"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("nim", ["--version"], None)
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
    name: "nimrod_init",
    description: "Initialize a new Nimrod site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new site"))
      Dict.set(props, "template", makeProp("string", "Template to use"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "nimrod_build",
    description: "Build the Nimrod site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "release", makeProp("boolean", "Build in release mode"))
      makeSchema(props, [])
    },
  },
  {
    name: "nimrod_serve",
    description: "Start Nimrod development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      makeSchema(props, [])
    },
  },
  {
    name: "nimrod_clean",
    description: "Clean build artifacts",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "nimrod_version",
    description: "Get Nim version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: string, template: option<string>) => {
  let args = ["init", path]
  let args = switch template {
  | Some(t) => Array.concat(args, ["--template", t])
  | None => args
  }
  await Deno.Command.run("nimrod", args, None)
}

let executeBuild = async (path: option<string>, release: option<bool>) => {
  let args = ["build"]
  let args = switch release {
  | Some(true) => Array.concat(args, ["--release"])
  | _ => args
  }
  await Deno.Command.run("nimrod", args, path)
}

let executeServe = async (path: option<string>, port: option<int>) => {
  let args = ["serve"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("nimrod", args, path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("nimrod", ["clean"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("nim", ["--version"], None)
}
