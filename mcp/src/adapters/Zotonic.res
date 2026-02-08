// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Zotonic adapter - CMS and framework in Erlang
// https://zotonic.com/

open Adapter

let name = "Zotonic"
let language = "Erlang"
let description = "Content management system and web framework in Erlang"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("zotonic", ["status"], None)
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
    name: "zotonic_siteadd",
    description: "Add a new Zotonic site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Site name"))
      Dict.set(props, "hostname", makeProp("string", "Site hostname"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "zotonic_start",
    description: "Start Zotonic",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to Zotonic installation"))
      makeSchema(props, [])
    },
  },
  {
    name: "zotonic_stop",
    description: "Stop Zotonic",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to Zotonic installation"))
      makeSchema(props, [])
    },
  },
  {
    name: "zotonic_sitestart",
    description: "Start a specific site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Site name"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "zotonic_sitestop",
    description: "Stop a specific site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Site name"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "zotonic_compile",
    description: "Compile Zotonic",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to Zotonic installation"))
      makeSchema(props, [])
    },
  },
  {
    name: "zotonic_version",
    description: "Get Zotonic version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeSiteadd = async (name: string, hostname: option<string>) => {
  let args = ["siteadd", name]
  let args = switch hostname {
  | Some(h) => Array.concat(args, ["-h", h])
  | None => args
  }
  await Deno.Command.run("zotonic", args, None)
}

let executeStart = async (path: option<string>) => {
  await Deno.Command.run("zotonic", ["start"], path)
}

let executeStop = async (path: option<string>) => {
  await Deno.Command.run("zotonic", ["stop"], path)
}

let executeSitestart = async (name: string) => {
  await Deno.Command.run("zotonic", ["sitestart", name], None)
}

let executeSitestop = async (name: string) => {
  await Deno.Command.run("zotonic", ["sitestop", name], None)
}

let executeCompile = async (path: option<string>) => {
  await Deno.Command.run("zotonic", ["compile"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("zotonic", ["status"], None)
}
