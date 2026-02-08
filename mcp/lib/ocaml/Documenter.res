// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Documenter adapter - Documentation generator in Julia
// https://documenter.juliadocs.org/

open Adapter

let name = "Documenter"
let language = "Julia"
let description = "Documentation generator for Julia packages"

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
    name: "documenter_init",
    description: "Initialize Documenter for a Julia package",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to Julia package"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "documenter_build",
    description: "Build documentation",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to docs/ directory"))
      Dict.set(props, "strict", makeProp("boolean", "Strict mode (fail on warnings)"))
      makeSchema(props, [])
    },
  },
  {
    name: "documenter_serve",
    description: "Serve documentation locally",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to docs/build/ directory"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      makeSchema(props, [])
    },
  },
  {
    name: "documenter_deploy",
    description: "Deploy documentation to GitHub Pages",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to docs/ directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "documenter_version",
    description: "Get Documenter version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: string) => {
  await Deno.Command.run("julia", ["-e", `using DocumenterTools; DocumenterTools.generate("${path}")`], None)
}

let executeBuild = async (path: option<string>, _strict: option<bool>) => {
  // Note: strict mode would be passed via make.jl configuration
  let docsPath = switch path {
  | Some(p) => p
  | None => "docs"
  }
  await Deno.Command.run("julia", ["--project=" ++ docsPath, docsPath ++ "/make.jl"], None)
}

let executeServe = async (path: option<string>, port: option<int>) => {
  let portArg = switch port {
  | Some(p) => Int.toString(p)
  | None => "8000"
  }
  let buildPath = switch path {
  | Some(p) => p
  | None => "docs/build"
  }
  await Deno.Command.run("julia", ["-e", `using LiveServer; serve(dir="${buildPath}", port=${portArg})`], None)
}

let executeDeploy = async (path: option<string>) => {
  let docsPath = switch path {
  | Some(p) => p
  | None => "docs"
  }
  await Deno.Command.run("julia", ["--project=" ++ docsPath, docsPath ++ "/make.jl", "--deploy"], None)
}

let executeVersion = async () => {
  await Deno.Command.run("julia", ["-e", "using Documenter; println(Documenter.DOCUMENTER_VERSION)"], None)
}
