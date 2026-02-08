// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Coleslaw adapter - Static blog generator in Common Lisp
// https://github.com/kingcons/coleslaw

open Adapter

let name = "Coleslaw"
let language = "Common Lisp"
let description = "Flexible static blog generator written in Common Lisp"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("sbcl", ["--version"], None)
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
    name: "coleslaw_init",
    description: "Initialize a new Coleslaw blog",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new blog"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "coleslaw_build",
    description: "Build the Coleslaw blog",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to blog root"))
      makeSchema(props, [])
    },
  },
  {
    name: "coleslaw_preview",
    description: "Preview the blog locally",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to blog root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      makeSchema(props, [])
    },
  },
  {
    name: "coleslaw_new_post",
    description: "Create a new blog post",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to blog root"))
      Dict.set(props, "title", makeProp("string", "Post title"))
      makeSchema(props, ["title"])
    },
  },
  {
    name: "coleslaw_version",
    description: "Get SBCL version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: string) => {
  // Coleslaw is typically run via quicklisp
  await Deno.Command.run("sbcl", ["--eval", "(ql:quickload :coleslaw)", "--eval", `(coleslaw:setup "${path}")`, "--quit"], None)
}

let executeBuild = async (path: option<string>) => {
  let evalArg = switch path {
  | Some(p) => `(coleslaw:main "${p}")`
  | None => "(coleslaw:main)"
  }
  await Deno.Command.run("sbcl", ["--eval", "(ql:quickload :coleslaw)", "--eval", evalArg, "--quit"], None)
}

let executePreview = async (path: option<string>, port: option<int>) => {
  let portStr = switch port {
  | Some(p) => Int.toString(p)
  | None => "8000"
  }
  let evalArg = switch path {
  | Some(p) => `(coleslaw:preview "${p}" :port ${portStr})`
  | None => `(coleslaw:preview :port ${portStr})`
  }
  await Deno.Command.run("sbcl", ["--eval", "(ql:quickload :coleslaw)", "--eval", evalArg], None)
}

let executeNewPost = async (path: option<string>, title: string) => {
  let evalArg = switch path {
  | Some(p) => `(coleslaw:new-post "${p}" :title "${title}")`
  | None => `(coleslaw:new-post :title "${title}")`
  }
  await Deno.Command.run("sbcl", ["--eval", "(ql:quickload :coleslaw)", "--eval", evalArg, "--quit"], None)
}

let executeVersion = async () => {
  await Deno.Command.run("sbcl", ["--version"], None)
}
