// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// adapter_test.ts — E2E tests for SSG adapters

import { assertEquals, assertExists } from "https://deno.land/std@0.208.0/assert/mod.ts";

const ADAPTERS_DIR = new URL("../../adapters/", import.meta.url).pathname;

Deno.test("E2E - All adapters export required interface", async () => {
  const adapters = [];

  for await (const entry of Deno.readDir(ADAPTERS_DIR)) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      adapters.push(entry.name);
    }
  }

  // Should have 28 adapters
  assertEquals(adapters.length, 28, "Expected 28 SSG adapters");

  for (const adapterFile of adapters) {
    const adapterPath = `${ADAPTERS_DIR}${adapterFile}`;
    const module = await import(adapterPath);

    // Check required exports
    assertExists(module.name, `${adapterFile}: missing 'name' export`);
    assertExists(module.language, `${adapterFile}: missing 'language' export`);
    assertExists(module.description, `${adapterFile}: missing 'description' export`);
    assertExists(module.connect, `${adapterFile}: missing 'connect' export`);
    assertExists(module.disconnect, `${adapterFile}: missing 'disconnect' export`);
    assertExists(module.isConnected, `${adapterFile}: missing 'isConnected' export`);
    assertExists(module.tools, `${adapterFile}: missing 'tools' export`);

    // Check tools is an array
    assertEquals(
      Array.isArray(module.tools),
      true,
      `${adapterFile}: 'tools' should be an array`
    );

    // Check each tool has required properties
    for (const tool of module.tools) {
      assertExists(tool.name, `${adapterFile}: tool missing 'name'`);
      assertExists(tool.description, `${adapterFile}: tool missing 'description'`);
      assertExists(tool.inputSchema, `${adapterFile}: tool missing 'inputSchema'`);
      assertExists(tool.execute, `${adapterFile}: tool missing 'execute'`);
    }
  }
});

Deno.test("E2E - Adapter names are unique", async () => {
  const names = new Set<string>();

  for await (const entry of Deno.readDir(ADAPTERS_DIR)) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const adapterPath = `${ADAPTERS_DIR}${entry.name}`;
      const module = await import(adapterPath);

      assertEquals(
        names.has(module.name),
        false,
        `Duplicate adapter name: ${module.name}`
      );
      names.add(module.name);
    }
  }
});

Deno.test("E2E - All adapters have SPDX headers", async () => {
  for await (const entry of Deno.readDir(ADAPTERS_DIR)) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const content = await Deno.readTextFile(`${ADAPTERS_DIR}${entry.name}`);
      const hasSPDX = content.includes("SPDX-License-Identifier");

      assertEquals(
        hasSPDX,
        true,
        `${entry.name}: missing SPDX license header`
      );
    }
  }
});

Deno.test("E2E - Adapter tool names follow convention", async () => {
  for await (const entry of Deno.readDir(ADAPTERS_DIR)) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const adapterPath = `${ADAPTERS_DIR}${entry.name}`;
      const module = await import(adapterPath);
      const adapterName = entry.name.replace(".js", "").replace(/-/g, "_");

      for (const tool of module.tools) {
        // Tool names should start with adapter name
        assertEquals(
          tool.name.startsWith(adapterName),
          true,
          `${entry.name}: tool '${tool.name}' should start with '${adapterName}_'`
        );
      }
    }
  }
});

Deno.test("E2E - Adapter languages are valid", async () => {
  const validLanguages = new Set([
    "Rust", "Haskell", "Elixir", "Julia", "Clojure",
    "Racket", "Scala", "F#", "OCaml", "Swift",
    "Kotlin", "Nim", "D", "Crystal", "Tcl",
    "Common Lisp", "Erlang"
  ]);

  for await (const entry of Deno.readDir(ADAPTERS_DIR)) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const adapterPath = `${ADAPTERS_DIR}${entry.name}`;
      const module = await import(adapterPath);

      assertEquals(
        validLanguages.has(module.language),
        true,
        `${entry.name}: invalid language '${module.language}'`
      );
    }
  }
});
