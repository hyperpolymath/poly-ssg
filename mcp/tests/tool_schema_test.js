// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
//
// Integration tests for MCP tool schema validation

import { assertEquals, assertExists, assert } from "https://deno.land/std@0.208.0/assert/mod.ts";

// Import all adapters
import * as Zola from "../lib/es6/src/adapters/Zola.res.js";
import * as Hakyll from "../lib/es6/src/adapters/Hakyll.res.js";
import * as Cobalt from "../lib/es6/src/adapters/Cobalt.res.js";
import * as MdBook from "../lib/es6/src/adapters/MdBook.res.js";
import * as Serum from "../lib/es6/src/adapters/Serum.res.js";
import * as Franklin from "../lib/es6/src/adapters/Franklin.res.js";
import * as Pollen from "../lib/es6/src/adapters/Pollen.res.js";

const allAdapters = [Zola, Hakyll, Cobalt, MdBook, Serum, Franklin, Pollen];

// Standard tool names that adapters commonly implement
const standardToolSuffixes = [
  "_init",
  "_build",
  "_serve",
  "_check",
  "_version",
  "_clean",
];

// JSON Schema property types
const validSchemaTypes = ["string", "number", "boolean", "integer", "object", "array"];

Deno.test("Tool Schema: All schemas have valid type property", async (t) => {
  for (const adapter of allAdapters) {
    await t.step(`${adapter.name} tool schemas`, () => {
      for (const tool of adapter.tools) {
        const schema = tool.inputSchema;
        if (schema.properties) {
          for (const [propName, propSchema] of Object.entries(schema.properties)) {
            if (propSchema.type) {
              assert(
                validSchemaTypes.includes(propSchema.type),
                `${tool.name}.${propName} has invalid type: ${propSchema.type}`
              );
            }
          }
        }
      }
    });
  }
});

Deno.test("Tool Schema: Required array contains valid property names", async (t) => {
  for (const adapter of allAdapters) {
    await t.step(`${adapter.name} required properties exist`, () => {
      for (const tool of adapter.tools) {
        const schema = tool.inputSchema;
        if (schema.required && Array.isArray(schema.required)) {
          const propNames = schema.properties ? Object.keys(schema.properties) : [];
          for (const reqProp of schema.required) {
            assert(
              propNames.includes(reqProp),
              `${tool.name} requires '${reqProp}' but it's not in properties`
            );
          }
        }
      }
    });
  }
});

Deno.test("Tool Schema: Property descriptions are strings", async (t) => {
  for (const adapter of allAdapters) {
    await t.step(`${adapter.name} property descriptions`, () => {
      for (const tool of adapter.tools) {
        const schema = tool.inputSchema;
        if (schema.properties) {
          for (const [propName, propSchema] of Object.entries(schema.properties)) {
            if (propSchema.description) {
              assertEquals(
                typeof propSchema.description,
                "string",
                `${tool.name}.${propName} description should be string`
              );
            }
          }
        }
      }
    });
  }
});

Deno.test("Tool Schema: Standard tools follow naming pattern", async (t) => {
  for (const adapter of allAdapters) {
    const prefix = adapter.name.toLowerCase().replace(/[^a-z]/g, "");
    await t.step(`${adapter.name} tool naming convention`, () => {
      for (const tool of adapter.tools) {
        // Tool name should start with adapter-specific prefix
        assert(
          tool.name.startsWith(prefix) || tool.name.includes("_"),
          `${tool.name} should follow ${prefix}_action naming`
        );
      }
    });
  }
});

Deno.test("Tool Schema: No empty descriptions", async (t) => {
  for (const adapter of allAdapters) {
    await t.step(`${adapter.name} descriptions not empty`, () => {
      for (const tool of adapter.tools) {
        assert(
          tool.description.length > 10,
          `${tool.name} description should be meaningful (>10 chars)`
        );
      }
    });
  }
});

Deno.test("Tool Schema: Path properties use string type", async (t) => {
  const pathPropertyNames = ["path", "outputDir", "inputDir", "rootPath", "basePath"];

  for (const adapter of allAdapters) {
    await t.step(`${adapter.name} path properties are strings`, () => {
      for (const tool of adapter.tools) {
        const schema = tool.inputSchema;
        if (schema.properties) {
          for (const pathProp of pathPropertyNames) {
            if (schema.properties[pathProp]) {
              assertEquals(
                schema.properties[pathProp].type,
                "string",
                `${tool.name}.${pathProp} should be string type`
              );
            }
          }
        }
      }
    });
  }
});
