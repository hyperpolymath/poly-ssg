// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
//
// Integration tests for SSG adapter interface compliance

import { assertEquals, assertExists, assert } from "https://deno.land/std@0.208.0/assert/mod.ts";

// Import compiled adapters
import * as Zola from "../lib/es6/src/adapters/Zola.res.js";
import * as Hakyll from "../lib/es6/src/adapters/Hakyll.res.js";
import * as Cobalt from "../lib/es6/src/adapters/Cobalt.res.js";
import * as MdBook from "../lib/es6/src/adapters/MdBook.res.js";
import * as Serum from "../lib/es6/src/adapters/Serum.res.js";

// All adapters to test
const adapters = [
  { module: Zola, expectedName: "Zola", expectedLang: "Rust" },
  { module: Hakyll, expectedName: "Hakyll", expectedLang: "Haskell" },
  { module: Cobalt, expectedName: "Cobalt", expectedLang: "Rust" },
  { module: MdBook, expectedName: "mdBook", expectedLang: "Rust" },
  { module: Serum, expectedName: "Serum", expectedLang: "Elixir" },
];

// Required exports for adapter interface
const requiredExports = [
  "name",
  "language",
  "description",
  "connect",
  "disconnect",
  "isConnected",
  "tools",
  "state",
];

Deno.test("Adapter Interface: All adapters export required properties", async (t) => {
  for (const { module, expectedName } of adapters) {
    await t.step(`${expectedName} has all required exports`, () => {
      for (const exportName of requiredExports) {
        assertExists(
          module[exportName],
          `${expectedName} missing required export: ${exportName}`
        );
      }
    });
  }
});

Deno.test("Adapter Interface: Name and language are strings", async (t) => {
  for (const { module, expectedName, expectedLang } of adapters) {
    await t.step(`${expectedName} name and language match`, () => {
      assertEquals(typeof module.name, "string");
      assertEquals(typeof module.language, "string");
      assertEquals(module.name, expectedName);
      assertEquals(module.language, expectedLang);
    });
  }
});

Deno.test("Adapter Interface: Tools is an array with valid structure", async (t) => {
  for (const { module, expectedName } of adapters) {
    await t.step(`${expectedName} tools array is valid`, () => {
      assert(Array.isArray(module.tools), `${expectedName}.tools should be an array`);
      assert(module.tools.length > 0, `${expectedName} should have at least one tool`);

      for (const tool of module.tools) {
        assertExists(tool.name, "Tool must have name");
        assertExists(tool.description, "Tool must have description");
        assertExists(tool.inputSchema, "Tool must have inputSchema");
        assertEquals(typeof tool.name, "string");
        assertEquals(typeof tool.description, "string");
      }
    });
  }
});

Deno.test("Adapter Interface: Connect/disconnect are async functions", async (t) => {
  for (const { module, expectedName } of adapters) {
    await t.step(`${expectedName} connect/disconnect are functions`, () => {
      assertEquals(typeof module.connect, "function");
      assertEquals(typeof module.disconnect, "function");
      assertEquals(typeof module.isConnected, "function");
    });
  }
});

Deno.test("Adapter Interface: State has correct shape", async (t) => {
  for (const { module, expectedName } of adapters) {
    await t.step(`${expectedName} state structure is valid`, () => {
      assertExists(module.state, `${expectedName} must have state`);
      assertEquals(
        typeof module.state.connected,
        "boolean",
        "state.connected should be boolean"
      );
    });
  }
});

Deno.test("Adapter Interface: Tool names follow naming convention", async (t) => {
  const toolNamePattern = /^[a-z][a-z0-9_]*$/;

  for (const { module, expectedName } of adapters) {
    await t.step(`${expectedName} tool names follow convention`, () => {
      for (const tool of module.tools) {
        assert(
          toolNamePattern.test(tool.name),
          `Tool name '${tool.name}' should be lowercase with underscores`
        );
      }
    });
  }
});

Deno.test("Adapter Interface: InputSchema is valid JSON Schema", async (t) => {
  for (const { module, expectedName } of adapters) {
    await t.step(`${expectedName} tool schemas are valid`, () => {
      for (const tool of module.tools) {
        const schema = tool.inputSchema;

        // Schema should be an object
        assertEquals(typeof schema, "object", "Schema should be object");

        // Should have type: "object" (standard for MCP tools)
        if (schema.type) {
          assertEquals(schema.type, "object", "Schema type should be 'object'");
        }
      }
    });
  }
});
