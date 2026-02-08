// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// server.ts — NoteG Language Server Protocol implementation

import { Lexer, Token, TokenType } from "../lexer.ts";
import { Parser, ProgramNode } from "../parser.ts";

// ============================================================
// LSP TYPES
// ============================================================

interface Position {
  line: number;
  character: number;
}

interface Range {
  start: Position;
  end: Position;
}

interface Diagnostic {
  range: Range;
  message: string;
  severity: number; // 1: Error, 2: Warning, 3: Information, 4: Hint
  source: string;
}

interface CompletionItem {
  label: string;
  kind: number;
  detail?: string;
  documentation?: string;
}

interface TextDocumentIdentifier {
  uri: string;
}

interface TextDocumentItem extends TextDocumentIdentifier {
  languageId: string;
  version: number;
  text: string;
}

// ============================================================
// DOCUMENT STORE
// ============================================================

class DocumentStore {
  private documents: Map<string, TextDocumentItem> = new Map();

  open(doc: TextDocumentItem): void {
    this.documents.set(doc.uri, doc);
  }

  update(uri: string, text: string, version: number): void {
    const doc = this.documents.get(uri);
    if (doc) {
      doc.text = text;
      doc.version = version;
    }
  }

  close(uri: string): void {
    this.documents.delete(uri);
  }

  get(uri: string): TextDocumentItem | undefined {
    return this.documents.get(uri);
  }
}

// ============================================================
// LANGUAGE SERVER
// ============================================================

class NoteGLanguageServer {
  private documents = new DocumentStore();

  // Analyze document and return diagnostics
  analyze(uri: string): Diagnostic[] {
    const doc = this.documents.get(uri);
    if (!doc) return [];

    const diagnostics: Diagnostic[] = [];

    try {
      const lexer = new Lexer(doc.text);
      const tokens = lexer.tokenize();

      // Check for lexer errors
      for (const token of tokens) {
        if (token.type === TokenType.ERROR) {
          diagnostics.push({
            range: {
              start: { line: token.line - 1, character: token.column - 1 },
              end: { line: token.line - 1, character: token.column + token.value.length - 1 },
            },
            message: `Unexpected character: ${token.value}`,
            severity: 1,
            source: "noteg",
          });
        }
      }

      // Try to parse
      const parser = new Parser(tokens);
      parser.parse();
    } catch (error) {
      if (error instanceof Error) {
        const match = error.message.match(/at line (\d+)/);
        const line = match ? parseInt(match[1]) - 1 : 0;

        diagnostics.push({
          range: {
            start: { line, character: 0 },
            end: { line, character: 100 },
          },
          message: error.message,
          severity: 1,
          source: "noteg",
        });
      }
    }

    return diagnostics;
  }

  // Get completions at position
  getCompletions(uri: string, position: Position): CompletionItem[] {
    const completions: CompletionItem[] = [];

    // Keywords
    const keywords = [
      { label: "let", detail: "Variable declaration" },
      { label: "fn", detail: "Function definition" },
      { label: "if", detail: "Conditional statement" },
      { label: "else", detail: "Else branch" },
      { label: "for", detail: "For loop" },
      { label: "while", detail: "While loop" },
      { label: "return", detail: "Return statement" },
      { label: "true", detail: "Boolean true" },
      { label: "false", detail: "Boolean false" },
      { label: "and", detail: "Logical AND" },
      { label: "or", detail: "Logical OR" },
      { label: "not", detail: "Logical NOT" },
    ];

    for (const kw of keywords) {
      completions.push({
        label: kw.label,
        kind: 14, // Keyword
        detail: kw.detail,
      });
    }

    // Built-in functions
    const builtins = [
      { label: "print", detail: "Print to console", doc: "print(value) - Outputs value to console" },
      { label: "len", detail: "Get length", doc: "len(array|string) - Returns the length" },
    ];

    for (const fn of builtins) {
      completions.push({
        label: fn.label,
        kind: 3, // Function
        detail: fn.detail,
        documentation: fn.doc,
      });
    }

    return completions;
  }

  // Get hover information
  getHover(uri: string, position: Position): string | null {
    const doc = this.documents.get(uri);
    if (!doc) return null;

    // Get word at position
    const lines = doc.text.split("\n");
    const line = lines[position.line] || "";
    const word = this.getWordAtPosition(line, position.character);

    // Keyword documentation
    const docs: Record<string, string> = {
      let: "Variable declaration: `let name = value`",
      fn: "Function definition: `fn name(params) { body }`",
      if: "Conditional: `if condition { then } else { else }`",
      for: "For loop: `for item in array { body }`",
      while: "While loop: `while condition { body }`",
      return: "Return from function: `return value`",
      print: "Built-in function: `print(value)` - Output to console",
      len: "Built-in function: `len(array|string)` - Get length",
    };

    return docs[word] || null;
  }

  private getWordAtPosition(line: string, character: number): string {
    let start = character;
    let end = character;

    while (start > 0 && /\w/.test(line[start - 1])) {
      start--;
    }
    while (end < line.length && /\w/.test(line[end])) {
      end++;
    }

    return line.substring(start, end);
  }

