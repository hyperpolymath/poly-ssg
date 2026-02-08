// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// lexer.ts — NoteG language lexer

// ============================================================
// TOKEN TYPES
// ============================================================

export enum TokenType {
  // Literals
  STRING = "STRING",
  NUMBER = "NUMBER",
  BOOLEAN = "BOOLEAN",
  IDENTIFIER = "IDENTIFIER",

  // Keywords
  LET = "LET",
  IF = "IF",
  ELSE = "ELSE",
  FOR = "FOR",
  WHILE = "WHILE",
  FN = "FN",
  RETURN = "RETURN",
  TRUE = "TRUE",
  FALSE = "FALSE",

  // Operators
  PLUS = "PLUS",
  MINUS = "MINUS",
  STAR = "STAR",
  SLASH = "SLASH",
  PERCENT = "PERCENT",
  EQ = "EQ",
  NEQ = "NEQ",
  LT = "LT",
  GT = "GT",
  LTE = "LTE",
  GTE = "GTE",
  AND = "AND",
  OR = "OR",
  NOT = "NOT",
  ASSIGN = "ASSIGN",

  // Delimiters
  LPAREN = "LPAREN",
  RPAREN = "RPAREN",
  LBRACE = "LBRACE",
  RBRACE = "RBRACE",
  LBRACKET = "LBRACKET",
  RBRACKET = "RBRACKET",
  COMMA = "COMMA",
  DOT = "DOT",
  COLON = "COLON",
  SEMICOLON = "SEMICOLON",
  ARROW = "ARROW",

  // Template syntax
  TEMPLATE_START = "TEMPLATE_START", // {{
  TEMPLATE_END = "TEMPLATE_END", // }}

  // Special
  NEWLINE = "NEWLINE",
  EOF = "EOF",
  ERROR = "ERROR",
}

export interface Token {
  type: TokenType;
  value: string;
  line: number;
  column: number;
}

// ============================================================
// LEXER
// ============================================================

export class Lexer {
  private source: string;
  private pos: number = 0;
  private line: number = 1;
  private column: number = 1;

  private static keywords: Map<string, TokenType> = new Map([
    ["let", TokenType.LET],
    ["if", TokenType.IF],
    ["else", TokenType.ELSE],
    ["for", TokenType.FOR],
    ["while", TokenType.WHILE],
    ["fn", TokenType.FN],
    ["return", TokenType.RETURN],
    ["true", TokenType.TRUE],
    ["false", TokenType.FALSE],
    ["and", TokenType.AND],
    ["or", TokenType.OR],
    ["not", TokenType.NOT],
  ]);

  constructor(source: string) {
    this.source = source;
  }

  tokenize(): Token[] {
    const tokens: Token[] = [];

    while (!this.isAtEnd()) {
      const token = this.nextToken();
      if (token.type !== TokenType.NEWLINE) {
        tokens.push(token);
      }
    }

    tokens.push(this.makeToken(TokenType.EOF, ""));
    return tokens;
  }

