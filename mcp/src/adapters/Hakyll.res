// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Hakyll adapter - Static site generator in Haskell
// https://jaspervdj.be/hakyll/

open Adapter

let name = "Hakyll"
let language = "Haskell"
let description = "Haskell library for generating static sites with Pandoc support"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("stack", ["--version"], None)
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
    name: "hakyll_init",
    description: "Initialize a new Hakyll site (using stack template)",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Project name"))
      Dict.set(props, "path", makeProp("string", "Path for the project"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "hakyll_build",
    description: "Build the Hakyll site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "hakyll_watch",
    description: "Start Hakyll watch server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      Dict.set(props, "host", makeProp("string", "Host to bind to"))
      makeSchema(props, [])
    },
  },
  {
    name: "hakyll_clean",
    description: "Clean the build cache",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "hakyll_rebuild",
    description: "Clean and rebuild the site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "hakyll_check",
    description: "Check for broken links",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      Dict.set(props, "internal", makeProp("boolean", "Check internal links only"))
      makeSchema(props, [])
    },
  },
  {
    name: "hakyll_deploy",
    description: "Deploy the site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to site root"))
      makeSchema(props, [])
    },
  },
  {
    name: "hakyll_version",
    description: "Get Stack/Hakyll version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

// Helper for running site commands via stack exec
let runSiteCommand = async (args: array<string>, path: option<string>) => {
  await Deno.Command.run("stack", Array.concat(["exec", "site", "--"], args), path)
}

let executeInit = async (name: string, path: option<string>) => {
  await Deno.Command.run("stack", ["new", name, "hakyll-template"], path)
}

let executeBuild = async (path: option<string>) => {
  await runSiteCommand(["build"], path)
}

let executeWatch = async (path: option<string>, port: option<int>, host: option<string>) => {
  let args = ["watch"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  let args = switch host {
  | Some(h) => Array.concat(args, ["--host", h])
  | None => args
  }
  await runSiteCommand(args, path)
}

let executeClean = async (path: option<string>) => {
  await runSiteCommand(["clean"], path)
}

let executeRebuild = async (path: option<string>) => {
  await runSiteCommand(["rebuild"], path)
}

let executeCheck = async (path: option<string>, internal: option<bool>) => {
  let args = ["check"]
  let args = switch internal {
  | Some(true) => Array.concat(args, ["--internal-links"])
  | _ => args
  }
  await runSiteCommand(args, path)
}

let executeDeploy = async (path: option<string>) => {
  await runSiteCommand(["deploy"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("stack", ["--version"], None)
}
