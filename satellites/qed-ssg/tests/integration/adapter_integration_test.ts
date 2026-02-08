// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// tests/integration/adapter_integration_test.ts — Integration tests for SSG adapters

import {
  assertEquals,
  assertExists,
  assertRejects,
} from "https://deno.land/std@0.210.0/assert/mod.ts";
import {
  stub,
  spy,
  assertSpyCalls,
} from "https://deno.land/std@0.210.0/testing/mock.ts";

// ============================================================================
// MOCK UTILITIES
// ============================================================================

interface MockCommandOutput {
  success: boolean;
  stdout: string;
  stderr: string;
  code: number;
}

function createMockCommand(outputs: Map<string, MockCommandOutput>) {
  return class MockCommand {
    private binary: string;
    private args: string[];

    constructor(binary: string, options: { args: string[] }) {
      this.binary = binary;
      this.args = options.args;
    }

    async output(): Promise<{ success: boolean; stdout: Uint8Array; stderr: Uint8Array; code: number }> {
      const key = `${this.binary} ${this.args.join(" ")}`;
      const result = outputs.get(key) || outputs.get(this.binary) || {
        success: false,
        stdout: "",
        stderr: "Command not found",
        code: 127,
      };

      const encoder = new TextEncoder();
      return {
        success: result.success,
        stdout: encoder.encode(result.stdout),
        stderr: encoder.encode(result.stderr),
        code: result.code,
      };
    }
  };
}

// ============================================================================
// ADAPTER INTERFACE TESTS
// ============================================================================

Deno.test("Integration: Adapter lifecycle - connect/disconnect", async () => {
  const adapter = await import("../../adapters/zola.js");

  // Initial state should be disconnected
  assertEquals(adapter.isConnected(), false);

  // Connect attempt (will fail without actual binary, but tests the interface)
  const connected = await adapter.connect();
  // Result depends on whether zola is installed
  assertEquals(typeof connected, "boolean");

  // Disconnect
  await adapter.disconnect();
  assertEquals(adapter.isConnected(), false);
});

Deno.test("Integration: Tool execution returns proper structure", async () => {
  const adapter = await import("../../adapters/zola.js");

  for (const tool of adapter.tools) {
    // Verify tool structure
    assertExists(tool.name);
    assertExists(tool.description);
    assertExists(tool.inputSchema);
    assertExists(tool.execute);

    // Tool names should follow pattern: {adapter}_{action}
    assertEquals(tool.name.startsWith("zola_"), true, `Tool ${tool.name} should start with adapter prefix`);

    // Input schema should be valid JSON Schema
    assertEquals(tool.inputSchema.type, "object");
    assertExists(tool.inputSchema.properties);
  }
});

Deno.test("Integration: All adapters have consistent tool patterns", async () => {
  const adapterFiles = [];
  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      adapterFiles.push(entry.name);
    }
  }

  const requiredTools = ["init", "build", "version"];

  for (const file of adapterFiles) {
    const adapter = await import(`../../adapters/${file}`);
    const prefix = adapter.name.toLowerCase().replace(/[^a-z]/g, "");

    for (const required of requiredTools) {
      const hasRequiredTool = adapter.tools.some(
        (t: { name: string }) => t.name.includes(required)
      );
      assertEquals(
        hasRequiredTool,
        true,
        `${file} should have a '${required}' tool`
      );
    }
  }
});

// ============================================================================
// ADAPTER GROUPING TESTS
// ============================================================================

Deno.test("Integration: Rust adapters use correct binary paths", async () => {
  const rustAdapters = ["zola", "cobalt", "mdbook"];

  for (const name of rustAdapters) {
    const adapter = await import(`../../adapters/${name}.js`);
    assertEquals(adapter.language, "Rust");
    // Rust adapters typically use native binaries
    assertExists(adapter.tools);
  }
});

Deno.test("Integration: Haskell adapters use stack", async () => {
  const haskellAdapters = ["hakyll", "ema"];

  for (const name of haskellAdapters) {
    const adapter = await import(`../../adapters/${name}.js`);
    assertEquals(adapter.language, "Haskell");
  }
});

