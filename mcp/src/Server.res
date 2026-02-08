// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Polyglot SSG MCP Server - Main Entry Point
// Supports both STDIO transport (local) and HTTP transport (remote/cloud)

open Adapter
open Mcp

let packageVersion = "1.1.0"
let feedbackUrl = "https://github.com/hyperpolymath/polyglot-ssg-mcp/issues"

// ============================================================================
// Adapter Registry
// ============================================================================

type adapterModule = {
  name: string,
  language: string,
  description: string,
  connect: unit => promise<bool>,
  disconnect: unit => promise<unit>,
  isConnected: unit => bool,
  tools: array<tool>,
}

// Import all adapters (compiled from ReScript)
@module("./adapters/Zola.res.js")
external zolaAdapter: adapterModule = "default"

@module("./adapters/Cobalt.res.js")
external cobaltAdapter: adapterModule = "default"

@module("./adapters/Mdbook.res.js")
external mdbookAdapter: adapterModule = "default"

@module("./adapters/Serum.res.js")
external serumAdapter: adapterModule = "default"

@module("./adapters/NimblePublisher.res.js")
external nimblePublisherAdapter: adapterModule = "default"

@module("./adapters/Tableau.res.js")
external tableauAdapter: adapterModule = "default"

@module("./adapters/Hakyll.res.js")
external hakyllAdapter: adapterModule = "default"

@module("./adapters/Ema.res.js")
external emaAdapter: adapterModule = "default"

@module("./adapters/Yocaml.res.js")
external yocamlAdapter: adapterModule = "default"

@module("./adapters/Fornax.res.js")
external fornaxAdapter: adapterModule = "default"

@module("./adapters/Publish.res.js")
external publishAdapter: adapterModule = "default"

@module("./adapters/Coleslaw.res.js")
external coleslawAdapter: adapterModule = "default"

@module("./adapters/Orchid.res.js")
external orchidAdapter: adapterModule = "default"

@module("./adapters/Franklin.res.js")
external franklinAdapter: adapterModule = "default"

@module("./adapters/Staticwebpages.res.js")
external staticwebpagesAdapter: adapterModule = "default"

@module("./adapters/Documenter.res.js")
external documenterAdapter: adapterModule = "default"

@module("./adapters/Cryogen.res.js")
external cryogenAdapter: adapterModule = "default"

@module("./adapters/Perun.res.js")
external perunAdapter: adapterModule = "default"

@module("./adapters/Babashka.res.js")
external babashkaAdapter: adapterModule = "default"

@module("./adapters/Laika.res.js")
external laikaAdapter: adapterModule = "default"

@module("./adapters/Scalatex.res.js")
external scalatexAdapter: adapterModule = "default"

@module("./adapters/Zotonic.res.js")
external zotonicAdapter: adapterModule = "default"

@module("./adapters/Pollen.res.js")
external pollenAdapter: adapterModule = "default"

@module("./adapters/Frog.res.js")
external frogAdapter: adapterModule = "default"

@module("./adapters/Reggae.res.js")
external reggaeAdapter: adapterModule = "default"

@module("./adapters/Wub.res.js")
external wubAdapter: adapterModule = "default"

@module("./adapters/Marmot.res.js")
external marmotAdapter: adapterModule = "default"

@module("./adapters/Nimrod.res.js")
external nimrodAdapter: adapterModule = "default"

@module("./adapters/Corral.res.js")
external corralAdapter: adapterModule = "default"

// All adapters array - populated at runtime
let adapters: array<adapterModule> = []

let initAdapters = () => {
  // Note: In actual implementation, these would be imported from compiled ES6 modules
  // For now, the array is populated by the main entry script
  ()
}

// ============================================================================
// Adapter Helper Functions
// ============================================================================

let getUniqueLanguages = (adapters: array<adapterModule>) => {
  let languages = Dict.make()
  Array.forEach(adapters, a => {
    Dict.set(languages, a.language, true)
  })
  Dict.keysToArray(languages)
}

let groupByLanguage = (adapters: array<adapterModule>) => {
  let byLang: Dict.t<array<adapterModule>> = Dict.make()
  Array.forEach(adapters, a => {
    let existing = switch Dict.get(byLang, a.language) {
    | Some(arr) => arr
    | None => []
    }
    Dict.set(byLang, a.language, Array.concat(existing, [a]))
  })
  byLang
}

