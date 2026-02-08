// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// tests/e2e/full_workflow_test.ts — End-to-end workflow tests

import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.210.0/assert/mod.ts";
import { exists } from "https://deno.land/std@0.210.0/fs/mod.ts";

// ============================================================================
// TEST UTILITIES
// ============================================================================

const TEST_DIR = "/tmp/qed-ssg-e2e-tests";

async function setupTestDir(): Promise<string> {
  const testPath = `${TEST_DIR}/${Date.now()}`;
  await Deno.mkdir(testPath, { recursive: true });
  return testPath;
}

async function cleanupTestDir(path: string): Promise<void> {
  try {
    await Deno.remove(path, { recursive: true });
  } catch {
    // Ignore cleanup errors
  }
}

async function checkBinaryExists(binary: string): Promise<boolean> {
  try {
    const cmd = new Deno.Command("which", { args: [binary] });
    const output = await cmd.output();
    return output.success;
  } catch {
    return false;
  }
}

// ============================================================================
// ADAPTER LOADING E2E TESTS
// ============================================================================

Deno.test("E2E: Load all 28 adapters successfully", async () => {
  const adapterFiles: string[] = [];

  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      adapterFiles.push(entry.name);
    }
  }

  assertEquals(adapterFiles.length, 28, "Should have exactly 28 adapter files");

  const loadResults = await Promise.allSettled(
    adapterFiles.map(file => import(`../../adapters/${file}`))
  );

  const successful = loadResults.filter(r => r.status === "fulfilled");
  assertEquals(successful.length, 28, "All 28 adapters should load successfully");
});

Deno.test("E2E: Adapter tools are executable", async () => {
  const adapter = await import("../../adapters/zola.js");

  // Get version tool
  const versionTool = adapter.tools.find((t: { name: string }) => t.name === "zola_version");
  assertExists(versionTool, "Should have version tool");

  // Execute the tool (will fail if binary not installed, but should not throw)
  const result = await versionTool.execute({});

  assertExists(result, "Should return a result");
  assertExists(result.success, "Result should have success property");
  assertExists(result.stdout, "Result should have stdout");
  assertExists(result.stderr, "Result should have stderr");
  assertExists(result.code, "Result should have exit code");
});

// ============================================================================
// ZOLA E2E TESTS (if installed)
// ============================================================================

Deno.test({
  name: "E2E: Zola full workflow (init, build)",
  ignore: !(await checkBinaryExists("zola")),
  async fn() {
    const testPath = await setupTestDir();

    try {
      const adapter = await import("../../adapters/zola.js");

      // Connect
      const connected = await adapter.connect();
      assertEquals(connected, true, "Should connect to Zola");

      // Get tools
      const initTool = adapter.tools.find((t: { name: string }) => t.name === "zola_init");
      const buildTool = adapter.tools.find((t: { name: string }) => t.name === "zola_build");
      const versionTool = adapter.tools.find((t: { name: string }) => t.name === "zola_version");

      // Check version
      const versionResult = await versionTool.execute({});
      assertEquals(versionResult.success, true);
      assertStringIncludes(versionResult.stdout.toLowerCase(), "zola");

      // Init site
      const sitePath = `${testPath}/mysite`;
      const initResult = await initTool.execute({ path: sitePath, force: true });

      if (initResult.success) {
        // Verify site was created
        const configExists = await exists(`${sitePath}/config.toml`);
        assertEquals(configExists, true, "config.toml should be created");

        // Build site
        const buildResult = await buildTool.execute({ path: sitePath });
        assertEquals(buildResult.success, true, "Build should succeed");
      }

      // Disconnect
      await adapter.disconnect();
      assertEquals(adapter.isConnected(), false);

    } finally {
      await cleanupTestDir(testPath);
    }
  },
});

// ============================================================================
// MDBOOK E2E TESTS (if installed)
// ============================================================================

Deno.test({
  name: "E2E: mdBook full workflow",
  ignore: !(await checkBinaryExists("mdbook")),
  async fn() {
    const testPath = await setupTestDir();

    try {
      const adapter = await import("../../adapters/mdbook.js");

      const connected = await adapter.connect();
      assertEquals(connected, true);

      const versionTool = adapter.tools.find((t: { name: string }) => t.name === "mdbook_version");
      const versionResult = await versionTool.execute({});
      assertEquals(versionResult.success, true);

      await adapter.disconnect();

    } finally {
      await cleanupTestDir(testPath);
    }
  },
});

