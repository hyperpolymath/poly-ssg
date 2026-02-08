// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Publish adapter - Static site generator in Swift
// https://github.com/JohnSundell/Publish

open Adapter

let name = "Publish"
let language = "Swift"
let description = "Static site generator for Swift developers"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("publish", ["--version"], None)
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
    name: "publish_new",
    description: "Create a new Publish site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new site"))
      makeSchema(props, [])
    },
  },
  {
    name: "publish_generate",
    description: "Generate the Publish site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "publish_run",
    description: "Run the Publish development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 8000)"))
      makeSchema(props, [])
    },
  },
  {
    name: "publish_deploy",
    description: "Deploy the site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "method", makeProp("string", "Deploy method (git, github)"))
      makeSchema(props, [])
    },
  },
  {
    name: "publish_version",
    description: "Get Publish version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeNew = async (path: option<string>) => {
  let args = ["new"]
  let args = switch path {
  | Some(p) => Array.concat(args, [p])
  | None => args
  }
  await Deno.Command.run("publish", args, None)
}

let executeGenerate = async (path: option<string>) => {
  await Deno.Command.run("publish", ["generate"], path)
}

let executeRun = async (path: option<string>, port: option<int>) => {
  let args = ["run"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("publish", args, path)
}

let executeDeploy = async (path: option<string>, method: option<string>) => {
  let args = ["deploy"]
  let args = switch method {
  | Some(m) => Array.concat(args, ["--" ++ m])
  | None => args
  }
  await Deno.Command.run("publish", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("publish", ["--version"], None)
}
