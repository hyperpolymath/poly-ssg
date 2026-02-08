// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Franklin adapter - Static site generator in Julia
// https://franklinjl.org/

open Adapter

let name = "Franklin"
let language = "Julia"
let description = "Static site generator for technical blogging in Julia"

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
    name: "franklin_new",
    description: "Create a new Franklin site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new site"))
      Dict.set(props, "template", makeProp("string", "Template name"))
      makeSchema(props, ["path"])
    },
  },
  {
    name: "franklin_serve",
    description: "Start Franklin development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 8000)"))
      Dict.set(props, "host", makeProp("string", "Host to bind to"))
      Dict.set(props, "clear", makeProp("boolean", "Clear cache before serving"))
      makeSchema(props, [])
    },
  },
  {
    name: "franklin_optimize",
    description: "Optimize the site for production",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "minify", makeProp("boolean", "Minify HTML/CSS/JS"))
      Dict.set(props, "prerender", makeProp("boolean", "Pre-render pages"))
      makeSchema(props, [])
    },
  },
  {
    name: "franklin_publish",
    description: "Publish site to GitHub Pages",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "franklin_version",
    description: "Get Julia/Franklin version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeNew = async (path: string, template: option<string>) => {
  let templateArg = switch template {
  | Some(t) => `, template="${t}"`
  | None => ""
  }
  await Deno.Command.run("julia", ["-e", `using Franklin; newsite("${path}"${templateArg})`], None)
}

let executeServe = async (path: option<string>, port: option<int>, host: option<string>, clear: option<bool>) => {
  let portArg = switch port {
  | Some(p) => `, port=${Int.toString(p)}`
  | None => ""
  }
  let hostArg = switch host {
  | Some(h) => `, host="${h}"`
  | None => ""
  }
  let clearArg = switch clear {
  | Some(true) => ", clear=true"
  | _ => ""
  }
  let dir = switch path {
  | Some(p) => `cd("${p}"); `
  | None => ""
  }
  await Deno.Command.run("julia", ["-e", `using Franklin; ${dir}serve(${portArg}${hostArg}${clearArg})`], None)
}

let executeOptimize = async (path: option<string>, minify: option<bool>, prerender: option<bool>) => {
  let minifyArg = switch minify {
  | Some(true) => ", minify=true"
  | _ => ""
  }
  let prerenderArg = switch prerender {
  | Some(true) => ", prerender=true"
  | _ => ""
  }
  let dir = switch path {
  | Some(p) => `cd("${p}"); `
  | None => ""
  }
  await Deno.Command.run("julia", ["-e", `using Franklin; ${dir}optimize(${minifyArg}${prerenderArg})`], None)
}

let executePublish = async (path: option<string>) => {
  let dir = switch path {
  | Some(p) => `cd("${p}"); `
  | None => ""
  }
  await Deno.Command.run("julia", ["-e", `using Franklin; ${dir}publish()`], None)
}

let executeVersion = async () => {
  await Deno.Command.run("julia", ["-e", "using Franklin; println(Franklin.FRANKLIN_VERSION)"], None)
}
