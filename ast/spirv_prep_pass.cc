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
    newStmts->Append(Resolve(it));
  }
  enclosingStmts_ = temp;
  return newStmts;
}

Result SPIRVPrepPass::Visit(MethodCall* node) {
  Method*                   method = node->GetMethod();
  const std::vector<Expr*>& args = node->GetArgList()->Get();
  auto* newArgs = Make<ExprList>();
  for (auto& i : args) {
    Expr* arg = i;
    auto* type = arg->GetType(types_);
    if (type->IsPtr()) {
      // FIXME: skip if no FieldAccess or ArrayAccess in arg
      arg = Make<SmartToRawPtr>(arg);
      type = arg->GetType(types_);
      auto var = std::make_shared<Var>("temp", type);
      enclosingStmts_->AppendVar(var);
      VarExpr* varExpr = Make<VarExpr>(var.get());
      auto* baseType = static_cast<PtrType*>(type)->GetBaseType();
      if (baseType->IsReadable()) {
        Expr* load = Make<LoadExpr>(arg);
        Stmt* store = Make<StoreStmt>(varExpr, load);
        arg = Make<ExprWithStmt>(varExpr, store);
      } else {
        arg = varExpr;
      }
//      if (baseType->IsWriteable()) {
//        temporaryArgs.push_back({resultArg, temporaryId, valueType});
//      }
    }
    newArgs->Append(arg);
  }
  return Make<MethodCall>(method, newArgs);
}

Result SPIRVPrepPass::Default(ASTNode* node) {
  return node;
}

};  // namespace Toucan
