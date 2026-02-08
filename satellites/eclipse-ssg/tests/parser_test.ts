// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// parser_test.ts — Unit tests for NoteG parser

import { assertEquals, assertExists } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { Lexer } from "../noteg-lang/src/lexer.ts";
import { Parser, ProgramNode, LetNode, FunctionNode, IfNode, LiteralNode, BinaryExprNode } from "../noteg-lang/src/parser.ts";

function parse(source: string): ProgramNode {
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();
  const parser = new Parser(tokens);
  return parser.parse();
}

Deno.test("Parser - parses let declaration", () => {
  const ast = parse("let x = 42");

  assertEquals(ast.type, "Program");
  assertEquals(ast.body.length, 1);

  const letNode = ast.body[0] as LetNode;
  assertEquals(letNode.type, "Let");
  assertEquals(letNode.name, "x");
  assertEquals((letNode.value as LiteralNode).value, 42);
});

Deno.test("Parser - parses function declaration", () => {
  const ast = parse("fn add(a, b) { return a + b }");

  assertEquals(ast.body.length, 1);

  const fnNode = ast.body[0] as FunctionNode;
  assertEquals(fnNode.type, "Function");
  assertEquals(fnNode.name, "add");
  assertEquals(fnNode.params, ["a", "b"]);
});

Deno.test("Parser - parses if statement", () => {
  const ast = parse("if x > 0 { let y = 1 }");

  assertEquals(ast.body.length, 1);

  const ifNode = ast.body[0] as IfNode;
  assertEquals(ifNode.type, "If");
  assertExists(ifNode.condition);
  assertExists(ifNode.thenBranch);
  assertEquals(ifNode.elseBranch, null);
});

Deno.test("Parser - parses if-else statement", () => {
  const ast = parse("if x > 0 { let y = 1 } else { let y = 0 }");

  const ifNode = ast.body[0] as IfNode;
  assertExists(ifNode.elseBranch);
});

Deno.test("Parser - parses binary expressions", () => {
  const ast = parse("let x = 1 + 2 * 3");

  const letNode = ast.body[0] as LetNode;
  const expr = letNode.value as BinaryExprNode;

  // 1 + (2 * 3) due to precedence
  assertEquals(expr.type, "BinaryExpr");
  assertEquals(expr.operator, "+");
});

Deno.test("Parser - parses comparison expressions", () => {
  const ast = parse("let x = a == b");

  const letNode = ast.body[0] as LetNode;
  const expr = letNode.value as BinaryExprNode;

  assertEquals(expr.type, "BinaryExpr");
  assertEquals(expr.operator, "==");
});

Deno.test("Parser - parses logical expressions", () => {
  const ast = parse("let x = a and b or c");

  const letNode = ast.body[0] as LetNode;
  const expr = letNode.value as BinaryExprNode;

  // (a and b) or c
  assertEquals(expr.type, "BinaryExpr");
  assertEquals(expr.operator, "or");
});

Deno.test("Parser - parses function calls", () => {
  const ast = parse("print(42)");

  assertEquals(ast.body.length, 1);
  assertEquals(ast.body[0].type, "Call");
});

Deno.test("Parser - parses arrays", () => {
  const ast = parse("let arr = [1, 2, 3]");

  const letNode = ast.body[0] as LetNode;
  assertEquals(letNode.value.type, "Array");
});

Deno.test("Parser - parses nested expressions", () => {
  const ast = parse("let x = (1 + 2) * 3");

  const letNode = ast.body[0] as LetNode;
  const expr = letNode.value as BinaryExprNode;

  assertEquals(expr.operator, "*");
});

Deno.test("Parser - parses multiple statements", () => {
  const ast = parse(`
    let x = 1
    let y = 2
    let z = x + y
  `);

  assertEquals(ast.body.length, 3);
});

Deno.test("Parser - parses for loop", () => {
  const ast = parse("for item in items { print(item) }");

  assertEquals(ast.body.length, 1);
  assertEquals(ast.body[0].type, "For");
});

Deno.test("Parser - parses while loop", () => {
  const ast = parse("while x > 0 { let x = x - 1 }");

  assertEquals(ast.body.length, 1);
  assertEquals(ast.body[0].type, "While");
});

Deno.test("Parser - parses template variable", () => {
  const ast = parse("let x = {{ title }}");

  const letNode = ast.body[0] as LetNode;
  assertEquals(letNode.value.type, "Template");
});
