// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// interpreter.ts — NoteG language interpreter

import { Lexer } from "./lexer.ts";
import { Parser, ASTNode, ProgramNode, LetNode, FunctionNode, IfNode, ForNode, WhileNode, ReturnNode, BinaryExprNode, UnaryExprNode, CallNode, IdentifierNode, LiteralNode, ArrayNode, ObjectNode, TemplateNode, BlockNode } from "./parser.ts";

// ============================================================
// RUNTIME VALUES
// ============================================================

export type Value =
  | string
  | number
  | boolean
  | null
  | Value[]
  | { [key: string]: Value }
  | FunctionValue;

export interface FunctionValue {
  type: "function";
  name: string;
  params: string[];
  body: ASTNode;
  closure: Environment;
}

// ============================================================
// ENVIRONMENT
// ============================================================

export class Environment {
  private values: Map<string, Value> = new Map();
  private parent: Environment | null;

  constructor(parent: Environment | null = null) {
    this.parent = parent;
  }

  define(name: string, value: Value): void {
    this.values.set(name, value);
  }

  get(name: string): Value {
    if (this.values.has(name)) {
      return this.values.get(name)!;
    }
    if (this.parent) {
      return this.parent.get(name);
    }
    throw new Error(`Undefined variable: ${name}`);
  }

  assign(name: string, value: Value): void {
    if (this.values.has(name)) {
      this.values.set(name, value);
      return;
    }
    if (this.parent) {
      this.parent.assign(name, value);
      return;
    }
    throw new Error(`Undefined variable: ${name}`);
  }
}

// ============================================================
// RETURN EXCEPTION (for early return)
// ============================================================

class ReturnException extends Error {
  value: Value;

  constructor(value: Value) {
    super("return");
    this.value = value;
  }
}

// ============================================================
// INTERPRETER
// ============================================================

export class Interpreter {
  private globalEnv: Environment;

  constructor() {
    this.globalEnv = new Environment();
    this.setupBuiltins();
  }

  private setupBuiltins(): void {
    // Built-in print function
    this.globalEnv.define("print", {
      type: "function",
      name: "print",
      params: ["value"],
      body: { type: "Block", statements: [] } as BlockNode,
      closure: this.globalEnv,
    });

    // Built-in len function
    this.globalEnv.define("len", {
      type: "function",
      name: "len",
      params: ["value"],
      body: { type: "Block", statements: [] } as BlockNode,
      closure: this.globalEnv,
    });
  }

  interpret(program: ProgramNode): Value {
    let result: Value = null;

    for (const node of program.body) {
      result = this.evaluate(node, this.globalEnv);
    }

    return result;
  }

  private evaluate(node: ASTNode, env: Environment): Value {
    switch (node.type) {
      case "Program":
        return this.evaluateProgram(node as ProgramNode, env);
      case "Let":
        return this.evaluateLet(node as LetNode, env);
      case "Function":
        return this.evaluateFunction(node as FunctionNode, env);
      case "If":
        return this.evaluateIf(node as IfNode, env);
      case "For":
        return this.evaluateFor(node as ForNode, env);
      case "While":
        return this.evaluateWhile(node as WhileNode, env);
      case "Return":
        throw new ReturnException(
          (node as ReturnNode).value
            ? this.evaluate((node as ReturnNode).value!, env)
            : null
        );
      case "Block":
        return this.evaluateBlock(node as BlockNode, env);
      case "BinaryExpr":
        return this.evaluateBinaryExpr(node as BinaryExprNode, env);
      case "UnaryExpr":
        return this.evaluateUnaryExpr(node as UnaryExprNode, env);
      case "Call":
        return this.evaluateCall(node as CallNode, env);
      case "Identifier":
        return env.get((node as IdentifierNode).name);
      case "Literal":
        return (node as LiteralNode).value;
      case "Array":
        return (node as ArrayNode).elements.map((el) => this.evaluate(el, env));
      case "Template":
        return env.get((node as TemplateNode).variable);
      default:
        throw new Error(`Unknown node type: ${(node as ASTNode).type}`);
    }
  }

  private evaluateProgram(node: ProgramNode, env: Environment): Value {
    let result: Value = null;
    for (const stmt of node.body) {
      result = this.evaluate(stmt, env);
    }
    return result;
  }

  private evaluateLet(node: LetNode, env: Environment): Value {
    const value = this.evaluate(node.value, env);
    env.define(node.name, value);
    return value;
  }

  private evaluateFunction(node: FunctionNode, env: Environment): Value {
    const fn: FunctionValue = {
      type: "function",
      name: node.name,
      params: node.params,
      body: node.body,
      closure: env,
    };
    env.define(node.name, fn);
    return fn;
  }

