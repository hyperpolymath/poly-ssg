// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// StaticWebPages adapter - Academic pages generator in Julia
// https://github.com/Humans-of-Julia/StaticWebPages.jl

open Adapter

let name = "StaticWebPages"
let language = "Julia"
let description = "Static website generator for academics in Julia"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("julia", ["--version"], None)
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
    name: "staticwebpages_init",
    description: "Initialize a new StaticWebPages project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new project"))
      Dict.set(props, "template", makeProp("string", "Template (academic, portfolio)"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "staticwebpages_build",
    description: "Build the static website",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "output", makeProp("string", "Output directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "staticwebpages_serve",
    description: "Start local development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      makeSchema(props, [])
    },
  },
  {
    name: "staticwebpages_version",
    description: "Get Julia version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: string, template: option<string>) => {
  let templateArg = switch template {
  | Some(t) => `, template=:${t}`
  | None => ""
  }
  await Deno.Command.run("julia", ["-e", `using StaticWebPages; init("${path}"${templateArg})`], None)
}

let executeBuild = async (path: option<string>, output: option<string>) => {
  let outputArg = switch output {
  | Some(o) => `, output="${o}"`
  | None => ""
  }
  let dir = switch path {
  | Some(p) => `cd("${p}"); `
  | None => ""
  }
  await Deno.Command.run("julia", ["-e", `using StaticWebPages; ${dir}build(${outputArg})`], None)
}

let executeServe = async (path: option<string>, port: option<int>) => {
  let portArg = switch port {
  | Some(p) => `, port=${Int.toString(p)}`
  | None => ""
  }
  let dir = switch path {
  | Some(p) => `cd("${p}"); `
  | None => ""
  }
  await Deno.Command.run("julia", ["-e", `using StaticWebPages; ${dir}serve(${portArg})`], None)
}

let executeVersion = async () => {
  await Deno.Command.run("julia", ["--version"], None)
}
