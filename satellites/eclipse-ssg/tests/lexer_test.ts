// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// lexer_test.ts — Unit tests for NoteG lexer

import { assertEquals, assertArrayIncludes } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { Lexer, TokenType } from "../noteg-lang/src/lexer.ts";

Deno.test("Lexer - tokenizes keywords", () => {
  const source = "let fn if else for while return true false";
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  const types = tokens.map(t => t.type);
  assertArrayIncludes(types, [
    TokenType.LET,
    TokenType.FN,
    TokenType.IF,
    TokenType.ELSE,
    TokenType.FOR,
    TokenType.WHILE,
    TokenType.RETURN,
    TokenType.TRUE,
    TokenType.FALSE,
  ]);
});

Deno.test("Lexer - tokenizes numbers", () => {
  const source = "42 3.14 0 100";
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  const numbers = tokens.filter(t => t.type === TokenType.NUMBER);
  assertEquals(numbers.length, 4);
  assertEquals(numbers[0].value, "42");
  assertEquals(numbers[1].value, "3.14");
});

Deno.test("Lexer - tokenizes strings", () => {
  const source = '"hello" \'world\'';
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  const strings = tokens.filter(t => t.type === TokenType.STRING);
  assertEquals(strings.length, 2);
  assertEquals(strings[0].value, "hello");
  assertEquals(strings[1].value, "world");
});

Deno.test("Lexer - tokenizes operators", () => {
  const source = "+ - * / % == != < > <= >= =";
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  const types = tokens.filter(t => t.type !== TokenType.EOF).map(t => t.type);
  assertArrayIncludes(types, [
    TokenType.PLUS,
    TokenType.MINUS,
    TokenType.STAR,
    TokenType.SLASH,
    TokenType.PERCENT,
    TokenType.EQ,
    TokenType.NEQ,
    TokenType.LT,
    TokenType.GT,
    TokenType.LTE,
    TokenType.GTE,
    TokenType.ASSIGN,
  ]);
});

Deno.test("Lexer - tokenizes template syntax", () => {
  const source = "{{ variable }}";
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  assertEquals(tokens[0].type, TokenType.TEMPLATE_START);
  assertEquals(tokens[1].type, TokenType.IDENTIFIER);
  assertEquals(tokens[1].value, "variable");
  assertEquals(tokens[2].type, TokenType.TEMPLATE_END);
});

Deno.test("Lexer - tokenizes identifiers", () => {
  const source = "foo bar_baz myVar123";
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  const identifiers = tokens.filter(t => t.type === TokenType.IDENTIFIER);
  assertEquals(identifiers.length, 3);
  assertEquals(identifiers[0].value, "foo");
  assertEquals(identifiers[1].value, "bar_baz");
  assertEquals(identifiers[2].value, "myVar123");
});

Deno.test("Lexer - tracks line numbers", () => {
  const source = `let x = 1
let y = 2
let z = 3`;
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  const lets = tokens.filter(t => t.type === TokenType.LET);
  assertEquals(lets[0].line, 1);
  assertEquals(lets[1].line, 2);
  assertEquals(lets[2].line, 3);
});

Deno.test("Lexer - handles comments", () => {
  const source = `let x = 1 // this is a comment
let y = 2`;
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  // Should not include comment content as tokens
  const identifiers = tokens.filter(t => t.type === TokenType.IDENTIFIER);
  assertEquals(identifiers.length, 2);
  assertEquals(identifiers[0].value, "x");
  assertEquals(identifiers[1].value, "y");
});

Deno.test("Lexer - tokenizes arrow", () => {
  const source = "->";
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  assertEquals(tokens[0].type, TokenType.ARROW);
  assertEquals(tokens[0].value, "->");
});

Deno.test("Lexer - handles empty input", () => {
  const source = "";
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();

  assertEquals(tokens.length, 1);
  assertEquals(tokens[0].type, TokenType.EOF);
});
