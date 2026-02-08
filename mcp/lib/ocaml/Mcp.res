// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// MCP SDK bindings for ReScript

type toolHandler = JSON.t => promise<JSON.t>

type toolSchema = {
  @as("type") type_: string,
  properties: dict<JSON.t>,
  required?: array<string>,
}

type mcpTool = {
  name: string,
  description: string,
  inputSchema: toolSchema,
}

type serverCapabilities = {
  tools: {listChanged: bool},
}

type serverInfo = {
  name: string,
  version: string,
  description?: string,
}

type mcpServerConfig = {
  name: string,
  version: string,
  description?: string,
}

// STDIO Transport binding
type stdioTransport

@module("@modelcontextprotocol/sdk/server/stdio.js") @new
external createStdioTransport: unit => stdioTransport = "StdioServerTransport"

// MCP Server class binding
type mcpServer

@module("@modelcontextprotocol/sdk/server/mcp.js") @new
external createMcpServer: mcpServerConfig => mcpServer = "McpServer"

@send
external tool: (mcpServer, string, string, dict<JSON.t>, toolHandler) => unit = "tool"

@send
external connect: (mcpServer, stdioTransport) => promise<unit> = "connect"

// Tool result types
type contentItem = {
  @as("type") type_: string,
  text: string,
}

type toolResult = {
  content: array<contentItem>,
  isError?: bool,
}

let makeTextContent = (text: string): contentItem => {
  type_: "text",
  text,
}

let makeToolResult = (text: string, ~isError=false): toolResult => {
  content: [makeTextContent(text)],
  isError: ?isError ? Some(true) : None,
}

let makeJsonResult = (data: JSON.t): toolResult => {
  content: [makeTextContent(JSON.stringify(data, ~space=2))],
}