  private nextToken(): Token {
    this.skipWhitespace();

    if (this.isAtEnd()) {
      return this.makeToken(TokenType.EOF, "");
    }

    const char = this.advance();

    // Template syntax
    if (char === "{" && this.peek() === "{") {
      this.advance();
      return this.makeToken(TokenType.TEMPLATE_START, "{{");
    }

    if (char === "}" && this.peek() === "}") {
      this.advance();
      return this.makeToken(TokenType.TEMPLATE_END, "}}");
    }

    // Single character tokens
    switch (char) {
      case "(": return this.makeToken(TokenType.LPAREN, char);
      case ")": return this.makeToken(TokenType.RPAREN, char);
      case "{": return this.makeToken(TokenType.LBRACE, char);
      case "}": return this.makeToken(TokenType.RBRACE, char);
      case "[": return this.makeToken(TokenType.LBRACKET, char);
      case "]": return this.makeToken(TokenType.RBRACKET, char);
      case ",": return this.makeToken(TokenType.COMMA, char);
      case ".": return this.makeToken(TokenType.DOT, char);
      case ":": return this.makeToken(TokenType.COLON, char);
      case ";": return this.makeToken(TokenType.SEMICOLON, char);
      case "+": return this.makeToken(TokenType.PLUS, char);
      case "-":
        if (this.peek() === ">") {
          this.advance();
          return this.makeToken(TokenType.ARROW, "->");
        }
        return this.makeToken(TokenType.MINUS, char);
      case "*": return this.makeToken(TokenType.STAR, char);
      case "/":
        if (this.peek() === "/") {
          this.skipLineComment();
          return this.nextToken();
        }
        return this.makeToken(TokenType.SLASH, char);
      case "%": return this.makeToken(TokenType.PERCENT, char);
      case "=":
        if (this.peek() === "=") {
          this.advance();
          return this.makeToken(TokenType.EQ, "==");
        }
        return this.makeToken(TokenType.ASSIGN, char);
      case "!":
        if (this.peek() === "=") {
          this.advance();
          return this.makeToken(TokenType.NEQ, "!=");
        }
        return this.makeToken(TokenType.NOT, char);
      case "<":
        if (this.peek() === "=") {
          this.advance();
          return this.makeToken(TokenType.LTE, "<=");
        }
        return this.makeToken(TokenType.LT, char);
      case ">":
        if (this.peek() === "=") {
          this.advance();
          return this.makeToken(TokenType.GTE, ">=");
        }
        return this.makeToken(TokenType.GT, char);
      case "\n":
        this.line++;
        this.column = 1;
        return this.makeToken(TokenType.NEWLINE, char);
      case '"':
      case "'":
        return this.string(char);
    }

    // Numbers
    if (this.isDigit(char)) {
      return this.number(char);
    }

    // Identifiers and keywords
    if (this.isAlpha(char)) {
      return this.identifier(char);
    }

    return this.makeToken(TokenType.ERROR, char);
  }

  private string(quote: string): Token {
    let value = "";
    while (!this.isAtEnd() && this.peek() !== quote) {
      if (this.peek() === "\n") {
        this.line++;
        this.column = 1;
      }
      if (this.peek() === "\\" && this.peekNext() === quote) {
        this.advance();
      }
      value += this.advance();
    }

    if (this.isAtEnd()) {
      return this.makeToken(TokenType.ERROR, "Unterminated string");
    }

    this.advance(); // closing quote
    return this.makeToken(TokenType.STRING, value);
  }

  private number(first: string): Token {
    let value = first;
    while (this.isDigit(this.peek())) {
      value += this.advance();
    }

    if (this.peek() === "." && this.isDigit(this.peekNext())) {
      value += this.advance(); // .
      while (this.isDigit(this.peek())) {
        value += this.advance();
      }
    }

    return this.makeToken(TokenType.NUMBER, value);
  }

  private identifier(first: string): Token {
    let value = first;
    while (this.isAlphaNumeric(this.peek())) {
      value += this.advance();
    }

    const type = Lexer.keywords.get(value) ?? TokenType.IDENTIFIER;
    return this.makeToken(type, value);
  }

  private skipWhitespace(): void {
    while (!this.isAtEnd()) {
      const char = this.peek();
      if (char === " " || char === "\t" || char === "\r") {
        this.advance();
      } else {
        break;
      }
    }
  }

  private skipLineComment(): void {
    while (!this.isAtEnd() && this.peek() !== "\n") {
      this.advance();
    }
  }

  private peek(): string {
    return this.source[this.pos] ?? "\0";
  }

  private peekNext(): string {
    return this.source[this.pos + 1] ?? "\0";
  }

  private advance(): string {
    const char = this.source[this.pos];
    this.pos++;
    this.column++;
    return char;
  }

  private isAtEnd(): boolean {
    return this.pos >= this.source.length;
  }

  private isDigit(char: string): boolean {
    return char >= "0" && char <= "9";
  }

  private isAlpha(char: string): boolean {
    return (char >= "a" && char <= "z") ||
           (char >= "A" && char <= "Z") ||
           char === "_";
  }

  private isAlphaNumeric(char: string): boolean {
    return this.isAlpha(char) || this.isDigit(char);
  }

  private makeToken(type: TokenType, value: string): Token {
    return {
      type,
      value,
      line: this.line,
      column: this.column - value.length,
    };
  }
}

// ============================================================
// CLI ENTRY POINT
// ============================================================

if (import.meta.main) {
  const file = Deno.args[0];
  if (!file) {
    console.error("Usage: lexer.ts <file>");
    Deno.exit(1);
  }

  const source = await Deno.readTextFile(file);
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  console.log(JSON.stringify(tokens, null, 2));
}
