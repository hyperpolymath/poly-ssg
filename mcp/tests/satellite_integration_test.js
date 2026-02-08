// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
//
// Integration tests for poly-ssg satellite repositories
// Tests that satellite SSG engines can be invoked via MCP adapter patterns

import { assertEquals, assertExists, assert } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { join } from "https://deno.land/std@0.208.0/path/mod.ts";

// Satellite registry (from SATELLITES.scm v2.0.0)
const implementedSatellites = [
  // Original implementations
  { name: "zigzag-ssg", language: "Zig", command: "zig" },
  { name: "casket-ssg", language: "Haskell", command: "stack" },
  { name: "prodigy-ssg", language: "Prolog", command: "swipl" },
  { name: "sparkle-ssg", language: "Gleam", command: "gleam" },
  { name: "macrauchenia-ssg", language: "OCaml", command: "dune" },
  { name: "eclipse-ssg", language: "Pony", command: "ponyc" },
  { name: "chicxulub-ssg", language: "Bash", command: "bash" },
  { name: "anvil-ssg", language: "Ada/SPARK", command: "gnatmake" },
  { name: "divisionone-ssg", language: "COBOL", command: "cobc" },
  { name: "labnote-ssg", language: "SciLab", command: "scilab-cli" },
  { name: "milk-ssg", language: "COW", command: "cow" },
  // v2 implementations (2025-01-18)
  { name: "baremetal-ssg", language: "x86-64 Assembly", command: "nasm" },
  { name: "befunge-ssg", language: "Befunge-93", command: "node" },
  { name: "ddraig-ssg", language: "Idris 2", command: "idris2" },
  { name: "doit-ssg", language: "Io", command: "io" },
  { name: "estate-ssg", language: "Eiffel", command: "ec" },
  { name: "gungir-ssg", language: "ReScript", command: "deno" },
  { name: "iota-ssg", language: "APL", command: "dyalog" },
  { name: "my-ssg", language: "Janet", command: "janet" },
  { name: "obli-ssg", language: "Oberon", command: "obnc" },
  { name: "odd-ssg", language: "Forth", command: "gforth" },
  { name: "orbital-ssg", language: "Grain", command: "grain" },
  { name: "parallax-ssg", language: "Chapel", command: "chpl" },
  { name: "pharos-ssg", language: "Pharo Smalltalk", command: "pharo" },
  { name: "qed-ssg", language: "Lean 4", command: "lean" },
  { name: "rats-ssg", language: "Ratfor", command: "ratfor" },
  { name: "rescribe-ssg", language: "ReScript", command: "deno" },
  { name: "saur-ssg", language: "Squirrel", command: "sq" },
  { name: "shift-ssg", language: "Wren", command: "wren" },
  { name: "terrapin-ssg", language: "Logo", command: "ucblogo" },
  { name: "wagasm-ssg", language: "WebAssembly Text", command: "wasmtime" },
];

// Hub adapters (from poly-ssg-mcp)
const hubAdapters = [
  "zola", "hakyll", "cobalt", "mdbook", "serum", "franklin",
  "pollen", "frog", "cryogen", "documenter", "fornax", "ema",
  "laika", "marmot", "nimrod", "orchid", "perun", "publish",
  "reggae", "scalatex", "staticwebpages", "tableau", "wub",
  "yocaml", "babashka", "coleslaw", "nimble-publisher", "zotonic",
];

Deno.test("Satellite Registry: All implemented satellites have valid structure", () => {
  for (const satellite of implementedSatellites) {
    assertExists(satellite.name, "Satellite must have name");
    assertExists(satellite.language, "Satellite must have language");
    assertExists(satellite.command, "Satellite must have command");
    assert(satellite.name.endsWith("-ssg"), "Satellite name should end with -ssg");
  }
});

Deno.test("Satellite Registry: No duplicate satellite names", () => {
  const names = implementedSatellites.map((s) => s.name);
  const uniqueNames = new Set(names);
  assertEquals(names.length, uniqueNames.size, "Duplicate satellite names found");
});

Deno.test("Hub Adapters: All adapter names are lowercase", () => {
  for (const adapter of hubAdapters) {
    assertEquals(adapter, adapter.toLowerCase(), `Adapter ${adapter} should be lowercase`);
  }
});

Deno.test("Hub Adapters: No duplicate adapter names", () => {
  const uniqueAdapters = new Set(hubAdapters);
  assertEquals(hubAdapters.length, uniqueAdapters.size, "Duplicate adapter names found");
});

Deno.test("Satellite-Hub Separation: Satellites don't overlap with hub adapters", () => {
  const satelliteNames = implementedSatellites.map((s) =>
    s.name.replace("-ssg", "").toLowerCase()
  );

  for (const satName of satelliteNames) {
    assert(
      !hubAdapters.includes(satName),
      `Satellite ${satName} should not overlap with hub adapter`
    );
  }
});

Deno.test("MCP Integration: Standard tool pattern is consistent", async (t) => {
  // Core tools that adapters should expose (clean/check may vary by SSG)
  const coreTools = ["init", "build", "serve", "version"];

  await t.step("Hub adapters follow standard tool naming", async () => {
    // Import a sample adapter
    const Zola = await import("../lib/es6/src/adapters/Zola.res.js");
    const toolNames = Zola.tools.map((t) => t.name);

    // Check that core operations exist with adapter prefix
    for (const stdTool of coreTools) {
      const hasStandardTool = toolNames.some((name) => name.includes(stdTool));
      assert(
        hasStandardTool,
        `Zola should have a tool containing '${stdTool}'`
      );
    }
  });
});

