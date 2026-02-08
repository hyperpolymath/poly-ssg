#!/usr/bin/env -S deno run --allow-run --allow-read --allow-write --allow-env --allow-net
// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

/**
 * Polyglot SSG MCP Server - Dual Mode Entry Point
 *
 * Supports both:
 * - STDIO transport (default, for local MCP clients)
 * - Streamable HTTP transport (for remote/cloud deployment)
 *
 * Usage:
 *   Local:  deno task start
 *   HTTP:   deno task serve
 *   Deploy: deno deploy (auto-detects HTTP mode)
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { StreamableHttpTransport } from "./transport/streamable-http.js";

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
  zola,
  cobalt,
  mdbook,
  serum,
  nimblePublisher,
  tableau,
  hakyll,
  ema,
  yocaml,
  fornax,
  publish,
  coleslaw,
  orchid,
  franklin,
  staticwebpages,
  documenter,
  cryogen,
  perun,
  babashka,
  laika,
  scalatex,
  zotonic,
  pollen,
  frog,
  reggae,
  wub,
  marmot,
  nimrod,
];

const PACKAGE_VERSION = "1.1.0";
const FEEDBACK_URL = "https://github.com/hyperpolymath/polyglot-ssg-mcp/issues";

/**
 * Create and configure the MCP server with all tools
 */
function createMcpServer() {
  const server = new McpServer({
    name: "polyglot-ssg-mcp",
    version: PACKAGE_VERSION,
    description:
      "Unified MCP server for 28 static site generators across 19 languages",
  });

  // ============================================================================
  // Meta Tools
  // ============================================================================

  server.tool(
    "ssg_list",
    "List all available SSG adapters with their languages and connection status",
    {},
    async () => {
      const list = adapters.map((a) => ({
        name: a.name,
        language: a.language,
        description: a.description,
        connected: a.isConnected(),
        toolCount: a.tools.length,
      }));

      const byLanguage = {};
      for (const ssg of list) {
        if (!byLanguage[ssg.language]) {
          byLanguage[ssg.language] = [];
        }
        byLanguage[ssg.language].push(ssg);
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                total: adapters.length,
                languages: Object.keys(byLanguage).length,
                byLanguage,
                ssgs: list,
              },
              null,
              2
            ),
          },
        ],
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

      const available = results.filter((r) => r.available);
      const unavailable = results.filter((r) => !r.available);

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                summary: `${available.length}/${results.length} SSGs available`,
                available: available.map((r) => `${r.name} (${r.language})`),
                unavailable: unavailable.map((r) => `${r.name} (${r.language})`),
                details: results,
              },
              null,
              2
            ),
          },
        ],
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
      const adapter = adapters.find(
        (a) => a.name.toLowerCase() === ssg.toLowerCase()
      );

      if (!adapter) {
        return {
          content: [
            {
              type: "text",
              text: `Unknown SSG: ${ssg}\n\nAvailable SSGs:\n${adapters.map((a) => `  - ${a.name} (${a.language})`).join("\n")}`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                name: adapter.name,
                language: adapter.language,
                description: adapter.description,
                connected: adapter.isConnected(),
                tools: adapter.tools.map((t) => ({
                  name: t.name,
                  description: t.description,
                })),
              },
              null,
              2
            ),
          },
        ],
      };
    }
  );

  server.tool(
    "ssg_version",
    "Get version information for polyglot-ssg-mcp",
    {},
    async () => {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                name: "polyglot-ssg-mcp",
                version: PACKAGE_VERSION,
                ssgs: adapters.length,
                languages: [...new Set(adapters.map((a) => a.language))].length,
                runtime: "Deno",
                core: "ReScript",
                feedback: FEEDBACK_URL,
              },
              null,
              2
            ),
          },
        ],
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
            if (!adapter.isConnected()) {
              const connected = await adapter.connect();
              if (!connected) {
                return {
                  content: [
                    {
                      type: "text",
                      text: `${adapter.name} is not available. Please install ${adapter.name} (${adapter.language}).`,
                    },
                  ],
                  isError: true,
                };
              }
            }

            const result = await tool.execute(params);
            return {
              content: [
                {
                  type: "text",
                  text:
                    typeof result === "string"
                      ? result
                      : JSON.stringify(result, null, 2),
                },
              ],
            };
          } catch (error) {
            return {
              content: [
                {
                  type: "text",
                  text: `Error: ${error.message}\n\nPlease report issues at: ${FEEDBACK_URL}`,
                },
              ],
              isError: true,
            };
          }
        }
      );
    }
  }

  return server;
}

/**
 * Detect if running in serverless environment
 */
function isServerlessEnvironment() {
  return (
    Deno.env.get("DENO_DEPLOYMENT_ID") !== undefined ||
    Deno.env.get("MCP_HTTP_MODE") === "true" ||
    Deno.args.includes("--http")
  );
}

/**
 * Start the server in STDIO mode (local MCP client)
 */
