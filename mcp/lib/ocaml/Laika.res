// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Laika adapter - Text markup transformer in Scala
// https://planet42.github.io/Laika/

open Adapter

let name = "Laika"
let language = "Scala"
let description = "Customizable text markup transformer and site generator in Scala"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("laika", ["--version"], None)
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
    name: "laika_transform",
    description: "Transform markup files",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "input", makeProp("string", "Input directory or file"))
      Dict.set(props, "output", makeProp("string", "Output directory"))
      Dict.set(props, "format", makeProp("string", "Output format (html, epub, pdf, ast)"))
      makeSchema(props, ["input", "output"])
    },
  },
  {
    name: "laika_generate",
    description: "Generate a site from markup",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "output", makeProp("string", "Output directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "laika_preview",
    description: "Start preview server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      makeSchema(props, [])
    },
  },
  {
    name: "laika_version",
    description: "Get Laika version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeTransform = async (input: string, output: string, format: option<string>) => {
  let args = ["transform", input, output]
  let args = switch format {
  | Some(f) => Array.concat(args, ["--format", f])
  | None => args
  }
  await Deno.Command.run("laika", args, None)
}

let executeGenerate = async (path: option<string>, output: option<string>) => {
  let args = ["generate"]
  let args = switch output {
  | Some(o) => Array.concat(args, ["--output", o])
  | None => args
  }
  await Deno.Command.run("laika", args, path)
}

let executePreview = async (path: option<string>, port: option<int>) => {
  let args = ["preview"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("laika", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("laika", ["--version"], None)
}
