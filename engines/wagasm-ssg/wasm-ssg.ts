// wasm-ssg.ts - AssemblyScript/WebAssembly static site generator
//
// "WASM-SSG" - Portable, fast site generation
//
// AssemblyScript compiles TypeScript-like code to WebAssembly.
// Runs anywhere WASI is supported: wasmtime, wasmer, browser.

// ============================================================================
// Types
// ============================================================================

class Frontmatter {
  title: string = "";
  date: string = "";
  tags: string[] = [];
  draft: bool = false;
  template: string = "default";
}

class ParserState {
  html: string = "";
  inPara: bool = false;
  inCode: bool = false;
  inList: bool = false;
}

// ============================================================================
// String Utilities
// ============================================================================

function startsWith(str: string, prefix: string): bool {
  if (str.length < prefix.length) return false;
  return str.substring(0, prefix.length) == prefix;
}

function trim(str: string): string {
  let start = 0;
  let end = str.length;

  while (start < end) {
    const c = str.charCodeAt(start);
    if (c != 32 && c != 9 && c != 10 && c != 13) break; // space, tab, \n, \r
    start++;
  }

  while (end > start) {
    const c = str.charCodeAt(end - 1);
    if (c != 32 && c != 9 && c != 10 && c != 13) break;
    end--;
  }

  return str.substring(start, end);
}

function stripPrefix(str: string, prefix: string): string {
  if (startsWith(str, prefix)) {
    return str.substring(prefix.length);
  }
  return str;
}

function escapeHtml(str: string): string {
  let result = "";
  for (let i = 0; i < str.length; i++) {
    const c = str.charAt(i);
    if (c == "<") result += "&lt;";
    else if (c == ">") result += "&gt;";
    else if (c == "&") result += "&amp;";
    else if (c == '"') result += "&quot;";
    else result += c;
  }
  return result;
}

function splitLines(str: string): string[] {
  const result: string[] = [];
  let start = 0;
  for (let i = 0; i < str.length; i++) {
    if (str.charCodeAt(i) == 10) { // \n
      result.push(str.substring(start, i));
      start = i + 1;
    }
  }
  if (start < str.length) {
    result.push(str.substring(start));
  }
  return result;
}

// ============================================================================
// Frontmatter Parser
// ============================================================================

function parseFmLine(line: string, fm: Frontmatter): void {
  const colonIdx = line.indexOf(":");
  if (colonIdx < 0) return;

  const key = trim(line.substring(0, colonIdx));
  const value = trim(line.substring(colonIdx + 1));

  if (key == "title") fm.title = value;
  else if (key == "date") fm.date = value;
  else if (key == "template") fm.template = value;
  else if (key == "draft") fm.draft = value == "true" || value == "yes";
}

function parseFrontmatter(content: string): Frontmatter {
  const lines = splitLines(content);
  const fm = new Frontmatter();

  if (lines.length == 0 || trim(lines[0]) != "---") {
    return fm;
  }

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    if (trim(line) == "---") {
      break;
    }
    parseFmLine(line, fm);
  }

  return fm;
}

function getFrontmatterBody(content: string): string {
  const lines = splitLines(content);

  if (lines.length == 0 || trim(lines[0]) != "---") {
    return content;
  }

  for (let i = 1; i < lines.length; i++) {
    if (trim(lines[i]) == "---") {
      const bodyLines: string[] = [];
      for (let j = i + 1; j < lines.length; j++) {
        bodyLines.push(lines[j]);
      }
      return bodyLines.join("\n");
    }
  }

  return "";
}

// ============================================================================
// Markdown Parser
// ============================================================================

