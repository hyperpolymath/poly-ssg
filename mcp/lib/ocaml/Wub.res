// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Wub adapter - Web application framework in Tcl
// https://wiki.tcl-lang.org/page/Wub

open Adapter

let name = "Wub"
let language = "Tcl"
let description = "Web application framework and static site generator in Tcl"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let _ = await Deno.Command.run("tclsh", ["--version"], None)
    // Tcl returns version info differently, check if tclsh exists
    state.connected = true
    true
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
    name: "wub_init",
    description: "Initialize a new Wub project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new project"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "wub_serve",
    description: "Start Wub server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 8080)"))
      makeSchema(props, [])
    },
  },
  {
    name: "wub_generate",
    description: "Generate static files",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "output", makeProp("string", "Output directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "wub_version",
    description: "Get Tcl version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: string) => {
  await Deno.Command.run("tclsh", ["wub.tcl", "init", path], None)
}

let executeServe = async (path: option<string>, port: option<int>) => {
  let args = ["wub.tcl", "serve"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["-port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("tclsh", args, path)
}

let executeGenerate = async (path: option<string>, output: option<string>) => {
  let args = ["wub.tcl", "generate"]
  let args = switch output {
  | Some(o) => Array.concat(args, ["-output", o])
  | None => args
  }
  await Deno.Command.run("tclsh", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("tclsh", ["-c", "puts [info patchlevel]"], None)
}
