// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Marmot adapter - Static site generator in Crystal
// https://github.com/MakeNowJust/marmot

open Adapter

let name = "Marmot"
let language = "Crystal"
let description = "Fast static site generator written in Crystal"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("marmot", ["--version"], None)
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
    name: "marmot_init",
    description: "Initialize a new Marmot site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new site"))
      makeSchema(props, [])
    },
  },
  {
    name: "marmot_build",
    description: "Build the Marmot site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "output", makeProp("string", "Output directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "marmot_serve",
    description: "Start Marmot development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      makeSchema(props, [])
    },
  },
  {
    name: "marmot_watch",
    description: "Watch for changes and rebuild",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "marmot_version",
    description: "Get Marmot version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: option<string>) => {
  let args = ["init"]
  let args = switch path {
  | Some(p) => Array.concat(args, [p])
  | None => args
  }
  await Deno.Command.run("marmot", args, None)
}

let executeBuild = async (path: option<string>, output: option<string>) => {
  let args = ["build"]
  let args = switch output {
  | Some(o) => Array.concat(args, ["--output", o])
  | None => args
  }
  await Deno.Command.run("marmot", args, path)
}

let executeServe = async (path: option<string>, port: option<int>) => {
  let args = ["serve"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("marmot", args, path)
}

let executeWatch = async (path: option<string>) => {
  await Deno.Command.run("marmot", ["watch"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("marmot", ["--version"], None)
}
