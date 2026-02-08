// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Frog adapter - Static blog generator in Racket
// https://github.com/greghendershott/frog

open Adapter

let name = "Frog"
let language = "Racket"
let description = "Static blog generator using Racket with Markdown and Pygments"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("raco", ["frog", "--help"], None)
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
    name: "frog_init",
    description: "Initialize a new Frog blog",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new blog"))
      makeSchema(props, [])
    },
  },
  {
    name: "frog_build",
    description: "Build the Frog blog",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to blog root"))
      makeSchema(props, [])
    },
  },
  {
    name: "frog_preview",
    description: "Start Frog preview server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to blog root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 3000)"))
      makeSchema(props, [])
    },
  },
  {
    name: "frog_new",
    description: "Create a new blog post",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to blog root"))
      Dict.set(props, "title", makeProp("string", "Post title"))
      makeSchema(props, ["title"])
    },
  },
  {
    name: "frog_clean",
    description: "Clean generated files",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to blog root"))
      makeSchema(props, [])
    },
  },
  {
    name: "frog_version",
    description: "Get Frog version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: option<string>) => {
  await Deno.Command.run("raco", ["frog", "--init"], path)
}

let executeBuild = async (path: option<string>) => {
  await Deno.Command.run("raco", ["frog", "-b"], path)
}

let executePreview = async (path: option<string>, port: option<int>) => {
  let args = ["frog", "-p"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("raco", args, path)
}

let executeNew = async (path: option<string>, title: string) => {
  await Deno.Command.run("raco", ["frog", "-n", title], path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("raco", ["frog", "--clean"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("raco", ["frog", "--version"], None)
}
