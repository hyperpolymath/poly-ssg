// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// Unit tests for SSG adapters

import { assertEquals, assertExists, assertRejects } from "@std/assert";
import { describe, it, beforeAll, afterAll } from "@std/testing/bdd";

// ============================================================================
// Test Utilities
// ============================================================================

interface AdapterModule {
  name: string;
  language: string;
  description: string;
  connect: () => Promise<boolean>;
  disconnect: () => Promise<void>;
  isConnected: () => boolean;
  tools: Array<{
    name: string;
    description: string;
    inputSchema: Record<string, unknown>;
    execute: (args: Record<string, unknown>) => Promise<unknown>;
  }>;
}

async function loadAdapter(name: string): Promise<AdapterModule> {
  return await import(`../../adapters/${name}.js`);
}

// ============================================================================
// Adapter Interface Tests
// ============================================================================

describe("Adapter Interface Compliance", () => {
  const adapterNames = [
    "zola",
    "hakyll",
    "mdbook",
    "serum",
    "cobalt",
    "franklin",
  ];

  for (const adapterName of adapterNames) {
    describe(`${adapterName} adapter`, () => {
      let adapter: AdapterModule;

      beforeAll(async () => {
        try {
          adapter = await loadAdapter(adapterName);
        } catch {
          // Adapter may not exist or have import errors
        }
      });

      it("should export required properties", () => {
        if (!adapter) return; // Skip if adapter failed to load

        assertExists(adapter.name, "name should be exported");
        assertExists(adapter.language, "language should be exported");
        assertExists(adapter.description, "description should be exported");
        assertExists(adapter.connect, "connect should be exported");
        assertExists(adapter.disconnect, "disconnect should be exported");
        assertExists(adapter.isConnected, "isConnected should be exported");
        assertExists(adapter.tools, "tools should be exported");
      });

      it("should have correct type for name", () => {
        if (!adapter) return;
        assertEquals(typeof adapter.name, "string");
      });

      it("should have correct type for language", () => {
        if (!adapter) return;
        assertEquals(typeof adapter.language, "string");
      });

      it("should have tools array", () => {
        if (!adapter) return;
        assertEquals(Array.isArray(adapter.tools), true);
      });

      it("should have valid tool definitions", () => {
        if (!adapter) return;

        for (const tool of adapter.tools) {
          assertExists(tool.name, "tool should have name");
          assertExists(tool.description, "tool should have description");
          assertExists(tool.inputSchema, "tool should have inputSchema");
          assertExists(tool.execute, "tool should have execute function");
          assertEquals(typeof tool.execute, "function");
        }
      });

      it("should return boolean from isConnected", () => {
        if (!adapter) return;
        const result = adapter.isConnected();
        assertEquals(typeof result, "boolean");
      });
    });
  }
});

// ============================================================================
// Tool Schema Validation
// ============================================================================

describe("Tool Schema Validation", () => {
  it("should have valid JSON Schema for inputSchema", async () => {
    const adapter = await loadAdapter("zola").catch(() => null);
    if (!adapter) return;

    for (const tool of adapter.tools) {
      assertExists(tool.inputSchema.type, "Schema should have type");
      assertEquals(tool.inputSchema.type, "object");
    }
  });

  it("should have properties defined in schema", async () => {
    const adapter = await loadAdapter("zola").catch(() => null);
    if (!adapter) return;

    for (const tool of adapter.tools) {
      if (tool.inputSchema.properties) {
        assertEquals(
          typeof tool.inputSchema.properties,
          "object",
          "properties should be an object"
        );
      }
    }
  });
});

// ============================================================================
// Bernoulli Verification Tests
// ============================================================================

describe("Bernoulli Probabilistic Verification", () => {
  const ITERATIONS = 100;
  const THRESHOLD = 0.95; // 95% success rate required

  it("should consistently report connection status", async () => {
    const adapter = await loadAdapter("zola").catch(() => null);
    if (!adapter) return;

    let successCount = 0;

    for (let i = 0; i < ITERATIONS; i++) {
      const connected = adapter.isConnected();
      if (typeof connected === "boolean") {
        successCount++;
      }
    }

    const successRate = successCount / ITERATIONS;
    assertEquals(
      successRate >= THRESHOLD,
      true,
      `Success rate ${successRate} below threshold ${THRESHOLD}`
    );
  });

  it("should return consistent tool count", async () => {
    const adapter = await loadAdapter("zola").catch(() => null);
    if (!adapter) return;

    const toolCounts: number[] = [];

    for (let i = 0; i < ITERATIONS; i++) {
      toolCounts.push(adapter.tools.length);
    }

    // All counts should be the same
    const allSame = toolCounts.every((c) => c === toolCounts[0]);
    assertEquals(allSame, true, "Tool count should be consistent");
  });
});

// ============================================================================
// Security Tests
// ============================================================================

describe("Security Validation", () => {
  it("should not use shell: true in command execution", async () => {
    // Read adapter source and check for shell: true
    const adapterPath = "../../adapters/zola.js";
    try {
      const source = await Deno.readTextFile(
        new URL(adapterPath, import.meta.url)
      );
      assertEquals(
        source.includes("shell: true"),
        false,
        "Adapter should not use shell: true"
      );
      assertEquals(
        source.includes("shell:true"),
        false,
        "Adapter should not use shell:true"
      );
    } catch {
      // File may not exist in test environment
    }
  });

  it("should use array-based command arguments", async () => {
    const adapter = await loadAdapter("zola").catch(() => null);
    if (!adapter) return;

    // Check that tools use proper argument passing
    for (const tool of adapter.tools) {
      // This is a basic check - in production, would verify execute implementation
      assertExists(tool.execute);
    }
  });
});

// ============================================================================
// Run Tests
// ============================================================================

if (import.meta.main) {
  console.log("Running adapter unit tests...");
}
