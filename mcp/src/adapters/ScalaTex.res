// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// ScalaTex adapter - LaTeX/PDF generation in Scala
// Document generation using Scala and LaTeX

open Adapter

let name = "ScalaTex"
let language = "Scala"
let description = "Document and site generation using Scala with LaTeX support"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("mill", ["--version"], None)
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
    name: "scalatex_init",
    description: "Initialize a new ScalaTex project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Project name"))
      Dict.set(props, "path", makeProp("string", "Path for the project"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "scalatex_build",
    description: "Build the ScalaTex document/site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "target", makeProp("string", "Build target (html, pdf)"))
      makeSchema(props, [])
    },
  },
  {
    name: "scalatex_watch",
    description: "Watch and rebuild on changes",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "scalatex_clean",
    description: "Clean build artifacts",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "scalatex_version",
    description: "Get Mill/Scala version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (name: string, path: option<string>) => {
  await Deno.Command.run("mill", ["init", name], path)
}

let executeBuild = async (path: option<string>, target: option<string>) => {
  let targetName = switch target {
  | Some(t) => t
  | None => "compile"
  }
  await Deno.Command.run("mill", [targetName], path)
}

let executeWatch = async (path: option<string>) => {
  await Deno.Command.run("mill", ["-w", "compile"], path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("mill", ["clean"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("mill", ["--version"], None)
}