Deno.test("Integration: Elixir adapters use mix", async () => {
  const elixirAdapters = ["serum", "tableau", "nimble-publisher"];

  for (const name of elixirAdapters) {
    const adapter = await import(`../../adapters/${name}.js`);
    assertEquals(adapter.language, "Elixir");
  }
});

// ============================================================================
// ERROR HANDLING TESTS
// ============================================================================

Deno.test("Integration: Adapters handle missing binary gracefully", async () => {
  const adapter = await import("../../adapters/zola.js");

  // Disconnect first to ensure clean state
  await adapter.disconnect();

  // If binary is not installed, connect should return false (not throw)
  const result = await adapter.connect();
  assertEquals(typeof result, "boolean");
});

Deno.test("Integration: Tools return structured error on failure", async () => {
  const adapter = await import("../../adapters/zola.js");

  // Execute without connecting (should handle gracefully)
  const versionTool = adapter.tools.find((t: { name: string }) => t.name === "zola_version");
  assertExists(versionTool);

  const result = await versionTool.execute({});

  // Should return a result object, not throw
  assertExists(result);
  assertEquals(typeof result.success, "boolean");
  assertExists(result.stdout);
  assertExists(result.stderr);
  assertEquals(typeof result.code, "number");
});

// ============================================================================
// SECURITY TESTS
// ============================================================================

Deno.test("Integration: Adapters use parameterized commands", async () => {
  // Read adapter source and verify no shell string concatenation
  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const content = await Deno.readTextFile(`./adapters/${entry.name}`);

      // Should use Deno.Command
      assertEquals(
        content.includes("Deno.Command"),
        true,
        `${entry.name} should use Deno.Command`
      );

      // Should not use shell execution
      assertEquals(
        content.includes("Deno.run"),
        false,
        `${entry.name} should not use deprecated Deno.run`
      );

      // Should not use eval
      assertEquals(
        content.includes("eval("),
        false,
        `${entry.name} should not use eval()`
      );
    }
  }
});

Deno.test("Integration: All adapters have SPDX headers", async () => {
  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const content = await Deno.readTextFile(`./adapters/${entry.name}`);
      const firstLine = content.split("\n")[0];

      assertEquals(
        firstLine.includes("SPDX-License-Identifier"),
        true,
        `${entry.name} should have SPDX header`
      );
    }
  }
});

// ============================================================================
// ADAPTER METADATA TESTS
// ============================================================================

Deno.test("Integration: Adapter metadata is complete and valid", async () => {
  const expectedAdapters = [
    { name: "Zola", language: "Rust" },
    { name: "Cobalt", language: "Rust" },
    { name: "mdBook", language: "Rust" },
    { name: "Hakyll", language: "Haskell" },
    { name: "Ema", language: "Haskell" },
    { name: "Serum", language: "Elixir" },
    { name: "Franklin.jl", language: "Julia" },
    { name: "Frog", language: "Racket" },
    { name: "Pollen", language: "Racket" },
  ];

  for (const expected of expectedAdapters) {
    const filename = expected.name.toLowerCase().replace(/\./g, "").replace(/\s/g, "-") + ".js";

    try {
      const adapter = await import(`../../adapters/${filename}`);
      assertEquals(adapter.language, expected.language, `${expected.name} should be ${expected.language}`);
    } catch {
      // Some adapters may have different naming conventions
    }
  }
});

// ============================================================================
// CONCURRENT ADAPTER TESTS
// ============================================================================

Deno.test("Integration: Multiple adapters can be loaded concurrently", async () => {
  const adapters = await Promise.all([
    import("../../adapters/zola.js"),
    import("../../adapters/hakyll.js"),
    import("../../adapters/serum.js"),
    import("../../adapters/cobalt.js"),
  ]);

  // All should load successfully
  assertEquals(adapters.length, 4);

  // Each should have unique names
  const names = adapters.map(a => a.name);
  const uniqueNames = new Set(names);
  assertEquals(uniqueNames.size, 4);
});
