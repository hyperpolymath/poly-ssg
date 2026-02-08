// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// parser.ts — NoteG language parser

import { Lexer, Token, TokenType } from "./lexer.ts";

// ============================================================
// AST NODES
// ============================================================

export type ASTNode =
  | ProgramNode
  | LetNode
  | FunctionNode
  | IfNode
  | ForNode
  | WhileNode
  | ReturnNode
  | BinaryExprNode
  | UnaryExprNode
  | CallNode
  | IdentifierNode
  | LiteralNode
  | ArrayNode
  | ObjectNode
  | TemplateNode
  | BlockNode;

export interface ProgramNode {
  type: "Program";
  body: ASTNode[];
}

export interface LetNode {
  type: "Let";
  name: string;
  value: ASTNode;
}

export interface FunctionNode {
  type: "Function";
  name: string;
  params: string[];
  body: ASTNode;
}

export interface IfNode {
  type: "If";
  condition: ASTNode;
  thenBranch: ASTNode;
  elseBranch: ASTNode | null;
}

export interface ForNode {
  type: "For";
  variable: string;
  iterable: ASTNode;
  body: ASTNode;
}

export interface WhileNode {
  type: "While";
  condition: ASTNode;
  body: ASTNode;
}

export interface ReturnNode {
  type: "Return";
  value: ASTNode | null;
}

export interface BinaryExprNode {
  type: "BinaryExpr";
  operator: string;
  left: ASTNode;
  right: ASTNode;
}

export interface UnaryExprNode {
  type: "UnaryExpr";
  operator: string;
  operand: ASTNode;
}

export interface CallNode {
  type: "Call";
  callee: ASTNode;
  args: ASTNode[];
}

export interface IdentifierNode {
  type: "Identifier";
  name: string;
}

export interface LiteralNode {
  type: "Literal";
  value: string | number | boolean | null;
}

export interface ArrayNode {
  type: "Array";
  elements: ASTNode[];
}

export interface ObjectNode {
  type: "Object";
  properties: { key: string; value: ASTNode }[];
}

export interface TemplateNode {
  type: "Template";
  variable: string;
}

export interface BlockNode {
  type: "Block";
  statements: ASTNode[];
}

// ============================================================
// PARSER
// ============================================================

export class Parser {
  private tokens: Token[];
  private pos: number = 0;

  constructor(tokens: Token[]) {
    this.tokens = tokens;
  }

  parse(): ProgramNode {
    const body: ASTNode[] = [];

    while (!this.isAtEnd()) {
      const stmt = this.declaration();
      if (stmt) {
        body.push(stmt);
      }
    }

    return { type: "Program", body };
  }

  private declaration(): ASTNode | null {
    if (this.check(TokenType.LET)) {
      return this.letDeclaration();
    }
    if (this.check(TokenType.FN)) {
      return this.functionDeclaration();
    }
    return this.statement();
  }

  private letDeclaration(): LetNode {
    this.advance(); // consume 'let'
    const name = this.consume(TokenType.IDENTIFIER, "Expected variable name").value;
    this.consume(TokenType.ASSIGN, "Expected '=' after variable name");
    const value = this.expression();
    return { type: "Let", name, value };
  }

  private functionDeclaration(): FunctionNode {
    this.advance(); // consume 'fn'
    const name = this.consume(TokenType.IDENTIFIER, "Expected function name").value;
    this.consume(TokenType.LPAREN, "Expected '(' after function name");

    const params: string[] = [];
    if (!this.check(TokenType.RPAREN)) {
      do {
        params.push(this.consume(TokenType.IDENTIFIER, "Expected parameter name").value);
      } while (this.match(TokenType.COMMA));
    }
    this.consume(TokenType.RPAREN, "Expected ')' after parameters");

    const body = this.block();
    return { type: "Function", name, params, body };
  }

  private statement(): ASTNode {
    if (this.check(TokenType.IF)) {
      return this.ifStatement();
    }
    if (this.check(TokenType.FOR)) {
      return this.forStatement();
    }
    if (this.check(TokenType.WHILE)) {
      return this.whileStatement();
    }
    if (this.check(TokenType.RETURN)) {
      return this.returnStatement();
    }
    if (this.check(TokenType.LBRACE)) {
      return this.block();
    }
    return this.expression();
  }

  private ifStatement(): IfNode {
    this.advance(); // consume 'if'
    const condition = this.expression();
    const thenBranch = this.block();

    let elseBranch: ASTNode | null = null;
    if (this.match(TokenType.ELSE)) {
      if (this.check(TokenType.IF)) {
        elseBranch = this.ifStatement();
      } else {
        elseBranch = this.block();
      }
    }

    return { type: "If", condition, thenBranch, elseBranch };
  }

  private forStatement(): ForNode {
    this.advance(); // consume 'for'
    const variable = this.consume(TokenType.IDENTIFIER, "Expected variable name").value;
    this.consume(TokenType.IDENTIFIER, "Expected 'in'"); // 'in' keyword
    const iterable = this.expression();
    const body = this.block();
    return { type: "For", variable, iterable, body };
  }

  private whileStatement(): WhileNode {
    this.advance(); // consume 'while'
    const condition = this.expression();
    const body = this.block();
    return { type: "While", condition, body };
  }

  private returnStatement(): ReturnNode {
    this.advance(); // consume 'return'
    let value: ASTNode | null = null;
    if (!this.check(TokenType.RBRACE) && !this.isAtEnd()) {
      value = this.expression();
    }
    return { type: "Return", value };
  }

