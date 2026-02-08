// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// mdBook adapter - Create books from Markdown in Rust
// https://rust-lang.github.io/mdBook/

open Adapter

let name = "MdBook"
let language = "Rust"
let description = "Create books from Markdown files using Rust"

let state: adapterState = {
  connected: false,
  projectPath: None,
}

let connect = async () => {
  try {
    let result = await Deno.Command.run("mdbook", ["--version"], None)
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
    name: "mdbook_init",
    description: "Initialize a new mdBook",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path for the new book"))
      Dict.set(props, "title", makeProp("string", "Book title"))
      Dict.set(props, "theme", makeProp("boolean", "Copy default theme"))
      makeSchema(props, [])
    },
  },
  {
    name: "mdbook_build",
    description: "Build the mdBook",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to book root"))
      Dict.set(props, "dest", makeProp("string", "Output directory"))
      Dict.set(props, "open", makeProp("boolean", "Open in browser after build"))
      makeSchema(props, [])
    },
  },
  {
    name: "mdbook_serve",
    description: "Start mdBook development server",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to book root"))
      Dict.set(props, "port", makeProp("number", "Port number (default: 3000)"))
      Dict.set(props, "hostname", makeProp("string", "Hostname to bind to"))
      Dict.set(props, "open", makeProp("boolean", "Open in browser"))
      makeSchema(props, [])
    },
  },
  {
    name: "mdbook_watch",
    description: "Watch for changes and rebuild",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to book root"))
      Dict.set(props, "dest", makeProp("string", "Output directory"))
      makeSchema(props, [])
    },
  },
  {
    name: "mdbook_clean",
    description: "Clean the build directory",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to book root"))
      makeSchema(props, [])
    },
  },
  {
    name: "mdbook_test",
    description: "Test Rust code samples in the book",
    inputSchema: {
      let props = Dict.make()
      Dict.set(props, "path", makeProp("string", "Path to book root"))
      Dict.set(props, "chapter", makeProp("string", "Specific chapter to test"))
      makeSchema(props, [])
    },
  },
  {
    name: "mdbook_version",
    description: "Get mdBook version",
    inputSchema: makeSchema(Dict.make(), []),
  },
]

let executeInit = async (path: option<string>, title: option<string>, theme: option<bool>) => {
  let args = ["init"]
  let args = switch path {
  | Some(p) => Array.concat(args, [p])
  | None => args
  }
  let args = switch title {
  | Some(t) => Array.concat(args, ["--title", t])
  | None => args
  }
  let args = switch theme {
  | Some(true) => Array.concat(args, ["--theme"])
  | _ => args
  }
  await Deno.Command.run("mdbook", args, None)
}

let executeBuild = async (path: option<string>, dest: option<string>, open_: option<bool>) => {
  let args = ["build"]
  let args = switch dest {
  | Some(d) => Array.concat(args, ["--dest-dir", d])
  | None => args
  }
  let args = switch open_ {
  | Some(true) => Array.concat(args, ["--open"])
  | _ => args
  }
  await Deno.Command.run("mdbook", args, path)
}

let executeServe = async (path: option<string>, port: option<int>, hostname: option<string>, open_: option<bool>) => {
  let args = ["serve"]
  let args = switch port {
  | Some(p) => Array.concat(args, ["--port", Int.toString(p)])
  | None => args
  }
  let args = switch hostname {
  | Some(h) => Array.concat(args, ["--hostname", h])
  | None => args
  }
  let args = switch open_ {
  | Some(true) => Array.concat(args, ["--open"])
  | _ => args
  }
  await Deno.Command.run("mdbook", args, path)
}

let executeWatch = async (path: option<string>, dest: option<string>) => {
  let args = ["watch"]
  let args = switch dest {
  | Some(d) => Array.concat(args, ["--dest-dir", d])
  | None => args
  }
  await Deno.Command.run("mdbook", args, path)
}

let executeClean = async (path: option<string>) => {
  await Deno.Command.run("mdbook", ["clean"], path)
}

let executeTest = async (path: option<string>, chapter: option<string>) => {
  let args = ["test"]
  let args = switch chapter {
  | Some(c) => Array.concat(args, ["--chapter", c])
  | None => args
  }
  await Deno.Command.run("mdbook", args, path)
}

let executeVersion = async () => {
  await Deno.Command.run("mdbook", ["--version"], None)
}
