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

#ifndef _AST_DUMP_AS_SOURCE_PASS_H_
#define _AST_DUMP_AS_SOURCE_PASS_H_

#include "ast.h"

#ifdef __gnuc__
#define CHECK_FORMAT(archetype, string_index, first_to_check) \
  __attribute__((format(archetype, string_index, first_to_check)))
#else
#define CHECK_FORMAT(...)
#endif

namespace Toucan {

class SymbolTable;

class PrintAST : public Visitor {
 public:
  PrintAST();
  void   Resolve(ASTNode* node);
  void   Output(ASTNode* node, const char* fmt, ...) CHECK_FORMAT(printf, 3, 4);

  Result Visit(ArgList* node) override;
  Result Visit(ArrayAccess* node) override;
  Result Visit(BinOpNode* node) override;
  Result Visit(BoolConstant* node) override;
  Result Visit(CastExpr* node) override;
  Result Visit(DestroyStmt* node) override;
  Result Visit(EnumConstant* node) override;
  Result Visit(ExprList* node) override;
  Result Visit(ExprStmt* node) override;
  Result Visit(ExprWithStmt* node) override;
  Result Visit(DoubleConstant* node) override;
  Result Visit(ExtractElementExpr* node) override;
  Result Visit(FieldAccess* node) override;
  Result Visit(FloatConstant* node) override;
  Result Visit(Initializer* node) override;
  Result Visit(IntConstant* node) override;
  Result Visit(InsertElementExpr* node) override;
  Result Visit(MethodCall* node) override;
  Result Visit(NullConstant* node) override;
  Result Visit(ReturnStatement* node) override;
  Result Visit(LoadExpr* node) override;
  Result Visit(SmartToRawPtr* node) override;
  Result Visit(Stmts* node) override;
  Result Visit(StoreStmt* node) override;
  Result Visit(TempVarExpr* node) override;
  Result Visit(UIntConstant* node) override;
  Result Visit(UnresolvedListExpr* node) override;
  Result Visit(VarDeclaration* node) override;
  Result Visit(VarExpr* node) override;
  Result Default(ASTNode* node) override;

 private:
  int                               indent_ = 0;
};

};  // namespace Toucan
#endif
