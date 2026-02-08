// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// validate.ts — Accessibility schema validation

const SCHEMAS = {
  main: "schema.json",
  bsl: "bsl.schema.json",
  asl: "asl.schema.json",
  gsl: "gsl.schema.json",
  makaton: "makaton.schema.json",
};

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

async function loadSchema(path: string): Promise<Record<string, unknown>> {
  const content = await Deno.readTextFile(path);
  return JSON.parse(content);
}

function validateA11yMetadata(
  data: Record<string, unknown>,
  _schema: Record<string, unknown>
): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Check for sign language content
  if (data.signLanguages && Array.isArray(data.signLanguages)) {
    for (const sl of data.signLanguages) {
      if (!sl.language) {
        errors.push("Sign language entry missing 'language' field");
      }
      if (!sl.url && !sl.transcript) {
        warnings.push(
          `Sign language ${sl.language}: Consider adding video URL or transcript`
        );
      }
    }
  }

  // Check alt text
  if (data.altText) {
    const alt = data.altText as Record<string, string>;
    if (alt.short && alt.short.length > 125) {
      errors.push("Short alt text exceeds 125 character limit");
    }
    if (!alt.short && !alt.long) {
      warnings.push("Alt text object has no content");
    }
  }

  // Check audio description
  if (data.audioDescription) {
    const ad = data.audioDescription as Record<string, string>;
    if (!ad.url && !ad.transcript) {
      warnings.push("Audio description has no URL or transcript");
    }
  }

  // Check captions
  if (data.captions) {
    const captions = data.captions as Record<string, string>;
    if (!captions.url) {
      errors.push("Captions object missing URL");
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

async function main() {
  console.log("Validating accessibility schemas...\n");

  const schemaDir = new URL(".", import.meta.url).pathname;
  let allValid = true;

  for (const [name, file] of Object.entries(SCHEMAS)) {
    const path = `${schemaDir}${file}`;
    try {
      const schema = await loadSchema(path);
      console.log(`✓ ${name}: Schema is valid JSON`);

      // Check required schema fields
      if (!schema.$schema) {
        console.log(`  ⚠ Missing $schema field`);
      }
      if (!schema.$id) {
        console.log(`  ⚠ Missing $id field`);
      }
      if (!schema.title) {
        console.log(`  ⚠ Missing title field`);
      }
    } catch (error) {
      console.log(`✗ ${name}: ${error}`);
      allValid = false;
    }
  }

  console.log("\n" + (allValid ? "All schemas valid!" : "Some schemas have issues"));
  Deno.exit(allValid ? 0 : 1);
}

if (import.meta.main) {
  main();
}

export { validateA11yMetadata, ValidationResult };
