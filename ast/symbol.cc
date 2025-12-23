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

#include "symbol.h"

#include <string.h>

#include "type.h"

namespace Toucan {

SymbolTable::SymbolTable() : currentScope_(nullptr) {}

void SymbolTable::PushScope(Stmts* scope) {
  scope->SetParent(currentScope_);
  currentScope_ = scope;
}

Stmts* SymbolTable::PopScope() {
  Stmts* back = currentScope_;
  currentScope_ = back ? back->GetParent() : nullptr;
  return back;
}

Stmts* SymbolTable::PeekScope() { return currentScope_; }

Expr* SymbolTable::FindID(const std::string& identifier) const {
  for (Stmts* scope = currentScope_; scope != nullptr; scope = scope->GetParent()) {
    if (Expr* expr = scope->FindID(identifier)) return expr;
  }
  return nullptr;
}

Var* SymbolTable::AppendVar(std::string identifier, Type* type) {
  if (!currentScope_) return nullptr;
  auto var = std::make_shared<Var>(identifier, type);
  currentScope_->AppendVar(var);
  return var.get();
}

void SymbolTable::DefineID(std::string identifier, Expr* expr) {
  assert(currentScope_);
  currentScope_->DefineID(identifier, expr);
}

void SymbolTable::DefineType(std::string identifier, Type* type) {
  assert(currentScope_);
  currentScope_->DefineType(identifier, type);
}

Type* SymbolTable::FindType(const std::string& identifier) const {
  for (auto scope = currentScope_; scope != nullptr; scope = scope->GetParent()) {
    if (auto type = scope->FindType(identifier)) return type;
  }
  return nullptr;
}

};  // namespace Toucan
