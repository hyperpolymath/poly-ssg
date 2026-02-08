// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Cobalt adapter - Static site generator in Rust
// https://cobalt-org.github.io/

open Adapter

let name = "Cobalt"
let language = "Rust"
let description = "Straightforward static site generator written in Rust"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("cobalt", ["--version"], None)
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

// Helper to create JSON schema
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
    name: "cobalt_init",
    description: "Initialize a new Cobalt site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new site"))
      makeSchema(props, [])
    },
  },
  {
    name: "cobalt_build",
    description: "Build the Cobalt site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "destination", makeProp("string", "Output directory"))
      Dict.set(props, "drafts", makeProp("boolean", "Include drafts"))
      makeSchema(props, [])
    },
  },
  {
    name: "cobalt_serve",
    description: "Start Cobalt development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      Dict.set(props, "host", makeProp("string", "Host to bind to"))
      Dict.set(props, "drafts", makeProp("boolean", "Include drafts"))
      makeSchema(props, [])
    },
  },
  {
    name: "cobalt_watch",
    description: "Watch for changes and rebuild",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "cobalt_clean",
    description: "Clean the build directory",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "cobalt_new",
    description: "Create a new post",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "title", makeProp("string", "Post title"))
      makeSchema(props, ["title"])
    },
  },
  {
    name: "cobalt_version",
    description: "Get Cobalt version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

// Tool execution handlers
let executeInit = async (path: option<string>) => {
  let args = ["init"]
  let args = switch path {
  | Some(p) => Array.concat(args, [p])
  | None => args
  }
  await Deno.Command.run("cobalt", args, None)
}

let executeBuild = async (path: option<string>, destination: option<string>, drafts: option<bool>) => {
  let args = ["build"]
  let args = switch destination {
  | Some(d) => Array.concat(args, ["--destination", d])
  | None => args
  }
  let args = switch drafts {
  | Some(true) => Array.concat(args, ["--drafts"])
  | _ => args
  }
  await Deno.Command.run("cobalt", args, path)
}

let executeServe = async (path: option<string>, port: option<int>, host: option<string>, drafts: option<bool>) => {
  let args = ["serve"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  let args = switch host {
  | Some(h) => Array.concat(args, ["--host", h])
  | None => args
  }
  let args = switch drafts {
  | Some(true) => Array.concat(args, ["--drafts"])
  | _ => args
  }
  await Deno.Command.run("cobalt", args, path)
}

let executeWatch = async (path: option<string>) => {
  await Deno.Command.run("cobalt", ["watch"], path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("cobalt", ["clean"], path)
}

let executeNew = async (path: option<string>, title: string) => {
  await Deno.Command.run("cobalt", ["new", title], path)
}

let executeVersion = async () => {
  await Deno.Command.run("cobalt", ["--version"], None)
}
