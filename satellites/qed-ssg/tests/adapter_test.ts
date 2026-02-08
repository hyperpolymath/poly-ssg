// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// tests/adapter_test.ts — Unit tests for SSG adapters

import { assertEquals, assertExists } from "https://deno.land/std@0.210.0/assert/mod.ts";

// Test adapter module structure
Deno.test("adapters have required exports", async () => {
  const adapterFiles = [];
  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js") && entry.name !== "README.md") {
      adapterFiles.push(entry.name);
    }
  }

  for (const file of adapterFiles) {
    const adapter = await import(`../adapters/${file}`);

    // Check required exports
    assertExists(adapter.name, `${file} should export 'name'`);
    assertExists(adapter.language, `${file} should export 'language'`);
    assertExists(adapter.description, `${file} should export 'description'`);
    assertExists(adapter.tools, `${file} should export 'tools'`);
    assertExists(adapter.connect, `${file} should export 'connect'`);
    assertExists(adapter.disconnect, `${file} should export 'disconnect'`);
    assertExists(adapter.isConnected, `${file} should export 'isConnected'`);

    // Check types
    assertEquals(typeof adapter.name, "string", `${file}.name should be a string`);
    assertEquals(typeof adapter.language, "string", `${file}.language should be a string`);
    assertEquals(typeof adapter.description, "string", `${file}.description should be a string`);
    assertEquals(Array.isArray(adapter.tools), true, `${file}.tools should be an array`);
    assertEquals(typeof adapter.connect, "function", `${file}.connect should be a function`);
    assertEquals(typeof adapter.disconnect, "function", `${file}.disconnect should be a function`);
    assertEquals(typeof adapter.isConnected, "function", `${file}.isConnected should be a function`);
  }
});

// Test tool structure
Deno.test("adapter tools have correct structure", async () => {
  const adapter = await import("../adapters/zola.js");

  for (const tool of adapter.tools) {
    assertExists(tool.name, "Tool should have 'name'");
    assertExists(tool.description, "Tool should have 'description'");
    assertExists(tool.inputSchema, "Tool should have 'inputSchema'");
    assertExists(tool.execute, "Tool should have 'execute'");

    assertEquals(typeof tool.name, "string");
    assertEquals(typeof tool.description, "string");
    assertEquals(typeof tool.execute, "function");
  }
});

// Test adapter count
Deno.test("28 adapters are available", async () => {
  let count = 0;
  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      count++;
    }
  }
  assertEquals(count, 28, "Should have exactly 28 adapters");
});

// Test isConnected returns boolean
Deno.test("isConnected returns boolean", async () => {
  const adapter = await import("../adapters/zola.js");
  const result = adapter.isConnected();
  assertEquals(typeof result, "boolean");
});
