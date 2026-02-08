// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// mod.js — orbital-ssg main module

/**
 * orbital-ssg - MCP adapters for 28 static site generators
 *
 * @module orbital-ssg
 */

// Re-export all adapters
export * as babashka from "./adapters/babashka.js";
export * as cobalt from "./adapters/cobalt.js";
export * as coleslaw from "./adapters/coleslaw.js";
export * as cryogen from "./adapters/cryogen.js";
export * as documenter from "./adapters/documenter.js";
export * as ema from "./adapters/ema.js";
export * as fornax from "./adapters/fornax.js";
export * as franklin from "./adapters/franklin.js";
export * as frog from "./adapters/frog.js";
export * as hakyll from "./adapters/hakyll.js";
export * as laika from "./adapters/laika.js";
export * as marmot from "./adapters/marmot.js";
export * as mdbook from "./adapters/mdbook.js";
export * as nimblePublisher from "./adapters/nimble-publisher.js";
export * as nimrod from "./adapters/nimrod.js";
export * as orchid from "./adapters/orchid.js";
export * as perun from "./adapters/perun.js";
export * as pollen from "./adapters/pollen.js";
export * as publish from "./adapters/publish.js";
export * as reggae from "./adapters/reggae.js";
export * as scalatex from "./adapters/scalatex.js";
export * as serum from "./adapters/serum.js";
export * as staticwebpages from "./adapters/staticwebpages.js";
export * as tableau from "./adapters/tableau.js";
export * as wub from "./adapters/wub.js";
export * as yocaml from "./adapters/yocaml.js";
export * as zola from "./adapters/zola.js";
export * as zotonic from "./adapters/zotonic.js";

// Package metadata
export const name = "orbital-ssg";
export const version = "0.2.0";
export const description = "MCP adapters for 28 static site generators across 17 languages";

// List all available adapters
export const adapters = [
  "babashka",
  "cobalt",
  "coleslaw",
  "cryogen",
  "documenter",
  "ema",
  "fornax",
  "franklin",
  "frog",
  "hakyll",
  "laika",
  "marmot",
  "mdbook",
  "nimble-publisher",
  "nimrod",
  "orchid",
  "perun",
  "pollen",
  "publish",
  "reggae",
  "scalatex",
  "serum",
  "staticwebpages",
  "tableau",
  "wub",
  "yocaml",
  "zola",
  "zotonic",
];

// Get adapter by name
export async function getAdapter(name) {
  return await import(`./adapters/${name}.js`);
}

// Check all adapter connectivity
export async function checkAllAdapters() {
  const results = {};
  for (const name of adapters) {
    try {
      const adapter = await getAdapter(name);
      results[name] = await adapter.connect();
    } catch {
      results[name] = false;
    }
  }
  return results;
}
