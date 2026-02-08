#!/usr/bin/env -S deno run --allow-run --allow-read --allow-write --allow-env --allow-net
// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// Thin entry shim - imports ReScript modules and starts the MCP server

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

// Import all adapters from compiled ReScript
import * as Zola from "./lib/es6/src/adapters/Zola.res.js";
import * as Cobalt from "./lib/es6/src/adapters/Cobalt.res.js";
import * as MdBook from "./lib/es6/src/adapters/MdBook.res.js";
import * as Serum from "./lib/es6/src/adapters/Serum.res.js";
import * as NimblePublisher from "./lib/es6/src/adapters/NimblePublisher.res.js";
import * as Tableau from "./lib/es6/src/adapters/Tableau.res.js";
import * as Hakyll from "./lib/es6/src/adapters/Hakyll.res.js";
import * as Ema from "./lib/es6/src/adapters/Ema.res.js";
import * as YOCaml from "./lib/es6/src/adapters/YOCaml.res.js";
import * as Fornax from "./lib/es6/src/adapters/Fornax.res.js";
import * as Publish from "./lib/es6/src/adapters/Publish.res.js";
import * as Coleslaw from "./lib/es6/src/adapters/Coleslaw.res.js";
import * as Orchid from "./lib/es6/src/adapters/Orchid.res.js";
import * as Franklin from "./lib/es6/src/adapters/Franklin.res.js";
import * as StaticWebPages from "./lib/es6/src/adapters/StaticWebPages.res.js";
import * as Documenter from "./lib/es6/src/adapters/Documenter.res.js";
import * as Cryogen from "./lib/es6/src/adapters/Cryogen.res.js";
import * as Perun from "./lib/es6/src/adapters/Perun.res.js";
import * as Babashka from "./lib/es6/src/adapters/Babashka.res.js";
import * as Laika from "./lib/es6/src/adapters/Laika.res.js";
import * as ScalaTex from "./lib/es6/src/adapters/ScalaTex.res.js";
import * as Zotonic from "./lib/es6/src/adapters/Zotonic.res.js";
import * as Pollen from "./lib/es6/src/adapters/Pollen.res.js";
import * as Frog from "./lib/es6/src/adapters/Frog.res.js";
import * as Reggae from "./lib/es6/src/adapters/Reggae.res.js";
import * as Wub from "./lib/es6/src/adapters/Wub.res.js";
import * as Marmot from "./lib/es6/src/adapters/Marmot.res.js";
import * as Nimrod from "./lib/es6/src/adapters/Nimrod.res.js";
import * as Corral from "./lib/es6/src/adapters/Corral.res.js";

const adapters = [
  Zola, Cobalt, MdBook,
  Serum, NimblePublisher, Tableau,
  Hakyll, Ema,
  YOCaml,
  Fornax,
  Publish,
  Coleslaw,
  Orchid,
  Franklin, StaticWebPages, Documenter,
  Cryogen, Perun, Babashka,
  Laika, ScalaTex,
  Zotonic,
  Pollen, Frog,
  Reggae,
  Wub,
  Marmot,
  Nimrod,
  Corral,
];

const PACKAGE_VERSION = "1.1.0";
const FEEDBACK_URL = "https://github.com/hyperpolymath/polyglot-ssg-mcp/issues";

// Create MCP server
const server = new McpServer({
  name: "polyglot-ssg-mcp",
  version: PACKAGE_VERSION,
  description: "Unified MCP server for 29 static site generators across 20 languages",
});

// Meta tools
server.tool("ssg_list", "List all available SSG adapters", {}, async () => {
  const list = adapters.map(a => ({
    name: a.name,
    language: a.language,
    description: a.description,
    connected: a.isConnected(),
    toolCount: a.tools.length,
  }));
  return { content: [{ type: "text", text: JSON.stringify(list, null, 2) }] };
});

server.tool("ssg_detect", "Auto-detect installed SSGs", {}, async () => {
  const results = [];
  for (const a of adapters) {
    try {
      const connected = await a.connect();
      results.push({ name: a.name, language: a.language, available: connected });
    } catch {
      results.push({ name: a.name, language: a.language, available: false });
    }
  }
  const available = results.filter(r => r.available);
  return {
    content: [{
      type: "text",
      text: JSON.stringify({
        summary: `${available.length}/${results.length} SSGs available`,
        available: available.map(r => `${r.name} (${r.language})`),
        details: results,
      }, null, 2),
    }],
  };
});

server.tool("ssg_help", "Get help for a specific SSG", {
  ssg: { type: "string", description: "SSG name" },
}, async ({ ssg }) => {
  const adapter = adapters.find(a => a.name.toLowerCase() === ssg.toLowerCase());
  if (!adapter) {
    return {
      content: [{ type: "text", text: `Unknown SSG: ${ssg}` }],
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
        tools: adapter.tools.map(t => ({ name: t.name, description: t.description })),
      }, null, 2),
    }],
  };
});

server.tool("ssg_version", "Get version information", {}, async () => {
  const languages = [...new Set(adapters.map(a => a.language))];
  return {
    content: [{
      type: "text",
      text: JSON.stringify({
        name: "polyglot-ssg-mcp",
        version: PACKAGE_VERSION,
        ssgs: adapters.length,
        languages: languages.length,
        runtime: "Deno",
        core: "ReScript",
        feedback: FEEDBACK_URL,
      }, null, 2),
    }],
  };
});

// Register adapter tools
for (const adapter of adapters) {
  for (const tool of adapter.tools) {
    const props = tool.inputSchema?.properties || {};
    server.tool(tool.name, tool.description, props, async (params) => {
      try {
        if (!adapter.isConnected()) {
          const connected = await adapter.connect();
          if (!connected) {
            return {
              content: [{ type: "text", text: `${adapter.name} is not available.` }],
              isError: true,
            };
          }
        }
        // Call execute if available, otherwise return tool info
        if (tool.execute) {
          const result = await tool.execute(params);
          return {
            content: [{
              type: "text",
              text: typeof result === "string" ? result : JSON.stringify(result, null, 2),
            }],
          };
        }
        return {
          content: [{ type: "text", text: `Tool ${tool.name} registered (execute not implemented yet)` }],
        };
      } catch (error) {
        return {
          content: [{ type: "text", text: `Error: ${error.message}` }],
          isError: true,
        };
      }
    });
  }
}

// Start server
const languages = [...new Set(adapters.map(a => a.language))];
console.error(`polyglot-ssg-mcp v${PACKAGE_VERSION} (STDIO mode)`);
console.error(`${adapters.length} SSGs across ${languages.length} languages`);
console.error(`Feedback: ${FEEDBACK_URL}`);

const transport = new StdioServerTransport();
await server.connect(transport);