let findAdapter = (adapters: array<adapterModule>, name: string) => {
  Array.find(adapters, a => String.toLowerCase(a.name) == String.toLowerCase(name))
}

// ============================================================================
// Meta Tools
// ============================================================================

let ssgListTool = (adapters: array<adapterModule>) => {
  async () => {
    let list = Array.map(adapters, a => {
      let item = Dict.make()
      Dict.set(item, "name", JSON.Encode.string(a.name))
      Dict.set(item, "language", JSON.Encode.string(a.language))
      Dict.set(item, "description", JSON.Encode.string(a.description))
      Dict.set(item, "connected", JSON.Encode.bool(a.isConnected()))
      Dict.set(item, "toolCount", JSON.Encode.int(Array.length(a.tools)))
      JSON.Encode.object(item)
    })

    let byLanguage = groupByLanguage(adapters)
    let byLangJson = Dict.make()
    let keys = Dict.keysToArray(byLanguage)
    Array.forEach(keys, lang => {
      switch Dict.get(byLanguage, lang) {
      | Some(arr) =>
        Dict.set(
          byLangJson,
          lang,
          JSON.Encode.array(
            Array.map(arr, a => {
              let item = Dict.make()
              Dict.set(item, "name", JSON.Encode.string(a.name))
              Dict.set(item, "language", JSON.Encode.string(a.language))
              JSON.Encode.object(item)
            }),
          ),
        )
      | None => ()
      }
    })

    let result = Dict.make()
    Dict.set(result, "total", JSON.Encode.int(Array.length(adapters)))
    Dict.set(result, "languages", JSON.Encode.int(Array.length(keys)))
    Dict.set(result, "byLanguage", JSON.Encode.object(byLangJson))
    Dict.set(result, "ssgs", JSON.Encode.array(list))

    makeJsonResult(JSON.Encode.object(result))
  }
}

let ssgDetectTool = (adapters: array<adapterModule>) => {
  async () => {
    let results = []

    for i in 0 to Array.length(adapters) - 1 {
      let a = adapters->Array.getUnsafe(i)
      let available = try {
        await a.connect()
      } catch {
      | _ => false
      }
      let item = Dict.make()
      Dict.set(item, "name", JSON.Encode.string(a.name))
      Dict.set(item, "language", JSON.Encode.string(a.language))
      Dict.set(item, "available", JSON.Encode.bool(available))
      Array.push(results, JSON.Encode.object(item))
    }

    let available = Array.filter(results, r => {
      switch JSON.Decode.object(r) {
      | Some(obj) =>
        switch Dict.get(obj, "available") {
        | Some(v) =>
          switch JSON.Decode.bool(v) {
          | Some(b) => b
          | None => false
          }
        | None => false
        }
      | None => false
      }
    })

    let unavailable = Array.filter(results, r => {
      switch JSON.Decode.object(r) {
      | Some(obj) =>
        switch Dict.get(obj, "available") {
        | Some(v) =>
          switch JSON.Decode.bool(v) {
          | Some(b) => !b
          | None => true
          }
        | None => true
        }
      | None => true
      }
    })

    let summary =
      Int.toString(Array.length(available)) ++
      "/" ++
      Int.toString(Array.length(results)) ++
      " SSGs available"

    let result = Dict.make()
    Dict.set(result, "summary", JSON.Encode.string(summary))
    Dict.set(result, "available", JSON.Encode.array(available))
    Dict.set(result, "unavailable", JSON.Encode.array(unavailable))
    Dict.set(result, "details", JSON.Encode.array(results))

    makeJsonResult(JSON.Encode.object(result))
  }
}