  private evaluateIf(node: IfNode, env: Environment): Value {
    const condition = this.evaluate(node.condition, env);

    if (this.isTruthy(condition)) {
      return this.evaluate(node.thenBranch, env);
    } else if (node.elseBranch) {
      return this.evaluate(node.elseBranch, env);
    }

    return null;
  }

  private evaluateFor(node: ForNode, env: Environment): Value {
    const iterable = this.evaluate(node.iterable, env);

    if (!Array.isArray(iterable)) {
      throw new Error("For loop requires an array");
    }

    let result: Value = null;
    for (const item of iterable) {
      const loopEnv = new Environment(env);
      loopEnv.define(node.variable, item);
      result = this.evaluate(node.body, loopEnv);
    }

    return result;
  }

  private evaluateWhile(node: WhileNode, env: Environment): Value {
    let result: Value = null;

    while (this.isTruthy(this.evaluate(node.condition, env))) {
      result = this.evaluate(node.body, env);
    }

    return result;
  }

  private evaluateBlock(node: BlockNode, env: Environment): Value {
    const blockEnv = new Environment(env);
    let result: Value = null;

    for (const stmt of node.statements) {
      result = this.evaluate(stmt, blockEnv);
    }

    return result;
  }

  private evaluateBinaryExpr(node: BinaryExprNode, env: Environment): Value {
    const left = this.evaluate(node.left, env);
    const right = this.evaluate(node.right, env);

    switch (node.operator) {
      case "+":
        if (typeof left === "string" || typeof right === "string") {
          return String(left) + String(right);
        }
        return (left as number) + (right as number);
      case "-":
        return (left as number) - (right as number);
      case "*":
        return (left as number) * (right as number);
      case "/":
        return (left as number) / (right as number);
      case "%":
        return (left as number) % (right as number);
      case "==":
        return left === right;
      case "!=":
        return left !== right;
      case "<":
        return (left as number) < (right as number);
      case ">":
        return (left as number) > (right as number);
      case "<=":
        return (left as number) <= (right as number);
      case ">=":
        return (left as number) >= (right as number);
      case "and":
        return this.isTruthy(left) && this.isTruthy(right);
      case "or":
        return this.isTruthy(left) || this.isTruthy(right);
      default:
        throw new Error(`Unknown operator: ${node.operator}`);
    }
  }

  private evaluateUnaryExpr(node: UnaryExprNode, env: Environment): Value {
    const operand = this.evaluate(node.operand, env);

    switch (node.operator) {
      case "-":
        return -(operand as number);
      case "not":
      case "!":
        return !this.isTruthy(operand);
      default:
        throw new Error(`Unknown operator: ${node.operator}`);
    }
  }

  private evaluateCall(node: CallNode, env: Environment): Value {
    const callee = this.evaluate(node.callee, env);

    if (typeof callee !== "object" || callee === null || !("type" in callee) || callee.type !== "function") {
      throw new Error("Can only call functions");
    }

    const fn = callee as FunctionValue;
    const args = node.args.map((arg) => this.evaluate(arg, env));

    // Handle built-in functions
    if (fn.name === "print") {
      console.log(...args);
      return null;
    }

    if (fn.name === "len") {
      const value = args[0];
      if (Array.isArray(value)) {
        return value.length;
      }
      if (typeof value === "string") {
        return value.length;
      }
      throw new Error("len() requires an array or string");
    }

    // User-defined function
    const fnEnv = new Environment(fn.closure);
    for (let i = 0; i < fn.params.length; i++) {
      fnEnv.define(fn.params[i], args[i] ?? null);
    }

    try {
      return this.evaluate(fn.body, fnEnv);
    } catch (e) {
      if (e instanceof ReturnException) {
        return e.value;
      }
      throw e;
    }
  }

  private isTruthy(value: Value): boolean {
    if (value === null) return false;
    if (typeof value === "boolean") return value;
    if (typeof value === "number") return value !== 0;
    if (typeof value === "string") return value.length > 0;
    if (Array.isArray(value)) return value.length > 0;
    return true;
  }
}

// ============================================================
// CLI ENTRY POINT
// ============================================================

if (import.meta.main) {
  const file = Deno.args[0];
  if (!file) {
    console.error("Usage: interpreter.ts <file>");
    Deno.exit(1);
  }

  const source = await Deno.readTextFile(file);
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();
  const parser = new Parser(tokens);
  const ast = parser.parse();
  const interpreter = new Interpreter();
  const result = interpreter.interpret(ast);

  if (result !== null) {
    console.log("Result:", result);
  }
}
