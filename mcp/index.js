#!/usr/bin/env -S deno run --allow-run --allow-read --allow-write --allow-env
// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

/**
 * polyglot-ssg-mcp - Unified MCP server for 28 static site generators
 *
 * Supports SSGs across 19 programming languages:
 * - Rust: Zola, Cobalt, mdBook
 * - Elixir: Serum, NimblePublisher, Tableau
 * - Haskell: Hakyll, Ema
 * - OCaml: YOCaml
 * - F#: Fornax
 * - Swift: Publish
 * - Common Lisp: Coleslaw
 * - Kotlin: Orchid
 * - Julia: Franklin.jl, StaticWebPages.jl, Documenter.jl
 * - Clojure: Cryogen, Perun, Babashka
 * - Scala: Laika, ScalaTex
 * - Erlang: Zotonic
 * - Racket: Pollen, Frog
 * - D: Reggae
 * - Tcl: Wub
 * - Crystal: Marmot
 * - Nim: Nimrod
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

// Import all SSG adapters
import * as zola from "./adapters/zola.js";
import * as cobalt from "./adapters/cobalt.js";
import * as mdbook from "./adapters/mdbook.js";
import * as serum from "./adapters/serum.js";
import * as nimblePublisher from "./adapters/nimble-publisher.js";
import * as tableau from "./adapters/tableau.js";
import * as hakyll from "./adapters/hakyll.js";
import * as ema from "./adapters/ema.js";
import * as yocaml from "./adapters/yocaml.js";
import * as fornax from "./adapters/fornax.js";
import * as publish from "./adapters/publish.js";
import * as coleslaw from "./adapters/coleslaw.js";
import * as orchid from "./adapters/orchid.js";
import * as franklin from "./adapters/franklin.js";
import * as staticwebpages from "./adapters/staticwebpages.js";
import * as documenter from "./adapters/documenter.js";
import * as cryogen from "./adapters/cryogen.js";
import * as perun from "./adapters/perun.js";
import * as babashka from "./adapters/babashka.js";
import * as laika from "./adapters/laika.js";
import * as scalatex from "./adapters/scalatex.js";
import * as zotonic from "./adapters/zotonic.js";
import * as pollen from "./adapters/pollen.js";
import * as frog from "./adapters/frog.js";
import * as reggae from "./adapters/reggae.js";
import * as wub from "./adapters/wub.js";
import * as marmot from "./adapters/marmot.js";
import * as nimrod from "./adapters/nimrod.js";

const adapters = [
  zola, cobalt, mdbook,
  serum, nimblePublisher, tableau,
  hakyll, ema,
  yocaml,
  fornax,
  publish,
  coleslaw,
  orchid,
  franklin, staticwebpages, documenter,
  cryogen, perun, babashka,
  laika, scalatex,
  zotonic,
  pollen, frog,
  reggae,
  wub,
  marmot,
  nimrod,
];

const FEEDBACK_URL = "https://github.com/hyperpolymath/polyglot-ssg-mcp/issues";

// Create MCP server
const server = new McpServer({
  name: "polyglot-ssg-mcp",
  version: "1.0.0",
  description: "Unified MCP server for 28 static site generators across 19 languages",
});

// ============================================================================
// Meta Tools
// ============================================================================

server.tool(
  "ssg_list",
  "List all available SSG adapters with their languages and connection status",
  {},
  async () => {
    const list = adapters.map(a => ({
      name: a.name,
      language: a.language,
      description: a.description,
      connected: a.isConnected(),
      toolCount: a.tools.length,
    }));

    // Group by language
    const byLanguage = {};
    for (const ssg of list) {
      if (!byLanguage[ssg.language]) {
        byLanguage[ssg.language] = [];
      }
      byLanguage[ssg.language].push(ssg);
    }

    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          total: adapters.length,
          languages: Object.keys(byLanguage).length,
          byLanguage,
          ssgs: list,
        }, null, 2),
      }],
    };
  }
);

server.tool(
  "ssg_detect",
  "Auto-detect which SSGs are installed on the system",
  {},
  async () => {
    const results = [];

    for (const adapter of adapters) {
      try {
        const connected = await adapter.connect();
        results.push({
          name: adapter.name,
          language: adapter.language,
          available: connected,
        });
      } catch {
        results.push({
          name: adapter.name,
          language: adapter.language,
          available: false,
        });
      }
    }

    const available = results.filter(r => r.available);
    const unavailable = results.filter(r => !r.available);

    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          summary: `${available.length}/${results.length} SSGs available`,
          available: available.map(r => `${r.name} (${r.language})`),
          unavailable: unavailable.map(r => `${r.name} (${r.language})`),
          details: results,
        }, null, 2),
      }],
    };
  }
);

server.tool(
  "ssg_help",
  "Get help for a specific SSG",
  {
    ssg: {
      type: "string",
      description: "SSG name (e.g., 'zola', 'hakyll', 'franklin')",
    },
  },
  async ({ ssg }) => {
    const adapter = adapters.find(a =>
      a.name.toLowerCase() === ssg.toLowerCase()
    );

    if (!adapter) {
      return {
        content: [{
          type: "text",
          text: `Unknown SSG: ${ssg}\n\nAvailable SSGs:\n${adapters.map(a => `  - ${a.name} (${a.language})`).join('\n')}`,
        }],
        isError: true,
      };
    }

    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          name: adapter.name,
          language: adapter.language,
          description: adapter.description,
          connected: adapter.isConnected(),
          tools: adapter.tools.map(t => ({
            name: t.name,
            description: t.description,
          })),
        }, null, 2),
      }],
    };
  }
);

server.tool(
  "ssg_version",
  "Get version information for polyglot-ssg-mcp",
  {},
  async () => {
    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          name: "polyglot-ssg-mcp",
          version: "1.0.0",
          ssgs: adapters.length,
          languages: [...new Set(adapters.map(a => a.language))].length,
          runtime: "Deno",
          core: "ReScript",
          feedback: FEEDBACK_URL,
        }, null, 2),
      }],
    };
  }
);

// ============================================================================
// Register tools from all adapters
// ============================================================================

for (const adapter of adapters) {
  for (const tool of adapter.tools) {
    server.tool(
      tool.name,
      tool.description,
      tool.inputSchema.properties || {},
      async (params) => {
        try {
          // Ensure connected
          if (!adapter.isConnected()) {
            const connected = await adapter.connect();
            if (!connected) {
              return {
                content: [{
                  type: "text",
                  text: `${adapter.name} is not available. Please install ${adapter.name} (${adapter.language}).`,
                }],
                isError: true,
              };
            }
          }

          // Execute tool
          const result = await tool.execute(params);
          return {
            content: [{
              type: "text",
              text: typeof result === "string" ? result : JSON.stringify(result, null, 2),
            }],
          };
        } catch (error) {
          return {
            content: [{
              type: "text",
              text: `Error: ${error.message}\n\nPlease report issues at: ${FEEDBACK_URL}`,
            }],
            isError: true,
          };
        }
      }
    );
  }
}

// ============================================================================
// Start server
// ============================================================================

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error(`polyglot-ssg-mcp started - ${adapters.length} SSGs across ${[...new Set(adapters.map(a => a.language))].length} languages`);
}

main().catch((error) => {
  console.error("Fatal error:", error);
  Deno.exit(1);
});
