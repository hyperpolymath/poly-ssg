// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// YOCaml adapter - Static site generator in OCaml
// https://github.com/xhtmlboi/yocaml

open Adapter

let name = "YOCaml"
let language = "OCaml"
let description = "Static site generator in OCaml with composable build rules"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("opam", ["--version"], None)
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
    name: "yocaml_init",
    description: "Initialize a new YOCaml project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Project name"))
      Dict.set(props, "path", makeProp("string", "Path for the project"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "yocaml_build",
    description: "Build the YOCaml site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "yocaml_watch",
    description: "Watch and rebuild on changes",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "yocaml_clean",
    description: "Clean build artifacts",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "yocaml_version",
    description: "Get opam/OCaml version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (name: string, path: option<string>) => {
  await Deno.Command.run("dune", ["init", "project", name], path)
}

let executeBuild = async (path: option<string>) => {
  await Deno.Command.run("dune", ["build"], path)
}

let executeWatch = async (path: option<string>) => {
  await Deno.Command.run("dune", ["build", "--watch"], path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("dune", ["clean"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("opam", ["--version"], None)
}
