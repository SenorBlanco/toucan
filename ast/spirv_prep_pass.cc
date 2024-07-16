// Copyright 2024 The Toucan Authors
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

#include "spirv_prep_pass.h"

namespace Toucan {

SPIRVPrepPass::SPIRVPrepPass(NodeVector* nodes, TypeTable* types)
    : CopyVisitor(nodes), types_(types) {}

Result SPIRVPrepPass::Visit(Stmts* stmts) {
  Stmts* temp = enclosingStmts_;
  Stmts* newStmts = enclosingStmts_ = Make<Stmts>();

  for (Stmt* const& it : stmts->GetStmts()) {
    Stmt* stmt = Resolve(it);
    if (stmt) newStmts->Append(stmt);
  }
  for (auto var : stmts->GetVars()) {
    newStmts->AppendVar(var);
  }
  enclosingStmts_ = temp;
  return newStmts;
}

Result SPIRVPrepPass::Visit(MethodCall* node) {
  Method*                   method = node->GetMethod();
  const std::vector<Expr*>& args = node->GetArgList()->Get();
  auto* newArgs = Make<ExprList>();
  Stmts* writeStmts = nullptr;
  for (auto& i : args) {
    Expr* arg = Resolve(i);
    auto* type = arg->GetType(types_);
    if (type->IsPtr() && arg->IsFieldAccess() || arg->IsArrayAccess()) {
      auto* baseType = static_cast<PtrType*>(type)->GetBaseType();
      auto var = std::make_shared<Var>("temp", baseType);
      enclosingStmts_->AppendVar(var);
      VarExpr* varExpr = Make<VarExpr>(var.get());
      if (baseType->IsReadable()) {
        Expr* load = Make<LoadExpr>(arg);
        Stmt* store = Make<StoreStmt>(varExpr, load);
        arg = Make<ExprWithStmt>(varExpr, store);
      } else {
        arg = varExpr;
      }
      if (baseType->IsWriteable()) {
        if (!writeStmts) writeStmts = Make<Stmts>();
        Expr* load = Make<LoadExpr>(varExpr);
        Stmt* store = Make<StoreStmt>(arg, load);
        writeStmts->Append(store);
      }
    }
    newArgs->Append(arg);
  }
  Expr* result = Make<MethodCall>(method, newArgs);
  if (writeStmts) result = Make<ExprWithStmt>(result, writeStmts);
  return result;
}

Result SPIRVPrepPass::Visit(RawToWeakPtr* node) {
  // All pointers are raw pointers in SPIR-V.
  return Resolve(node->GetExpr());
}

Result SPIRVPrepPass::Visit(ZeroInitStmt* node) {
  // All variables are zero-initialized already
  return nullptr;
}

Result SPIRVPrepPass::Default(ASTNode* node) {
  assert(false);
  return nullptr;
}

};  // namespace Toucan
