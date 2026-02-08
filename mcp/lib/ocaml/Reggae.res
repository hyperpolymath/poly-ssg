// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Reggae adapter - Build system in D language
// https://github.com/atilaneves/reggae

open Adapter

let name = "Reggae"
let language = "D"
let description = "Build system generator written in D for static sites"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("reggae", ["--version"], None)
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
    name: "reggae_init",
    description: "Initialize a Reggae build",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "backend", makeProp("string", "Build backend (make, ninja, tup)"))
      makeSchema(props, [])
    },
  },
  {
    name: "reggae_build",
    description: "Build the project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "jobs", makeProp("number", "Number of parallel jobs"))
      makeSchema(props, [])
    },
  },
  {
    name: "reggae_clean",
    description: "Clean build artifacts",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "reggae_version",
    description: "Get Reggae version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: option<string>, backend: option<string>) => {
  let args = switch backend {
  | Some(b) => ["--backend=" ++ b]
  | None => []
  }
  await Deno.Command.run("reggae", args, path)
}

let executeBuild = async (path: option<string>, jobs: option<int>) => {
  let args = ["build"]
  let args = switch jobs {
  | Some(j) => Array.concat(args, ["-j", Int.toString(j)])
  | None => args
  }
  await Deno.Command.run("reggae", args, path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("reggae", ["clean"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("reggae", ["--version"], None)
}
