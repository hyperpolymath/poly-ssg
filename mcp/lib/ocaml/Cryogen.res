// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Cryogen adapter - Static site generator in Clojure
// https://cryogenweb.org/

open Adapter

let name = "Cryogen"
let language = "Clojure"
let description = "Simple static site generator using Clojure and Leiningen"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("lein", ["version"], None)
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
    name: "cryogen_new",
    description: "Create a new Cryogen site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Project name"))
      Dict.set(props, "path", makeProp("string", "Path for the project"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "cryogen_build",
    description: "Build the Cryogen site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "cryogen_serve",
    description: "Start Cryogen development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 3000)"))
      makeSchema(props, [])
    },
  },
  {
    name: "cryogen_new_post",
    description: "Create a new blog post",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "title", makeProp("string", "Post title"))
      makeSchema(props, ["title"])
    },
  },
  {
    name: "cryogen_version",
    description: "Get Leiningen version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeNew = async (name: string, path: option<string>) => {
  await Deno.Command.run("lein", ["new", "cryogen", name], path)
}

let executeBuild = async (path: option<string>) => {
  await Deno.Command.run("lein", ["run"], path)
}

let executeServe = async (path: option<string>, port: option<int>) => {
  let args = ["ring", "server"]
  let args = switch port {
  | Some(p) => Array.concat(args, [Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("lein", args, path)
}

let executeNewPost = async (path: option<string>, title: string) => {
  await Deno.Command.run("lein", ["run", "-m", "cryogen.core/new-post!", title], path)
}

let executeVersion = async () => {
  await Deno.Command.run("lein", ["version"], None)
}
