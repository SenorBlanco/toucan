// Copyright 2023 The Toucan Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "print_ast.h"

#include <stdarg.h>

// #include "symbol.h"

namespace Toucan {

PrintAST::PrintAST() {}

void PrintAST::Resolve(ASTNode* node) {
  indent_++;
  node->Accept(this);
  indent_--;
}

void PrintAST::Output(ASTNode* node, const char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  for (int i = 0; i < indent_; ++i) {
    printf("  ");
  }
  vprintf(fmt, ap);
  printf("\n");
}

Result PrintAST::Visit(ArgList* node) {
  Output(node, "ArgList");
  return {};
}

Result PrintAST::Visit(ArrayAccess* node) {
  Output(node, "ArrayAccess");
  Resolve(node->GetExpr());
  Resolve(node->GetIndex());
  return {};
}

Result PrintAST::Visit(CastExpr* node) {
  Output(node, "CastExpr %s", node->GetType()->ToString().c_str());
  Resolve(node->GetExpr());
  return {};
}

Result PrintAST::Visit(DestroyStmt* node) {
  Output(node, "DestroyStmt");
  Resolve(node->GetExpr());
  return {};
}

Result PrintAST::Visit(ExtractElementExpr* node) {
  Output(node, "ExtractElementExpr %d", node->GetIndex());
  Resolve(node->GetExpr());
  return {};
}

Result PrintAST::Visit(InsertElementExpr* node) {
  Output(node, "InsertElementExpr %d", node->GetIndex());
  Resolve(node->GetExpr());
  return {};
}

Result PrintAST::Visit(ExprWithStmt* node) {
  Output(node, "ExprWithStmt");
  if (node->GetExpr()) { Resolve(node->GetExpr()); }
  Resolve(node->GetStmt());
  return {};
}

Result PrintAST::Visit(IntConstant* node) {
  Output(node, "IntConstant> %d (%d bit)", node->GetValue(), node->GetBits());
  return {};
}

Result PrintAST::Visit(UIntConstant* node) {
  Output(node, "UIntConstant> %u (%d bit)", node->GetValue(), node->GetBits());
  return {};
}

Result PrintAST::Visit(EnumConstant* node) {
  Output(node, "EnumConstant %s.%s (%d)", node->GetValue()->type->ToString().c_str(), node->GetValue()->id.c_str(), node->GetValue()->value);
  return {};
}

Result PrintAST::Visit(FieldAccess* node) {
  Output(node, "FieldAccess %s", node->GetField()->name.c_str());
  Resolve(node->GetExpr());
  return {};
}

Result PrintAST::Visit(FloatConstant* node) {
  Output(node, "FloatConstant %g", node->GetValue());
  return {};
}

Result PrintAST::Visit(DoubleConstant* node) {
  Output(node, "DoubleConstant %lg)", node->GetValue());
  return {};
}

Result PrintAST::Visit(BoolConstant* node) {
  Output(node, "BoolConstant %s", node->GetValue() ? "true" : "false");
  return {};
}

Result PrintAST::Visit(NullConstant* node) {
  Output(node, "NullConstant");
  return {};
}

Result PrintAST::Visit(Stmts* node) {
  Output(node, "Stmts");
  for (Stmt* const& it : node->GetStmts()) {
    Resolve(it);
  }
  return {};
}

Result PrintAST::Visit(MethodCall* node) {
  Output(node, "MethodCall %s", node->GetMethod()->ToString().c_str());
  Resolve(node->GetArgList());
  return {};
}

Result PrintAST::Visit(ExprList* a) {
  Output(a, "ExprList");
  for (auto expr : a->Get()) {
    if (expr) Resolve(expr); else Output(a, "(null)");
  }
  return {};
}

Result PrintAST::Visit(ExprStmt* node) {
  Output(node, "ExprStmt");
  Resolve(node->GetExpr());
  return {};
}

Result PrintAST::Visit(Initializer* node) {
  Output(node, "Initializer %s", node->GetType()->ToString().c_str());
  Resolve(node->GetArgList());
  return {};
}

Result PrintAST::Visit(VarDeclaration* decl) {
  Output(decl, "VarDeclaration %s", decl->GetType()->ToString().c_str());
  Resolve(decl->GetInitExpr());
  return {};
}

Result PrintAST::Visit(LoadExpr* node) {
  Output(node, "LoadExpr");
  Resolve(node->GetExpr());
  return {};
}

Result PrintAST::Visit(StoreStmt* node) {
  Output(node, "StoreStmt");
  Resolve(node->GetLHS());
  Resolve(node->GetRHS());
  return {};
}

Result PrintAST::Visit(SmartToRawPtr* node) {
  Output(node, "SmartToRawPtr");
  Resolve(node->GetExpr());
  return {};
}

static const char* GetOp(BinOpNode::Op op) {
  switch (op) {
    case BinOpNode::ADD: return "ADD";
    case BinOpNode::SUB: return "SUB";
    case BinOpNode::MUL: return "MUL";
    case BinOpNode::DIV: return "DIV";
    case BinOpNode::LT: return "LT";
    case BinOpNode::LE: return "LE";
    case BinOpNode::GE: return "GE";
    case BinOpNode::GT: return "GT";
    case BinOpNode::NE: return "NE";
    case BinOpNode::BITWISE_AND: return "BITWISE_AND";
    case BinOpNode::BITWISE_OR: return "BITWISE_OR";
    default: assert(false); return "";
  }
}

Result PrintAST::Visit(BinOpNode* node) {
  Output(node, "BinOpNode %s", GetOp(node->GetOp()));
  Resolve(node->GetLHS());
  Resolve(node->GetRHS());
  return {};
}


Result PrintAST::Visit(UnresolvedListExpr* node) {
  Output(node, "UnresolvedListExpr");
  Resolve(node->GetArgList());
  return {};
}

Result PrintAST::Visit(ReturnStatement* node) {
  Output(node, "ReturnStatement");
  if (node->GetExpr()) {
    Resolve(node->GetExpr());
  }
  return {};
}

Result PrintAST::Visit(TempVarExpr* node) {
  Output(node, "TempVarExpr (%s)", node->GetType()->ToString().c_str());
  if (node->GetInitExpr()) {
    Resolve(node->GetInitExpr());
  }
  return {};
}

Result PrintAST::Visit(VarExpr* node) {
  auto var = node->GetVar();
  Output(node, "VarExpr %s : %s", var->name.c_str(), var->type->ToString().c_str());
  return {};
}

Result PrintAST::Default(ASTNode* node) {
  Output(node, "*** unknown node ***");
  return {};
}

};  // namespace Toucan
