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

Scope* SymbolTable::PushNewScope() {
  Scope* scope = new Scope(currentScope_);
  scopes_.push_back(std::unique_ptr<Scope>(scope));
  currentScope_ = scope;
  return scope;
}

void SymbolTable::PushScope(Scope* scope) {
  assert(scope && currentScope_ == scope->parent);
  currentScope_ = scope;
}

Scope* SymbolTable::PopScope() {
  Scope* back = currentScope_;
  currentScope_ = back ? back->parent : nullptr;
  return back;
}

Scope* SymbolTable::PeekScope() { return currentScope_; }

Expr* SymbolTable::FindID(const std::string& identifier) const {
  for (Scope* scope = currentScope_; scope != nullptr; scope = scope->parent) {
    ExprMap::const_iterator j = scope->ids.find(identifier);
    if (j != scope->ids.end()) { return j->second; }
  }
  return nullptr;
}

Var* SymbolTable::DefineVar(std::string identifier, Type* type) {
  if (!currentScope_) return nullptr;
  auto var = std::make_shared<Var>(identifier, type);
  currentScope_->vars.push_back(var);
  return var.get();
}

void SymbolTable::DefineID(std::string identifier, Expr* expr) {
  assert(currentScope_);
  currentScope_->ids[identifier] = expr;
}

bool SymbolTable::DefineType(std::string identifier, Type* type) {
  if (!currentScope_) return false;
  currentScope_->types[identifier] = type;
  return true;
}

Type* SymbolTable::FindType(const std::string& identifier) const {
  Scope* scope = currentScope_;
  for (scope = currentScope_; scope != nullptr; scope = scope->parent) {
    TypeMap::const_iterator j = scope->types.find(identifier);
    if (j != scope->types.end()) { return j->second; }
  }
  return nullptr;
}

void SymbolTable::Dump() {
  for (const auto& scope : scopes_) {
    printf("Scope:\n");
    for (auto var : scope->vars) {
      printf("  %s", var->type->ToString().c_str());
      printf(" %s;\n", var->name.c_str());
    }
    for (const auto& i : scope->types) {
      const char* name = i.first.c_str();
      const Type* t = i.second;
      if (t->IsClass()) {
        printf("  class %s;\n", name);
      } else if (t->IsEnum()) {
        printf("  enum %s;\n", name);
      }
    }
  }
}

};  // namespace Toucan
