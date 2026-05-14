
// Copyright 2026 The Toucan Authors
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

#ifndef _AST_AST_TEMPLATE_PASS_H_
#define _AST_AST_TEMPLATE_PASS_H_

#include "copy_visitor.h"

namespace Toucan {

class TemplatePass : public CopyVisitor {
 public:
  TemplatePass(NodeVector* nodes);
//  Result        Visit(ASTArrayType* node) override;
//  Result        Visit(ASTBoolType* node) override;
  Result        Visit(ASTClassTemplateInstance* node) override;
#if 0
  Result        Visit(ASTFloatingPointType* node) override;
  Result        Visit(ASTFormalTemplateArg* node) override;
  Result        Visit(ASTIntegerType* node) override;
  Result        Visit(ASTLegacyType* node) override;
  Result        Visit(ASTMatrixType* node) override;
  Result        Visit(ASTQualifiedType* node) override;
  Result        Visit(ASTRawPtrType* node) override;
  Result        Visit(ASTScopedType* node) override;
  Result        Visit(ASTStrongPtrType* node) override;
  Result        Visit(ASTVectorType* node) override;
  Result        Visit(ASTWeakPtrType* node) override;
  Result        Visit(Arg* node) override;
  Result        Visit(ArgList* node) override;
  Result        Visit(ArrayAccess* node) override;
  Result        Visit(BinOpNode* node) override;
  Result        Visit(BoolConstant* constant) override;
  Result        Visit(CastExpr* expr) override;
  Result        Visit(Data* node) override;
  Result        Visit(UnresolvedClassDefinition* defn) override;
  Result        Visit(Decls* decls) override;
  Result        Visit(DoStatement* stmt) override;
  Result        Visit(DoubleConstant* constant) override;
  Result        Visit(EnumConstant* node) override;
  Result        Visit(ExprList* node) override;
  Result        Visit(ExprStmt* exprStmt) override;
  Result        Visit(ExprWithStmt* node) override;
  Result        Visit(ExtractElementExpr* node) override;
  Result        Visit(FieldAccess* node) override;
  Result        Visit(FloatConstant* constant) override;
  Result        Visit(ForStatement* forStmt) override;
  Result        Visit(HeapAllocation* node) override;
  Result        Visit(IfStatement* stmt) override;
  Result        Visit(IncDecExpr* node) override;
  Result        Visit(Initializer* node) override;
  Result        Visit(InsertElementExpr* node) override;
  Result        Visit(IntConstant* constant) override;
  Result        Visit(MethodCall* node) override;
  Result        Visit(UnresolvedNewExpr* node) override;
  Result        Visit(NullConstant* constant) override;
  Result        Visit(ReturnStatement* stmt) override;
  Result        Visit(LoadExpr* node) override;
  Result        Visit(RawToSmartPtr* node) override;
  Result        Visit(SliceExpr* node) override;
  Result        Visit(SmartToRawPtr* node) override;
  Result        Visit(Stmts* stmts) override;
  Result        Visit(StoreStmt* node) override;
  Result        Visit(SwizzleExpr* node) override;
  Result        Visit(TempVarExpr* node) override;
  Result        Visit(UIntConstant* constant) override;
  Result        Visit(UnaryOp* node) override;
  Result        Visit(DestroyStmt* node) override;
  Result        Visit(UnresolvedInitializer* node) override;
  Result        Visit(UnresolvedDot* node) override;
  Result        Visit(UnresolvedIdentifier* node) override;
  Result        Visit(UnresolvedListExpr* node) override;
  Result        Visit(UnresolvedMethodCall* node) override;
  Result        Visit(UnresolvedStaticDot* node) override;
  Result        Visit(UnresolvedStaticMethodCall* node) override;
  Result        Visit(VarDeclaration* decl) override;
  Result        Visit(WhileStatement* stmt) override;
  Result        Visit(VarExpr* node) override;
  Result        Visit(ZeroInitStmt* node) override;
#endif
};

};  // namespace Toucan
#endif