  // Document lifecycle
  openDocument(doc: TextDocumentItem): void {
    this.documents.open(doc);
  }

  updateDocument(uri: string, text: string, version: number): void {
    this.documents.update(uri, text, version);
  }

  closeDocument(uri: string): void {
    this.documents.close(uri);
  }
}

// ============================================================
// LSP MESSAGE HANDLING
// ============================================================

interface LSPMessage {
  jsonrpc: "2.0";
  id?: number;
  method?: string;
  params?: unknown;
  result?: unknown;
  error?: { code: number; message: string };
}

class LSPServer {
  private server: NoteGLanguageServer;
  private initialized = false;

  constructor() {
    this.server = new NoteGLanguageServer();
  }

  handleMessage(message: LSPMessage): LSPMessage | null {
    if (message.method) {
      return this.handleRequest(message);
    }
    return null;
  }

  private handleRequest(message: LSPMessage): LSPMessage | null {
    const { id, method, params } = message;

    switch (method) {
      case "initialize":
        this.initialized = true;
        return {
          jsonrpc: "2.0",
          id,
          result: {
            capabilities: {
              textDocumentSync: 1, // Full sync
              completionProvider: { triggerCharacters: ["."] },
              hoverProvider: true,
              diagnosticProvider: { interFileDependencies: false, workspaceDiagnostics: false },
            },
            serverInfo: {
              name: "NoteG Language Server",
              version: "0.2.0",
            },
          },
        };

      case "initialized":
        console.error("NoteG LSP initialized");
        return null;

      case "shutdown":
        return { jsonrpc: "2.0", id, result: null };

      case "exit":
        Deno.exit(0);

      case "textDocument/didOpen":
        const openParams = params as { textDocument: TextDocumentItem };
        this.server.openDocument(openParams.textDocument);
        return null;

      case "textDocument/didChange":
        const changeParams = params as {
          textDocument: { uri: string; version: number };
          contentChanges: { text: string }[];
        };
        if (changeParams.contentChanges.length > 0) {
          this.server.updateDocument(
            changeParams.textDocument.uri,
            changeParams.contentChanges[0].text,
            changeParams.textDocument.version
          );
        }
        return null;

      case "textDocument/didClose":
        const closeParams = params as { textDocument: { uri: string } };
        this.server.closeDocument(closeParams.textDocument.uri);
        return null;

      case "textDocument/completion":
        const completionParams = params as {
          textDocument: { uri: string };
          position: Position;
        };
        return {
          jsonrpc: "2.0",
          id,
          result: this.server.getCompletions(
            completionParams.textDocument.uri,
            completionParams.position
          ),
        };

      case "textDocument/hover":
        const hoverParams = params as {
          textDocument: { uri: string };
          position: Position;
        };
        const hover = this.server.getHover(
          hoverParams.textDocument.uri,
          hoverParams.position
        );
        return {
          jsonrpc: "2.0",
          id,
          result: hover ? { contents: hover } : null,
        };

      case "textDocument/diagnostic":
        const diagParams = params as { textDocument: { uri: string } };
        return {
          jsonrpc: "2.0",
          id,
          result: {
            kind: "full",
            items: this.server.analyze(diagParams.textDocument.uri),
          },
        };

      default:
        console.error(`Unknown method: ${method}`);
        return null;
    }
  }
}

// ============================================================
// STDIO TRANSPORT
// ============================================================

async function runStdio() {
  const server = new LSPServer();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();

  let buffer = "";

  for await (const chunk of Deno.stdin.readable) {
    buffer += decoder.decode(chunk);

    while (true) {
      const headerEnd = buffer.indexOf("\r\n\r\n");
      if (headerEnd === -1) break;

      const header = buffer.substring(0, headerEnd);
      const contentLengthMatch = header.match(/Content-Length: (\d+)/);
      if (!contentLengthMatch) break;

      const contentLength = parseInt(contentLengthMatch[1]);
      const messageStart = headerEnd + 4;
      const messageEnd = messageStart + contentLength;

      if (buffer.length < messageEnd) break;

      const messageStr = buffer.substring(messageStart, messageEnd);
      buffer = buffer.substring(messageEnd);

      try {
        const message = JSON.parse(messageStr) as LSPMessage;
        const response = server.handleMessage(message);

        if (response) {
          const responseStr = JSON.stringify(response);
          const responseHeader = `Content-Length: ${encoder.encode(responseStr).length}\r\n\r\n`;
          await Deno.stdout.write(encoder.encode(responseHeader + responseStr));
        }
      } catch (e) {
        console.error("Error handling message:", e);
      }
    }
  }
}

// ============================================================
// MAIN
// ============================================================

if (import.meta.main) {
  const args = Deno.args;

  if (args.includes("--help") || args.includes("-h")) {
    console.log("NoteG Language Server");
    console.log("");
    console.log("Usage: server.ts [options]");
    console.log("");
    console.log("Options:");
    console.log("  --stdio     Use stdio transport (default)");
    console.log("  --tcp       Use TCP transport");
    console.log("  --port N    TCP port (default: 9999)");
    console.log("  --help      Show this help");
    Deno.exit(0);
  }

  console.error("NoteG Language Server starting...");
  await runStdio();
}
