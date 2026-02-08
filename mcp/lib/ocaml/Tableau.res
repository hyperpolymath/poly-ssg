// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Tableau adapter - Static site generator in Elixir
// https://github.com/elixir-tools/tableau

open Adapter

let name = "Tableau"
let language = "Elixir"
let description = "Static site generator for Elixir with LiveView support"

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
    name: "tableau_init",
    description: "Initialize a new Tableau project",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "name", makeProp("string", "Project name"))
      Dict.set(props, "path", makeProp("string", "Path for the project"))
      makeSchema(props, ["name"])
    },
  },
  {
    name: "tableau_build",
    description: "Build the Tableau site",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "tableau_server",
    description: "Start Tableau development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      Dict.set(props, "port", makeProp("number", "Port number"))
      makeSchema(props, [])
    },
  },
  {
    name: "tableau_version",
    description: "Get Mix/Elixir version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (name: string, path: option<string>) => {
  await Deno.Command.run("mix", ["tableau.new", name], path)
}

let executeBuild = async (path: option<string>) => {
  await Deno.Command.run("mix", ["tableau.build"], path)
}

let executeServer = async (path: option<string>, _port: option<int>) => {
  await Deno.Command.run("mix", ["tableau.server"], path)
}

let executeVersion = async () => {
  await Deno.Command.run("mix", ["--version"], None)
}
