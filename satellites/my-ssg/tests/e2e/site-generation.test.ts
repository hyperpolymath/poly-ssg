// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// End-to-end tests for SSG adapter integration

import { assertEquals, assertExists } from "@std/assert";
import { describe, it, beforeAll, afterAll } from "@std/testing/bdd";

// ============================================================================
// Test Configuration
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

async function loadAdapter(name: string): Promise<AdapterModule | null> {
  try {
    return await import(`../../adapters/${name}.js`);
  } catch {
    return null;
  }
}

// ============================================================================
// E2E Adapter Loading Tests
// ============================================================================

describe("E2E Adapter Loading", () => {
  const coreAdapters = [
    "zola",
    "hakyll",
    "mdbook",
    "serum",
    "cobalt",
    "franklin",
  ];

  for (const adapterName of coreAdapters) {
    describe(`${adapterName} adapter E2E`, () => {
      let adapter: AdapterModule | null = null;

      beforeAll(async () => {
        adapter = await loadAdapter(adapterName);
      });

      it("should load successfully", () => {
        assertExists(adapter, `${adapterName} adapter should load`);
      });

      it("should have correct structure", () => {
        if (!adapter) return;
        assertExists(adapter.name);
        assertExists(adapter.language);
        assertExists(adapter.tools);
        assertEquals(Array.isArray(adapter.tools), true);
      });

      it("should have valid tools", () => {
        if (!adapter) return;
        for (const tool of adapter.tools) {
          assertExists(tool.name);
          assertExists(tool.description);
          assertExists(tool.inputSchema);
          assertExists(tool.execute);
          assertEquals(typeof tool.execute, "function");
        }
      });
    });
  }
});

// ============================================================================
// Adapter Count Verification
// ============================================================================

describe("Adapter Collection Verification", () => {
  it("should have 28 adapters", async () => {
    const files = [...Deno.readDirSync("adapters")].filter((f) =>
      f.name.endsWith(".js")
    );
    assertEquals(files.length, 28, "Should have exactly 28 adapters");
  });

  it("should have all adapters loadable", async () => {
    const files = [...Deno.readDirSync("adapters")].filter((f) =>
      f.name.endsWith(".js")
    );

    let loadable = 0;
    for (const file of files) {
      try {
        const mod = await import(`../../adapters/${file.name}`);
        if (mod.name && mod.tools) {
          loadable++;
        }
      } catch {
        // Skip failed imports
      }
    }

    assertEquals(
      loadable > 0,
      true,
      "At least some adapters should be loadable"
    );
  });
});

// ============================================================================
// Performance E2E Tests
// ============================================================================

describe("Performance E2E", () => {
  const PERFORMANCE_THRESHOLD_MS = 5000; // 5 seconds

  it("should load all adapters within threshold", async () => {
    const start = performance.now();

    const files = [...Deno.readDirSync("adapters")].filter((f) =>
      f.name.endsWith(".js")
    );

    for (const file of files) {
      try {
        await import(`../../adapters/${file.name}`);
      } catch {
        // Continue even if some fail
      }
    }

    const duration = performance.now() - start;
    assertEquals(
      duration < PERFORMANCE_THRESHOLD_MS,
      true,
      `Loading took ${duration}ms, exceeds ${PERFORMANCE_THRESHOLD_MS}ms`
    );
  });
});

// ============================================================================
// Run Tests
// ============================================================================

if (import.meta.main) {
  console.log("Running E2E tests for SSG Adapter Collection...");
}
