// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Corral adapter - Static site generator in Pony
// Pony is a capability-secure, actor-model language

open Adapter

let name = "Corral"
let language = "Pony"
let description = "Static site generator written in Pony with capability-based security and actor-model concurrency"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("corral", ["version"], None)
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
    name: "corral_init",
    description: "Initialize a new Pony site project with Corral package manager",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new site"))
      Dict.set(props, "template", makeProp("string", "Template to use (blog, docs, portfolio)"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "corral_build",
    description: "Build the Pony static site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "outputDir", makeProp("string", "Output directory for built site"))
      Dict.set(props, "release", makeProp("boolean", "Build in release mode with optimizations"))
      makeSchema(props, [])
    },
  },
  {
    name: "corral_serve",
    description: "Start Pony development server with live reload",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 8080)"))
      Dict.set(props, "host", makeProp("string", "Host to bind to (default: 127.0.0.1)"))
      makeSchema(props, [])
    },
  },
  {
    name: "corral_clean",
    description: "Clean build artifacts from the Pony site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "corral_version",
    description: "Get Corral and Pony version information",
    inputSchema: makeSchema(Dict.make(), []),
  },
  {
    name: "corral_new_post",
    description: "Create a new blog post or content page",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "title", makeProp("string", "Title of the new post"))
      Dict.set(props, "draft", makeProp("boolean", "Mark as draft"))
      makeSchema(props, ["title"])
    },
  },
  {
    name: "corral_check",
    description: "Check and validate the site configuration and content",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
]

// Tool execution handlers
let executeInit = async (path: string, template: option<string>) => {
  let args = ["init", path]
  let args = switch template {
  | Some(t) => Array.concat(args, ["--template", t])
  | None => args
  }
  await Deno.Command.run("corral", args, None)
}

let executeBuild = async (path: option<string>, outputDir: option<string>, release: option<bool>) => {
  let args = ["build"]
  let args = switch outputDir {
  | Some(dir) => Array.concat(args, ["--output", dir])
  | None => args
  }
  let args = switch release {
  | Some(true) => Array.concat(args, ["--release"])
  | _ => args
  }
  await Deno.Command.run("corral", args, path)
}

let executeServe = async (path: option<string>, port: option<int>, host: option<string>) => {
  let args = ["serve"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  let args = switch host {
  | Some(h) => Array.concat(args, ["--host", h])
  | None => args
  }
  await Deno.Command.run("corral", args, path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("corral", ["clean"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("corral", ["version"], None)
}

let executeNewPost = async (path: option<string>, title: string, draft: option<bool>) => {
  let args = ["new", "post", title]
  let args = switch draft {
  | Some(true) => Array.concat(args, ["--draft"])
  | _ => args
  }
  await Deno.Command.run("corral", args, path)
}

let executeCheck = async (path: option<string>) => {
  await Deno.Command.run("corral", ["check"], path)
}
