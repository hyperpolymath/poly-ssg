// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Babashka adapter - Fast native Clojure scripting
// https://babashka.org/

open Adapter

let name = "Babashka"
let language = "Clojure"
let description = "Fast native Clojure scripting runtime for static site tasks"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("bb", ["--version"], None)
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
    name: "bb_run",
    description: "Run a Babashka script",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "script", makeProp("string", "Script file to run"))
      Dict.set(props, "path", makeProp("string", "Working directory"))
      Dict.set(props, "args", makeProp("string", "Arguments to pass"))
      makeSchema(props, ["script"])
    },
  },
  {
    name: "bb_tasks",
    description: "List available bb.edn tasks",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, [])
    },
  },
  {
    name: "bb_task",
    description: "Run a bb.edn task",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "task", makeProp("string", "Task name"))
      Dict.set(props, "path", makeProp("string", "Path to project root"))
      makeSchema(props, ["task"])
    },
  },
  {
    name: "bb_nrepl",
    description: "Start nREPL server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "port", makeProp("number", "nREPL port"))
      Dict.set(props, "path", makeProp("string", "Working directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "bb_version",
    description: "Get Babashka version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeRun = async (script: string, path: option<string>, args: option<string>) => {
  let cmdArgs = [script]
  let cmdArgs = switch args {
  | Some(a) => Array.concat(cmdArgs, [a])
  | None => cmdArgs
  }
  await Deno.Command.run("bb", cmdArgs, path)
}

let executeTasks = async (path: option<string>) => {
  await Deno.Command.run("bb", ["tasks"], path)
}

let executeTask = async (task: string, path: option<string>) => {
  await Deno.Command.run("bb", [task], path)
}

let executeNrepl = async (port: option<int>, path: option<string>) => {
  let args = ["nrepl-server"]
  let args = switch port {
  | Some(p) => Array.concat(args, [Int.toString(p)])
  | None => args
  }
  await Deno.Command.run("bb", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("bb", ["--version"], None)
}