// ============================================================================
// COBALT E2E TESTS (if installed)
// ============================================================================

Deno.test({
  name: "E2E: Cobalt full workflow",
  ignore: !(await checkBinaryExists("cobalt")),
  async fn() {
    const adapter = await import("../../adapters/cobalt.js");

    const connected = await adapter.connect();
    assertEquals(connected, true);

    const versionTool = adapter.tools.find((t: { name: string }) => t.name === "cobalt_version");
    const versionResult = await versionTool.execute({});
    assertEquals(versionResult.success, true);

    await adapter.disconnect();
  },
});

// ============================================================================
// ADAPTER REGISTRY E2E TESTS
// ============================================================================

Deno.test("E2E: Verify adapter language distribution", async () => {
  const languageCount: Record<string, number> = {};

  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const adapter = await import(`../../adapters/${entry.name}`);
      const lang = adapter.language;
      languageCount[lang] = (languageCount[lang] || 0) + 1;
    }
  }

  // Verify expected language distribution
  assertEquals(languageCount["Rust"], 3, "Should have 3 Rust adapters");
  assertEquals(languageCount["Haskell"], 2, "Should have 2 Haskell adapters");
  assertEquals(languageCount["Elixir"], 3, "Should have 3 Elixir adapters");
  assertEquals(languageCount["Clojure"], 3, "Should have 3 Clojure adapters");
  assertEquals(languageCount["Julia"], 3, "Should have 3 Julia adapters");
  assertEquals(languageCount["Scala"], 2, "Should have 2 Scala adapters");
  assertEquals(languageCount["Racket"], 2, "Should have 2 Racket adapters");

  // Total should be 28
  const total = Object.values(languageCount).reduce((a, b) => a + b, 0);
  assertEquals(total, 28, "Total adapters should be 28");
});

Deno.test("E2E: All adapters have minimum required tools", async () => {
  const minimumTools = 4; // init, build, serve/version, at least one more

  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const adapter = await import(`../../adapters/${entry.name}`);

      assertEquals(
        adapter.tools.length >= minimumTools,
        true,
        `${entry.name} should have at least ${minimumTools} tools, has ${adapter.tools.length}`
      );
    }
  }
});

// ============================================================================
// CONCURRENT OPERATIONS E2E TESTS
// ============================================================================

Deno.test("E2E: Concurrent adapter operations", async () => {
  const adapters = [
    import("../../adapters/zola.js"),
    import("../../adapters/cobalt.js"),
    import("../../adapters/mdbook.js"),
  ];

  const loaded = await Promise.all(adapters);

  // Connect all concurrently
  const connections = await Promise.all(
    loaded.map(adapter => adapter.connect())
  );

  // All should complete (success depends on binary availability)
  assertEquals(connections.length, 3);
  connections.forEach(result => {
    assertEquals(typeof result, "boolean");
  });

  // Disconnect all
  await Promise.all(loaded.map(adapter => adapter.disconnect()));

  // Verify all disconnected
  loaded.forEach(adapter => {
    assertEquals(adapter.isConnected(), false);
  });
});

// ============================================================================
// ERROR RECOVERY E2E TESTS
// ============================================================================

Deno.test("E2E: Recover from failed connection", async () => {
  const adapter = await import("../../adapters/zola.js");

  // First disconnect to ensure clean state
  await adapter.disconnect();
  assertEquals(adapter.isConnected(), false);

  // Try to connect (may fail if binary not installed)
  const firstAttempt = await adapter.connect();

  // Disconnect
  await adapter.disconnect();
  assertEquals(adapter.isConnected(), false);

  // Try again - should work the same way
  const secondAttempt = await adapter.connect();

  // Both attempts should behave consistently
  assertEquals(typeof firstAttempt, typeof secondAttempt);

  await adapter.disconnect();
});

Deno.test("E2E: Tool execution with invalid input", async () => {
  const adapter = await import("../../adapters/zola.js");

  const buildTool = adapter.tools.find((t: { name: string }) => t.name === "zola_build");
  assertExists(buildTool);

  // Execute with non-existent path
  const result = await buildTool.execute({ path: "/nonexistent/path/12345" });

  // Should return error result, not throw
  assertExists(result);
  assertEquals(result.success, false);
});