  private block(): BlockNode {
    this.consume(TokenType.LBRACE, "Expected '{'");
    const statements: ASTNode[] = [];

    while (!this.check(TokenType.RBRACE) && !this.isAtEnd()) {
      const stmt = this.declaration();
      if (stmt) {
        statements.push(stmt);
      }
    }

    this.consume(TokenType.RBRACE, "Expected '}'");
    return { type: "Block", statements };
  }

  private expression(): ASTNode {
    return this.or();
  }

  private or(): ASTNode {
    let left = this.and();

    while (this.match(TokenType.OR)) {
      const right = this.and();
      left = { type: "BinaryExpr", operator: "or", left, right };
    }

    return left;
  }

  private and(): ASTNode {
    let left = this.equality();

    while (this.match(TokenType.AND)) {
      const right = this.equality();
      left = { type: "BinaryExpr", operator: "and", left, right };
    }

    return left;
  }

  private equality(): ASTNode {
    let left = this.comparison();

    while (this.match(TokenType.EQ, TokenType.NEQ)) {
      const operator = this.previous().value;
      const right = this.comparison();
      left = { type: "BinaryExpr", operator, left, right };
    }

    return left;
  }

  private comparison(): ASTNode {
    let left = this.term();

    while (this.match(TokenType.LT, TokenType.GT, TokenType.LTE, TokenType.GTE)) {
      const operator = this.previous().value;
      const right = this.term();
      left = { type: "BinaryExpr", operator, left, right };
    }

    return left;
  }

  private term(): ASTNode {
    let left = this.factor();

    while (this.match(TokenType.PLUS, TokenType.MINUS)) {
      const operator = this.previous().value;
      const right = this.factor();
      left = { type: "BinaryExpr", operator, left, right };
    }

    return left;
  }

  private factor(): ASTNode {
    let left = this.unary();

    while (this.match(TokenType.STAR, TokenType.SLASH, TokenType.PERCENT)) {
      const operator = this.previous().value;
      const right = this.unary();
      left = { type: "BinaryExpr", operator, left, right };
    }

    return left;
  }

  private unary(): ASTNode {
    if (this.match(TokenType.NOT, TokenType.MINUS)) {
      const operator = this.previous().value;
      const operand = this.unary();
      return { type: "UnaryExpr", operator, operand };
    }

    return this.call();
  }

  private call(): ASTNode {
    let expr = this.primary();

    while (true) {
      if (this.match(TokenType.LPAREN)) {
        const args: ASTNode[] = [];
        if (!this.check(TokenType.RPAREN)) {
          do {
            args.push(this.expression());
          } while (this.match(TokenType.COMMA));
        }
        this.consume(TokenType.RPAREN, "Expected ')' after arguments");
        expr = { type: "Call", callee: expr, args };
      } else {
        break;
      }
    }

    return expr;
  }

  private primary(): ASTNode {
    if (this.match(TokenType.TRUE)) {
      return { type: "Literal", value: true };
    }
    if (this.match(TokenType.FALSE)) {
      return { type: "Literal", value: false };
    }
    if (this.match(TokenType.NUMBER)) {
      return { type: "Literal", value: parseFloat(this.previous().value) };
    }
    if (this.match(TokenType.STRING)) {
      return { type: "Literal", value: this.previous().value };
    }
    if (this.match(TokenType.IDENTIFIER)) {
      return { type: "Identifier", name: this.previous().value };
    }
    if (this.match(TokenType.TEMPLATE_START)) {
      const variable = this.consume(TokenType.IDENTIFIER, "Expected variable name").value;
      this.consume(TokenType.TEMPLATE_END, "Expected '}}'");
      return { type: "Template", variable };
    }
    if (this.match(TokenType.LBRACKET)) {
      const elements: ASTNode[] = [];
      if (!this.check(TokenType.RBRACKET)) {
        do {
          elements.push(this.expression());
        } while (this.match(TokenType.COMMA));
      }
      this.consume(TokenType.RBRACKET, "Expected ']'");
      return { type: "Array", elements };
    }
    if (this.match(TokenType.LPAREN)) {
      const expr = this.expression();
      this.consume(TokenType.RPAREN, "Expected ')'");
      return expr;
    }

    throw new Error(`Unexpected token: ${this.peek().type}`);
  }

  // Helper methods
  private match(...types: TokenType[]): boolean {
    for (const type of types) {
      if (this.check(type)) {
        this.advance();
        return true;
      }
    }
    return false;
  }

  private check(type: TokenType): boolean {
    return !this.isAtEnd() && this.peek().type === type;
  }

  private advance(): Token {
    if (!this.isAtEnd()) {
      this.pos++;
    }
    return this.previous();
  }

  private consume(type: TokenType, message: string): Token {
    if (this.check(type)) {
      return this.advance();
    }
    throw new Error(`${message} at line ${this.peek().line}`);
  }

  private peek(): Token {
    return this.tokens[this.pos];
  }

  private previous(): Token {
    return this.tokens[this.pos - 1];
  }

  private isAtEnd(): boolean {
    return this.peek().type === TokenType.EOF;
  }
}

// ============================================================
// CLI ENTRY POINT
// ============================================================

if (import.meta.main) {
  const file = Deno.args[0];
  if (!file) {
    console.error("Usage: parser.ts <file>");
    Deno.exit(1);
  }

  const source = await Deno.readTextFile(file);
  const lexer = new Lexer(source);
  const tokens = lexer.tokenize();
  const parser = new Parser(tokens);
  const ast = parser.parse();

  console.log(JSON.stringify(ast, null, 2));
}
