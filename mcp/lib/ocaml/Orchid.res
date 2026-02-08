// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Orchid adapter - Static site generator in Kotlin
// https://orchid.run/

open Adapter

let name = "Orchid"
let language = "Kotlin"
let description = "Powerful static site generator in Kotlin with plugin system"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("orchid", ["--version"], None)
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
    name: "orchid_init",
    description: "Initialize a new Orchid project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new project"))
      Dict.set(props, "theme", makeProp("string", "Theme to use (Editorial, Copper, etc.)"))
      makeSchema(props, [])
    },
  },
  {
    name: "orchid_build",
    description: "Build the Orchid site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "environment", makeProp("string", "Build environment (debug, production)"))
      makeSchema(props, [])
    },
  },
  {
    name: "orchid_serve",
    description: "Start Orchid development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 8080)"))
      makeSchema(props, [])
    },
  },
  {
    name: "orchid_deploy",
    description: "Deploy the Orchid site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "destination", makeProp("string", "Deploy destination"))
      makeSchema(props, [])
    },
  },
  {
    name: "orchid_version",
    description: "Get Orchid version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: option<string>, theme: option<string>) => {
  let args = ["init"]
  let args = switch path {
  | Some(p) => Array.concat(args, [p])
  | None => args
  }
  let args = switch theme {
  | Some(t) => Array.concat(args, ["--theme", t])
  | None => args
  }
  await Deno.Command.run("orchid", args, None)
}

let executeBuild = async (path: option<string>, environment: option<string>) => {
  let args = ["build"]
  let args = switch environment {
  | Some(e) => Array.concat(args, ["--environment", e])
  | None => args
  }
  await Deno.Command.run("orchid", args, path)
}

let executeServe = async (path: option<string>, port: option<int>) => {
  let args = ["serve"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("orchid", args, path)
}

let executeDeploy = async (path: option<string>, destination: option<string>) => {
  let args = ["deploy"]
  let args = switch destination {
  | Some(d) => Array.concat(args, ["--destination", d])
  | None => args
  }
  await Deno.Command.run("orchid", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("orchid", ["--version"], None)
}
