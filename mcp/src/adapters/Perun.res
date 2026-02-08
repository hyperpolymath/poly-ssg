// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Perun adapter - Composable static site generator in Clojure
// https://perun.io/

open Adapter

let name = "Perun"
let language = "Clojure"
let description = "Composable static site generator using Boot build tool"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("boot", ["--version"], None)
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
    name: "perun_init",
    description: "Initialize a new Perun project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new project"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "perun_build",
    description: "Build the Perun site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "target", makeProp("string", "Build target"))
      makeSchema(props, [])
    },
  },
  {
    name: "perun_dev",
    description: "Start development mode with watch",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      makeSchema(props, [])
    },
  },
  {
    name: "perun_version",
    description: "Get Boot version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: string) => {
  await Deno.Command.run("boot", ["new", "perun", path], None)
}

let executeBuild = async (path: option<string>, target: option<string>) => {
  let args = switch target {
  | Some(t) => [t]
  | None => ["build"]
  }
  await Deno.Command.run("boot", args, path)
}

let executeDev = async (path: option<string>, port: option<int>) => {
  let args = ["dev"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["-p", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("boot", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("boot", ["--version"], None)
}