async function startStdioMode(server) {
  const languageCount = [...new Set(adapters.map((a) => a.language))].length;
  console.error(`polyglot-ssg-mcp v${PACKAGE_VERSION} (STDIO mode)`);
  console.error(`${adapters.length} SSGs across ${languageCount} languages`);
  console.error(`Feedback: ${FEEDBACK_URL}`);

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

/**
 * Start the server in HTTP mode (remote/cloud)
 */
async function startHttpMode(server) {
  const port = parseInt(Deno.env.get("PORT") || "8000");
  const host = Deno.env.get("HOST") || "0.0.0.0";
  const languageCount = [...new Set(adapters.map((a) => a.language))].length;

  console.error(`polyglot-ssg-mcp v${PACKAGE_VERSION} (HTTP mode)`);
  console.error(`${adapters.length} SSGs across ${languageCount} languages`);
  console.error(`Listening on http://${host}:${port}/mcp`);
  console.error(`Feedback: ${FEEDBACK_URL}`);

  const transport = new StreamableHttpTransport(null, { path: "/mcp" });

  // Build tools list for HTTP mode
  const allTools = [];

  // Meta tools
  allTools.push(
    {
      name: "ssg_list",
      description:
        "List all available SSG adapters with their languages and connection status",
    },
    { name: "ssg_detect", description: "Auto-detect which SSGs are installed" },
    { name: "ssg_help", description: "Get help for a specific SSG" },
    { name: "ssg_version", description: "Get version information" }
  );

  // Adapter tools
  for (const adapter of adapters) {
    for (const tool of adapter.tools) {
      allTools.push({
        name: tool.name,
        description: tool.description,
        inputSchema: tool.inputSchema,
      });
    }
  }

  transport.onMessage(async (message) => {
    if (message.method === "initialize") {
      return {
        jsonrpc: "2.0",
        id: message.id,
        result: {
          protocolVersion: "2025-06-18",
          capabilities: {
            tools: { listChanged: true },
          },
          serverInfo: {
            name: "polyglot-ssg-mcp",
            version: PACKAGE_VERSION,
          },
        },
      };
    }

    if (message.method === "tools/list") {
      return {
        jsonrpc: "2.0",
        id: message.id,
        result: { tools: allTools },
      };
    }

    if (message.method === "tools/call") {
      const { name, arguments: args } = message.params;

      // Handle meta tools
      if (name === "ssg_list") {
        const list = adapters.map((a) => ({
          name: a.name,
          language: a.language,
          description: a.description,
          connected: a.isConnected(),
          toolCount: a.tools.length,
        }));
        return {
          jsonrpc: "2.0",
          id: message.id,
          result: {
            content: [{ type: "text", text: JSON.stringify(list, null, 2) }],
          },
        };
      }

      if (name === "ssg_version") {
        return {
          jsonrpc: "2.0",
          id: message.id,
          result: {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    name: "polyglot-ssg-mcp",
                    version: PACKAGE_VERSION,
                    ssgs: adapters.length,
                    languages: languageCount,
                  },
                  null,
                  2
                ),
              },
            ],
          },
        };
      }

      // Find adapter tool
      for (const adapter of adapters) {
        const tool = adapter.tools.find((t) => t.name === name);
        if (tool) {
          try {
            if (!adapter.isConnected()) {
              await adapter.connect();
            }
            const result = await tool.execute(args || {});
            return {
              jsonrpc: "2.0",
              id: message.id,
              result: {
                content: [
                  {
                    type: "text",
                    text:
                      typeof result === "string"
                        ? result
                        : JSON.stringify(result, null, 2),
                  },
                ],
              },
            };
          } catch (error) {
            return {
              jsonrpc: "2.0",
              id: message.id,
              error: {
                code: -32603,
                message: error.message,
              },
            };
          }
        }
      }

      return {
        jsonrpc: "2.0",
        id: message.id,
        error: {
          code: -32601,
          message: `Tool not found: ${name}`,
        },
      };
    }

    return {
      jsonrpc: "2.0",
      id: message.id,
      error: {
        code: -32601,
        message: `Method not found: ${message.method}`,
      },
    };
  });

  const handler = async (request) => {
    const url = new URL(request.url);

    if (url.pathname === "/health") {
      return new Response(
        JSON.stringify({
          status: "ok",
          version: PACKAGE_VERSION,
          ssgs: adapters.length,
          languages: languageCount,
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    if (url.pathname === "/" || url.pathname === "/info") {
      return new Response(
        JSON.stringify({
          name: "polyglot-ssg-mcp",
          version: PACKAGE_VERSION,
          protocol: "MCP Streamable HTTP",
          protocolVersion: "2025-06-18",
          endpoint: "/mcp",
          ssgs: adapters.map((a) => ({ name: a.name, language: a.language })),
          documentation: "https://github.com/hyperpolymath/polyglot-ssg-mcp",
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    return transport.handleRequest(request);
  };

  Deno.serve({ port, hostname: host }, handler);
}

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================

const server = createMcpServer();

if (isServerlessEnvironment()) {
  await startHttpMode(server);
} else {
  await startStdioMode(server);
}