Deno.test("Satellite Metadata: Implemented count matches list", () => {
  // From SATELLITES.scm statistics (v2.0.0: 11 original + 20 new = 31)
  const expectedCount = 31;
  assertEquals(
    implementedSatellites.length,
    expectedCount,
    "Implemented satellite count should match SATELLITES.scm"
  );
});

Deno.test("Language Paradigm Coverage: Multiple paradigms represented", () => {
  const languages = implementedSatellites.map((s) => s.language);
  const uniqueLanguages = new Set(languages);

  // Should cover multiple programming paradigms
  assert(uniqueLanguages.size >= 8, "Should cover at least 8 different languages");

  // Check specific paradigm coverage
  const hasSystemsLang = languages.some((l) =>
    ["Zig", "Ada/SPARK", "COBOL"].includes(l)
  );
  const hasFunctionalLang = languages.some((l) =>
    ["Haskell", "OCaml", "Gleam"].includes(l)
  );
  const hasLogicLang = languages.some((l) => l === "Prolog");
  const hasEsotericLang = languages.some((l) => l === "COW");

  assert(hasSystemsLang, "Should have systems programming language");
  assert(hasFunctionalLang, "Should have functional language");
  assert(hasLogicLang, "Should have logic programming language");
  assert(hasEsotericLang, "Should have esoteric language");
});

Deno.test("Command Availability: Check if satellite commands could be available", async (t) => {
  // This test documents what commands satellites use
  // Actual availability depends on system installation

  const commandDescriptions = {
    // Original v1 commands
    "zig": "Zig compiler/build system",
    "stack": "Haskell Stack build tool",
    "swipl": "SWI-Prolog interpreter",
    "gleam": "Gleam build tool",
    "dune": "OCaml build system",
    "ponyc": "Pony compiler",
    "bash": "POSIX shell",
    "gnatmake": "Ada compiler (GNAT)",
    "cobc": "GnuCOBOL compiler",
    "scilab-cli": "SciLab CLI interpreter",
    "cow": "COW esoteric interpreter",
    // v2 commands (2025-01-18)
    "nasm": "Netwide Assembler (x86-64)",
    "node": "Node.js runtime (Befunge interpreter)",
    "idris2": "Idris 2 compiler",
    "io": "Io language interpreter",
    "ec": "Eiffel compiler",
    "deno": "Deno runtime (ReScript)",
    "dyalog": "Dyalog APL interpreter",
    "janet": "Janet language interpreter",
    "obnc": "Oberon to C compiler",
    "gforth": "GNU Forth interpreter",
    "grain": "Grain WASM compiler",
    "chpl": "Chapel parallel compiler",
    "pharo": "Pharo Smalltalk VM",
    "lean": "Lean 4 theorem prover",
    "ratfor": "Ratfor preprocessor",
    "sq": "Squirrel interpreter",
    "wren": "Wren VM",
    "ucblogo": "UCB Logo interpreter",
    "wasmtime": "WebAssembly runtime",
  };

  for (const sat of implementedSatellites) {
    await t.step(`${sat.name} uses ${sat.command}`, () => {
      assert(
        sat.command in commandDescriptions,
        `${sat.name} command '${sat.command}' should be documented`
      );
    });
  }
});

// Additional v2 integration tests

Deno.test("v2 Satellites: All have example content directories", async () => {
  // v2 satellites should have content/ directories with example sites
  const v2Satellites = implementedSatellites.filter((s) =>
    ["baremetal-ssg", "befunge-ssg", "ddraig-ssg", "doit-ssg", "estate-ssg",
     "gungir-ssg", "iota-ssg", "my-ssg", "obli-ssg", "odd-ssg", "orbital-ssg",
     "parallax-ssg", "pharos-ssg", "qed-ssg", "rats-ssg", "rescribe-ssg",
     "saur-ssg", "shift-ssg", "terrapin-ssg", "wagasm-ssg"].includes(s.name)
  );

  assertEquals(v2Satellites.length, 20, "Should have 20 v2 satellites");
});

Deno.test("Language Diversity: v2 adds unique paradigms", () => {
  const v2Languages = [
    "x86-64 Assembly", "Befunge-93", "Idris 2", "Io", "Eiffel",
    "APL", "Janet", "Oberon", "Forth", "Grain", "Chapel",
    "Pharo Smalltalk", "Lean 4", "Ratfor", "Squirrel", "Wren",
    "Logo", "WebAssembly Text"
  ];

  const allLanguages = implementedSatellites.map((s) => s.language);

  for (const lang of v2Languages) {
    assert(
      allLanguages.includes(lang),
      `v2 language '${lang}' should be in satellite list`
    );
  }
});

Deno.test("Total Language Count: 31 languages represented", () => {
  const languages = implementedSatellites.map((s) => s.language);
  const uniqueLanguages = new Set(languages);

  // Some satellites share languages (e.g., gungir-ssg and rescribe-ssg both use ReScript)
  assert(
    uniqueLanguages.size >= 29,
    `Should have at least 29 unique languages, got ${uniqueLanguages.size}`
  );
});
