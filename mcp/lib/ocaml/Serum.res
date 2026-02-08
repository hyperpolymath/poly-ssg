// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Serum adapter - Static site generator in Elixir
// https://dalgona.github.io/Serum/

open Adapter

let name = "Serum"
let language = "Elixir"
let description = "Simple static website generator written in Elixir"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("mix", ["--version"], None)
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
    name: "serum_init",
    description: "Initialize a new Serum project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new project"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "serum_build",
    description: "Build the Serum site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "output", makeProp("string", "Output directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "serum_server",
    description: "Start Serum development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 8080)"))
      makeSchema(props, [])
    },
  },
  {
    name: "serum_version",
    description: "Get Serum version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: string) => {
  await Deno.Command.run("mix", ["serum.new", path], None)
}

let executeBuild = async (path: option<string>, output: option<string>) => {
  let args = ["serum.build"]
  let args = switch output {
  | Some(o) => Array.concat(args, ["--output", o])
  | None => args
  }
  await Deno.Command.run("mix", args, path)
}

let executeServer = async (path: option<string>, port: option<int>) => {
  let args = ["serum.server"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("mix", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("mix", ["serum", "--version"], None)
}
