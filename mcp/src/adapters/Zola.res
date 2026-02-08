// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Zola adapter - Fast static site generator in Rust
// https://www.getzola.org/

open Adapter

let name = "Zola"
let language = "Rust"
let description = "Fast static site generator written in Rust with built-in Sass compilation and syntax highlighting"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("zola", ["--version"], None)
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
    name: "zola_init",
    description: "Initialize a new Zola site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new site"))
      Dict.set(props, "force", makeProp("boolean", "Overwrite existing directory"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "zola_build",
    description: "Build the Zola site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "baseUrl", makeProp("string", "Base URL for the site"))
      Dict.set(props, "outputDir", makeProp("string", "Output directory"))
      Dict.set(props, "drafts", makeProp("boolean", "Include drafts"))
      makeSchema(props, [])
    },
  },
  {
    name: "zola_serve",
    description: "Start Zola development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 1111)"))
      Dict.set(props, "interface", makeProp("string", "Interface to bind to"))
      Dict.set(props, "drafts", makeProp("boolean", "Include drafts"))
      Dict.set(props, "openBrowser", makeProp("boolean", "Open browser automatically"))
      makeSchema(props, [])
    },
  },
  {
    name: "zola_check",
    description: "Check the site for errors",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "drafts", makeProp("boolean", "Include drafts"))
      makeSchema(props, [])
    },
  },
  {
    name: "zola_version",
    description: "Get Zola version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

// Tool execution handlers
let executeInit = async (path: string, force: option<bool>) => {
  let args = ["init", path]
  let args = switch force {
  | Some(true) => Array.concat(args, ["--force"])
  | _ => args
  }
  await Deno.Command.run("zola", args, None)
}

let executeBuild = async (
  path: option<string>,
  baseUrl: option<string>,
  outputDir: option<string>,
  drafts: option<bool>,
) => {
  let args = ["build"]
  let args = switch baseUrl {
  | Some(url) => Array.concat(args, ["--base-url", url])
  | None => args
  }
  let args = switch outputDir {
  | Some(dir) => Array.concat(args, ["--output-dir", dir])
  | None => args
  }
  let args = switch drafts {
  | Some(true) => Array.concat(args, ["--drafts"])
  | _ => args
  }
  await Deno.Command.run("zola", args, path)
}

let executeServe = async (
  path: option<string>,
  port: option<int>,
  iface: option<string>,
  drafts: option<bool>,
  openBrowser: option<bool>,
) => {
  let args = ["serve"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  let args = switch iface {
  | Some(i) => Array.concat(args, ["--interface", i])
  | None => args
  }
  let args = switch drafts {
  | Some(true) => Array.concat(args, ["--drafts"])
  | _ => args
  }
  let args = switch openBrowser {
  | Some(true) => Array.concat(args, ["--open"])
  | _ => args
  }
  await Deno.Command.run("zola", args, path)
}

let executeCheck = async (path: option<string>, drafts: option<bool>) => {
  let args = ["check"]
  let args = switch drafts {
  | Some(true) => Array.concat(args, ["--drafts"])
  | _ => args
  }
  await Deno.Command.run("zola", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("zola", ["--version"], None)
}