function processLine(line: string, state: ParserState): void {
  const tr = trim(line);

  // Code fence
  if (startsWith(tr, "```")) {
    if (state.inCode) {
      state.html += "</code></pre>\n";
      state.inCode = false;
    } else {
      if (state.inPara) {
        state.html += "</p>\n";
        state.inPara = false;
      }
      if (state.inList) {
        state.html += "</ul>\n";
        state.inList = false;
      }
      state.html += "<pre><code>";
      state.inCode = true;
    }
    return;
  }

  // Inside code block
  if (state.inCode) {
    state.html += escapeHtml(line) + "\n";
    return;
  }

  // Empty line
  if (tr.length == 0) {
    if (state.inPara) {
      state.html += "</p>\n";
      state.inPara = false;
    }
    if (state.inList) {
      state.html += "</ul>\n";
      state.inList = false;
    }
    return;
  }

  // Headers
  if (startsWith(tr, "### ")) {
    if (state.inPara) { state.html += "</p>\n"; state.inPara = false; }
    if (state.inList) { state.html += "</ul>\n"; state.inList = false; }
    state.html += "<h3>" + trim(stripPrefix(tr, "### ")) + "</h3>\n";
    return;
  }
  if (startsWith(tr, "## ")) {
    if (state.inPara) { state.html += "</p>\n"; state.inPara = false; }
    if (state.inList) { state.html += "</ul>\n"; state.inList = false; }
    state.html += "<h2>" + trim(stripPrefix(tr, "## ")) + "</h2>\n";
    return;
  }
  if (startsWith(tr, "# ")) {
    if (state.inPara) { state.html += "</p>\n"; state.inPara = false; }
    if (state.inList) { state.html += "</ul>\n"; state.inList = false; }
    state.html += "<h1>" + trim(stripPrefix(tr, "# ")) + "</h1>\n";
    return;
  }

  // List items
  if (startsWith(tr, "- ") || startsWith(tr, "* ")) {
    if (state.inPara) {
      state.html += "</p>\n";
      state.inPara = false;
    }
    if (!state.inList) {
      state.html += "<ul>\n";
      state.inList = true;
    }
    state.html += "<li>" + trim(tr.substring(2)) + "</li>\n";
    return;
  }

  // Paragraph
  if (!state.inPara) {
    state.html += "<p>";
    state.inPara = true;
  } else {
    state.html += " ";
  }
  state.html += tr;
}

function parseMarkdown(content: string): string {
  const state = new ParserState();
  const lines = splitLines(content);

  for (let i = 0; i < lines.length; i++) {
    processLine(lines[i], state);
  }

  if (state.inPara) state.html += "</p>\n";
  if (state.inList) state.html += "</ul>\n";
  if (state.inCode) state.html += "</code></pre>\n";

  return state.html;
}

// ============================================================================
// Template Engine
// ============================================================================

const TEMPLATE: string = `<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>{{title}}</title>
<style>body{font-family:system-ui;max-width:800px;margin:0 auto;padding:2rem}pre{background:#f4f4f4;padding:1rem}</style>
</head><body><article><h1>{{title}}</h1><time>{{date}}</time>
{{content}}
</article></body></html>`;

function replaceAll(str: string, search: string, replace: string): string {
  let result = "";
  let i = 0;
  while (i < str.length) {
    if (i + search.length <= str.length && str.substring(i, i + search.length) == search) {
      result += replace;
      i += search.length;
    } else {
      result += str.charAt(i);
      i++;
    }
  }
  return result;
}

function applyTemplate(fm: Frontmatter, html: string): string {
  let result = TEMPLATE;
  result = replaceAll(result, "{{title}}", fm.title);
  result = replaceAll(result, "{{date}}", fm.date);
  result = replaceAll(result, "{{content}}", html);
  return result;
}

// ============================================================================
// Exports for WASI
// ============================================================================

export function testMarkdown(): void {
  console.log("=== Test: Markdown ===");
  const md = `# Hello World

This is a test.

- Item 1
- Item 2

\`\`\`
code block
\`\`\`
`;
  console.log(parseMarkdown(md));
}

export function testFrontmatter(): void {
  console.log("=== Test: Frontmatter ===");
  const content = `---
title: My Post
date: 2024-01-15
draft: false
---

Content here
`;
  const fm = parseFrontmatter(content);
  console.log("Title: " + fm.title);
  console.log("Date: " + fm.date);
  console.log("Draft: " + (fm.draft ? "true" : "false"));
}

export function testFull(): void {
  console.log("=== Test: Full Pipeline ===");
  const content = `---
title: Welcome
date: 2024-01-15
---

# Welcome

This is WASM-SSG, a WebAssembly SSG.

- Portable
- Fast
- Universal
`;
  const fm = parseFrontmatter(content);
  const body = getFrontmatterBody(content);
  const html = parseMarkdown(body);
  const output = applyTemplate(fm, html);
  console.log(output);
}

// Main entry point
console.log("WASM-SSG - WebAssembly powered");
console.log("Compile with: asc wasm-ssg.ts -o wasm-ssg.wasm");
console.log("Run with: wasmtime wasm-ssg.wasm");
testFull();
