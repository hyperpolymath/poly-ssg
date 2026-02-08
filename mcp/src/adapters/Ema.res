// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Ema adapter - Static site generator in Haskell with hot reload
// https://ema.srid.ca/

open Adapter

let name = "Ema"
let language = "Haskell"
let description = "Static site generator in Haskell with hot reload and Nix support"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("ema", ["--version"], None)
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
    name: "ema_init",
    description: "Initialize a new Ema project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Project name"))
      Dict.set(props, "path", makeProp("string", "Path for the project"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "ema_build",
    description: "Build the Ema site (generate static files)",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "output", makeProp("string", "Output directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "ema_run",
    description: "Start Ema development server with hot reload",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      Dict.set(props, "host", makeProp("string", "Host to bind to"))
      makeSchema(props, [])
    },
  },
  {
    name: "ema_version",
    description: "Get Ema version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (name: string, path: option<string>) => {
  // Ema projects are typically created via nix flake
  await Deno.Command.run("nix", ["flake", "init", "-t", "github:srid/ema#template", name], path)
}

let executeBuild = async (path: option<string>, output: option<string>) => {
  let args = ["gen"]
  let args = switch output {
  | Some(o) => Array.concat(args, ["--dest", o])
  | None => args
  }
  await Deno.Command.run("ema", args, path)
}

let executeRun = async (path: option<string>, port: option<int>, host: option<string>) => {
  let args = ["run"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  let args = switch host {
  | Some(h) => Array.concat(args, ["--host", h])
  | None => args
  }
  await Deno.Command.run("ema", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("ema", ["--version"], None)
}
