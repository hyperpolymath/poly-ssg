// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// NimblePublisher adapter - Markdown-based publishing in Elixir
// https://github.com/dashbitco/nimble_publisher

open Adapter

let name = "NimblePublisher"
let language = "Elixir"
let description = "Markdown-based publishing library for Elixir/Phoenix"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("mix", ["--version"], None)
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
    name: "nimble_publisher_init",
    description: "Initialize a new Phoenix project with NimblePublisher",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Project name"))
      Dict.set(props, "path", makeProp("string", "Path for the project"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "nimble_publisher_build",
    description: "Compile the Phoenix project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "nimble_publisher_server",
    description: "Start Phoenix development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 4000)"))
      makeSchema(props, [])
    },
  },
  {
    name: "nimble_publisher_version",
    description: "Get Mix/Elixir version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (name: string, path: option<string>) => {
  await Deno.Command.run("mix", ["phx.new", name], path)
}

let executeBuild = async (path: option<string>) => {
  await Deno.Command.run("mix", ["compile"], path)
}

let executeServer = async (path: option<string>, port: option<int>) => {
  let args = ["phx.server"]
  let _ = port // Phoenix uses config for port
  await Deno.Command.run("mix", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("mix", ["--version"], None)
}