let ssgHelpTool = (adapters: array<adapterModule>) => {
  async (params: JSON.t) => {
    let ssgName = switch JSON.Decode.object(params) {
    | Some(obj) =>
      switch Dict.get(obj, "ssg") {
      | Some(v) => JSON.Decode.string(v)
      | None => None
      }
    | None => None
    }

    switch ssgName {
    | None => makeToolResult("Missing required parameter: ssg", ~isError=true)
    | Some(name) =>
      switch findAdapter(adapters, name) {
      | None =>
        let availableList = Array.map(adapters, a => "  - " ++ a.name ++ " (" ++ a.language ++ ")")
        makeToolResult(
          "Unknown SSG: " ++ name ++ "\n\nAvailable SSGs:\n" ++ Array.join(availableList, "\n"),
          ~isError=true,
        )
      | Some(adapter) =>
        let tools = Array.map(adapter.tools, t => {
          let item = Dict.make()
          Dict.set(item, "name", JSON.Encode.string(t.name))
          Dict.set(item, "description", JSON.Encode.string(t.description))
          JSON.Encode.object(item)
        })

        let result = Dict.make()
        Dict.set(result, "name", JSON.Encode.string(adapter.name))
        Dict.set(result, "language", JSON.Encode.string(adapter.language))
        Dict.set(result, "description", JSON.Encode.string(adapter.description))
        Dict.set(result, "connected", JSON.Encode.bool(adapter.isConnected()))
        Dict.set(result, "tools", JSON.Encode.array(tools))

        makeJsonResult(JSON.Encode.object(result))
      }
    }
  }
}

let ssgVersionTool = (adapters: array<adapterModule>) => {
  async () => {
    let languages = getUniqueLanguages(adapters)
    let result = Dict.make()
    Dict.set(result, "name", JSON.Encode.string("polyglot-ssg-mcp"))
    Dict.set(result, "version", JSON.Encode.string(packageVersion))
    Dict.set(result, "ssgs", JSON.Encode.int(Array.length(adapters)))
    Dict.set(result, "languages", JSON.Encode.int(Array.length(languages)))
    Dict.set(result, "runtime", JSON.Encode.string("Deno"))
    Dict.set(result, "core", JSON.Encode.string("ReScript"))
    Dict.set(result, "feedback", JSON.Encode.string(feedbackUrl))

    makeJsonResult(JSON.Encode.object(result))
  }
}

// ============================================================================
// Server Configuration
// ============================================================================

type serverMode = Stdio | Http

let isServerlessEnvironment = () => {
  Deno.Env.get("DENO_DEPLOYMENT_ID")->Option.isSome ||
    Deno.Env.get("MCP_HTTP_MODE") == Some("true") ||
    Array.includes(Deno.Args.get(), "--http")
}

let detectMode = () => {
  if isServerlessEnvironment() {
    Http
  } else {
    Stdio
  }
}

// ============================================================================
// Server Startup
// ============================================================================

let logStartup = (mode: serverMode, adapters: array<adapterModule>) => {
  let modeStr = switch mode {
  | Stdio => "STDIO"
  | Http => "HTTP"
  }
  let languageCount = Array.length(getUniqueLanguages(adapters))
  Console.error("polyglot-ssg-mcp v" ++ packageVersion ++ " (" ++ modeStr ++ " mode)")
  Console.error(
    Int.toString(Array.length(adapters)) ++
    " SSGs across " ++
    Int.toString(languageCount) ++
    " languages",
  )
  Console.error("Feedback: " ++ feedbackUrl)
}

// ============================================================================
// Tool Execution Wrapper
// ============================================================================

let executeAdapterTool = async (adapter: adapterModule, tool: tool, params: JSON.t) => {
  try {
    if !adapter.isConnected() {
      let connected = await adapter.connect()
      if !connected {
        makeToolResult(
          adapter.name ++
          " is not available. Please install " ++
          adapter.name ++
          " (" ++
          adapter.language ++
          ").",
          ~isError=true,
        )
      } else {
        switch tool.execute {
        | Some(executeFn) =>
          let result = await executeFn(params)
          makeJsonResult(result)
        | None => makeToolResult("Tool execution not implemented", ~isError=true)
        }
      }
    } else {
      switch tool.execute {
      | Some(executeFn) =>
        let result = await executeFn(params)
        makeJsonResult(result)
      | None => makeToolResult("Tool execution not implemented", ~isError=true)
      }
    }
  } catch {
  | JsExn(e) =>
    let msg = switch JsExn.message(e) {
    | Some(m) => m
    | None => "Unknown error"
    }
    makeToolResult("Error: " ++ msg ++ "\n\nPlease report issues at: " ++ feedbackUrl, ~isError=true)
  }
}
