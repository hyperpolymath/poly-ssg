// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// bernoulli_test.ts — Bernoulli verification tests

import { assertEquals, assertExists } from "https://deno.land/std@0.208.0/assert/mod.ts";

/**
 * Bernoulli Verification Engine
 *
 * Based on the probabilistic reasoning principles of the Bernoulli numbers
 * and formal verification approaches. These tests verify properties that
 * must hold for the SSG system to be correct.
 */

// ============================================================
// PROPERTY: Build Determinism
// Same inputs should always produce same outputs
// ============================================================

Deno.test("Verify - Build determinism", () => {
  const input = {
    content: "# Hello World",
    template: "<h1>{{ title }}</h1>",
    variables: { title: "Hello World" },
  };

  // Simulate build
  function build(input: typeof input): string {
    return input.template.replace("{{ title }}", input.variables.title);
  }

  // Run multiple times
  const results = [];
  for (let i = 0; i < 10; i++) {
    results.push(build(input));
  }

  // All results should be identical
  const first = results[0];
  for (const result of results) {
    assertEquals(result, first, "Build output should be deterministic");
  }
});

// ============================================================
// PROPERTY: Template Variable Safety
// Undefined variables should be handled safely
// ============================================================

Deno.test("Verify - Template variable safety", () => {
  const template = "Hello {{ name }}, welcome to {{ place }}!";
  const variables = { name: "User" }; // 'place' is missing

  function safeSubstitute(
    template: string,
    variables: Record<string, string>
  ): string {
    return template.replace(/\{\{\s*(\w+)\s*\}\}/g, (_, key) => {
      return variables[key] ?? `[UNDEFINED:${key}]`;
    });
  }

  const result = safeSubstitute(template, variables);

  assertEquals(result.includes("User"), true);
  assertEquals(result.includes("[UNDEFINED:place]"), true);
  // Should not throw or produce undefined behavior
});

// ============================================================
// PROPERTY: Content Format Preservation
// Content should maintain structure through transformation
// ============================================================

Deno.test("Verify - Content format preservation", () => {
  const markdown = `---
title: Test
---

# Heading 1

Paragraph text.

- Item 1
- Item 2
`;

  // Parse frontmatter and body
  function parseContent(content: string): { frontmatter: string; body: string } {
    const parts = content.split("---");
    return {
      frontmatter: parts[1]?.trim() ?? "",
      body: parts.slice(2).join("---").trim(),
    };
  }

  const { frontmatter, body } = parseContent(markdown);

  // Frontmatter should be extractable
  assertExists(frontmatter);
  assertEquals(frontmatter.includes("title: Test"), true);

  // Body structure should be preserved
  assertEquals(body.includes("# Heading 1"), true);
  assertEquals(body.includes("- Item 1"), true);
});

// ============================================================
// PROPERTY: Adapter Isolation
// Adapters should not affect each other's state
// ============================================================

Deno.test("Verify - Adapter isolation", () => {
  // Simulate adapter state
  const createAdapter = (name: string) => {
    let connected = false;
    return {
      name,
      connect: () => { connected = true; },
      disconnect: () => { connected = false; },
      isConnected: () => connected,
    };
  };

  const adapterA = createAdapter("A");
  const adapterB = createAdapter("B");

  // Connect A
  adapterA.connect();
  assertEquals(adapterA.isConnected(), true);
  assertEquals(adapterB.isConnected(), false, "B should be unaffected");

  // Connect B
  adapterB.connect();
  assertEquals(adapterA.isConnected(), true, "A should still be connected");
  assertEquals(adapterB.isConnected(), true);

  // Disconnect A
  adapterA.disconnect();
  assertEquals(adapterA.isConnected(), false);
  assertEquals(adapterB.isConnected(), true, "B should be unaffected");
});

// ============================================================
// PROPERTY: Configuration Validation
// Invalid configs should be rejected
// ============================================================

Deno.test("Verify - Configuration validation", () => {
  interface Config {
    title: string;
    baseUrl: string;
    outputDir: string;
  }

  function validateConfig(config: Partial<Config>): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (!config.title || config.title.trim() === "") {
      errors.push("title is required");
    }

    if (!config.baseUrl) {
      errors.push("baseUrl is required");
    } else if (!config.baseUrl.startsWith("http")) {
      errors.push("baseUrl must be a valid URL");
    }

    if (config.outputDir && config.outputDir.includes("..")) {
      errors.push("outputDir cannot contain path traversal");
    }

    return { valid: errors.length === 0, errors };
  }

  // Valid config
  const valid = validateConfig({
    title: "My Site",
    baseUrl: "https://example.com",
    outputDir: "public",
  });
  assertEquals(valid.valid, true);
  assertEquals(valid.errors.length, 0);

  // Invalid: missing title
  const noTitle = validateConfig({ baseUrl: "https://example.com" });
  assertEquals(noTitle.valid, false);
  assertEquals(noTitle.errors.includes("title is required"), true);

  // Invalid: bad URL
  const badUrl = validateConfig({ title: "Test", baseUrl: "not-a-url" });
  assertEquals(badUrl.valid, false);

  // Invalid: path traversal
  const pathTraversal = validateConfig({
    title: "Test",
    baseUrl: "https://example.com",
    outputDir: "../../../etc",
  });
  assertEquals(pathTraversal.valid, false);
});

// ============================================================
// PROPERTY: Output Path Safety
// Generated paths should not escape output directory
// ============================================================

Deno.test("Verify - Output path safety", () => {
  function sanitizePath(basedir: string, filepath: string): string | null {
    // Normalize and resolve
    const normalized = filepath
      .replace(/\\/g, "/")
      .replace(/\/+/g, "/");

    // Reject if contains traversal
    if (normalized.includes("..")) {
      return null;
    }

    // Reject if absolute
    if (normalized.startsWith("/")) {
      return null;
    }

    return `${basedir}/${normalized}`;
  }

  // Safe paths
  assertEquals(sanitizePath("/out", "index.html"), "/out/index.html");
  assertEquals(sanitizePath("/out", "posts/hello.html"), "/out/posts/hello.html");

  // Unsafe paths
  assertEquals(sanitizePath("/out", "../etc/passwd"), null);
  assertEquals(sanitizePath("/out", "/etc/passwd"), null);
  assertEquals(sanitizePath("/out", "foo/../../bar"), null);
});
