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

#include "api_validation_pass.h"

#include <assert.h>
#include <stdarg.h>
#include <string.h>

#include <filesystem>

#include <ast/native_class.h>

namespace Toucan {

APIValidationPass::APIValidationPass(NodeVector* nodes, TypeTable* types)
    : nodes_(nodes), types_(types) {}

int APIValidationPass::Run() {
  for (auto type : types_->GetTypes()) {
    if (type->IsClass()) {
      ClassType* classType = static_cast<ClassType*>(type);
      auto classTemplate = classType->GetTemplate();
      if (classTemplate == NativeClass::Buffer) {
      }
    }
  }
  return numErrors_;
}

Result APIValidationPass::Visit(ArrayAccess* node) {
  Resolve(node->GetExpr());
  Resolve(node->GetIndex());
  return {};
}

Result APIValidationPass::Visit(CastExpr* node) {
  Resolve(node->GetExpr());
  return {};
}

Result APIValidationPass::Visit(IntConstant* node) { return {}; }

Result APIValidationPass::Visit(UIntConstant* node) { return {}; }

Result APIValidationPass::Visit(EnumConstant* node) { return {}; }

Result APIValidationPass::Visit(DoubleConstant* node) { return {}; }

Result APIValidationPass::Visit(FloatConstant* node) { return {}; }

Result APIValidationPass::Visit(BoolConstant* node) { return {}; }

Result APIValidationPass::Visit(NullConstant* node) { return {}; }

Result APIValidationPass::Visit(Stmts* stmts) {
  for (Stmt* const& it : stmts->GetStmts()) {
    Resolve(it);
  }
  return {};
}

Result APIValidationPass::Visit(ArgList* a) {
  for (Arg* const& i : a->GetArgs()) {
    Resolve(i);
  }
  return {};
}

Result APIValidationPass::Visit(ExprStmt* stmt) {
  Resolve(stmt->GetExpr());
  return {};
}

Result APIValidationPass::Visit(VarDeclaration* decl) { return {}; }

Result APIValidationPass::Visit(LoadExpr* node) {
  Resolve(node->GetExpr());
  return {};
}

Result APIValidationPass::Visit(StoreStmt* node) {
  Resolve(node->GetLHS());
  Resolve(node->GetRHS());
  return {};
}

Result APIValidationPass::Visit(BinOpNode* node) {
  Resolve(node->GetRHS());
  Resolve(node->GetLHS());
  return {};
}

Result APIValidationPass::Visit(UnaryOp* node) {
  Resolve(node->GetRHS());
  return {};
}

Result APIValidationPass::Visit(ReturnStatement* stmt) {
  Resolve(stmt->GetExpr());
  return {};
}

Result APIValidationPass::Visit(IfStatement* s) {
  Resolve(s->GetExpr());
  Resolve(s->GetStmt());
  Resolve(s->GetOptElse());
  return {};
}

Result APIValidationPass::Visit(WhileStatement* s) {
  Resolve(s->GetCond());
  Resolve(s->GetBody());
  return {};
}

Result APIValidationPass::Visit(DoStatement* s) {
  Resolve(s->GetBody());
  Resolve(s->GetCond());
  return {};
}

Result APIValidationPass::Visit(ForStatement* node) {
  Resolve(node->GetInitStmt());
  Resolve(node->GetCond());
  Resolve(node->GetLoopStmt());
  Resolve(node->GetBody());
  return {};
}

Result APIValidationPass::Visit(FieldAccess* fieldAccess) {
  Resolve(fieldAccess->GetExpr());
  return {};
}

Result APIValidationPass::Default(ASTNode* node) {
  Error(node, "Internal compiler error");
  return {};
}

Result APIValidationPass::Resolve(ASTNode* node) { return node->Accept(this); }

void APIValidationPass::Error(ASTNode* node, const char* fmt, ...) {
  const FileLocation& location = node->GetFileLocation();
  std::string         filename =
      location.filename ? std::filesystem::path(*location.filename).filename().string() : "";
  va_list argp;
  va_start(argp, fmt);
  fprintf(stderr, "%s:%d:  ", filename.c_str(), location.lineNum);
  vfprintf(stderr, fmt, argp);
  fprintf(stderr, "\n");
  numErrors_++;
}

};  // namespace Toucan
