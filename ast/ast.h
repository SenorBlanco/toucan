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

#ifndef _AST_AST_H_
#define _AST_AST_H_

#include <assert.h>
#include <string>
#include <variant>
#include <vector>

#include "type.h"

namespace Toucan {

struct Var;
struct Scope;

class Visitor;

using Result = std::variant<void*, uint32_t>;

struct FileLocation {
  FileLocation();
  FileLocation(const FileLocation& other);
  FileLocation(std::shared_ptr<std::string> f, int n);
  std::shared_ptr<std::string> filename;
  int                          lineNum;
};

class ScopedFileLocation {
 public:
  ScopedFileLocation(FileLocation* p, const FileLocation& newLocation)
      : location_(p), previous_(*p) {
    *location_ = newLocation;
  }
  ~ScopedFileLocation() { *location_ = previous_; }

 private:
  FileLocation* location_;
  FileLocation  previous_;
};

class ASTNode {
 public:
  ASTNode();
  virtual ~ASTNode();
  virtual Result Accept(Visitor* visitor) = 0;
  void           SetFileLocation(const FileLocation& fileLocation) { fileLocation_ = fileLocation; }
  const FileLocation& GetFileLocation() const { return fileLocation_; }
  int                 GetLineNum() const { return fileLocation_.lineNum; }

 private:
  FileLocation fileLocation_;
};

class Expr : public ASTNode {
 public:
  Expr();
  virtual Type* GetType(TypeTable* types) = 0;
  virtual bool  IsArrayAccess() const { return false; }
  virtual bool  IsFieldAccess() const { return false; }
  virtual bool  IsUnresolvedSwizzleExpr() const { return false; }
  virtual bool  IsUnresolvedListExpr() const { return false; }
  virtual bool  IsIntConstant() const { return false; }
  virtual bool  IsVarExpr() const { return false; }
};

class Data : public Expr {
 public:
  Data(Type* type, std::unique_ptr<uint8_t[]> data, size_t size);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  void*  GetData() { return data_.get(); }
  size_t GetSize() const { return size_; }

 private:
  Type*                      type_;
  std::unique_ptr<uint8_t[]> data_;
  size_t                     size_;
};

class IntConstant : public Expr {
 public:
  IntConstant(int32_t value, uint32_t bits);
  Result   Accept(Visitor* visitor) override;
  Type*    GetType(TypeTable* types) override;
  bool     IsIntConstant() const override { return true; }
  int32_t  GetValue() const { return value_; }
  uint32_t GetBits() const { return bits_; }

 private:
  int32_t  value_;
  uint32_t bits_;
};

class UIntConstant : public Expr {
 public:
  UIntConstant(uint32_t value, uint32_t bits);
  Result   Accept(Visitor* visitor) override;
  Type*    GetType(TypeTable* types) override;
  uint32_t GetValue() const { return value_; }
  uint32_t GetBits() const { return bits_; }

 private:
  uint32_t value_;
  uint32_t bits_;
};

class FloatConstant : public Expr {
 public:
  FloatConstant(float value);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  float  GetValue() const { return value_; }

 private:
  float value_;
};

class DoubleConstant : public Expr {
 public:
  DoubleConstant(double value);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  double GetValue() const { return value_; }

 private:
  double value_;
};

class CastExpr : public Expr {
 public:
  CastExpr(Type* type, Expr* expr);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Type*  GetType() { return type_; }
  Expr*  GetExpr() { return expr_; }

 private:
  Type* type_;
  Expr* expr_;
};

class BoolConstant : public Expr {
 public:
  BoolConstant(bool value);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  bool   GetValue() { return value_; }

 private:
  bool value_;
};

class EnumConstant : public Expr {
 public:
  EnumConstant(const EnumValue* value);
  Result           Accept(Visitor* visitor) override;
  Type*            GetType(TypeTable* types) override;
  const EnumValue* GetValue() { return value_; }

 private:
  const EnumValue* value_;
};

class NullConstant : public Expr {
 public:
  NullConstant();
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
};

class Arg : public ASTNode {
 public:
  Arg(std::string id, Expr* expr);
  Result      Accept(Visitor* visitor) override;
  std::string GetID() { return id_; }
  Expr*       GetExpr() { return expr_; }

 private:
  std::string id_;
  Expr*       expr_;
};

class ArgList : public ASTNode {
 public:
  ArgList();
  ArgList(std::vector<Arg*>&& args);
  Result                   Accept(Visitor* visitor) override;
  void                     Append(Arg* arg) { args_.push_back(arg); }
  const std::vector<Arg*>& GetArgs() { return args_; }
  bool                     IsNamed() const;

 private:
  std::vector<Arg*> args_;
};

class ExprList : public ASTNode {
 public:
  ExprList();
  explicit ExprList(std::vector<Expr*>&& exprs);
  Result                    Accept(Visitor* visitor) override;
  void                      Append(Expr* expr) { exprs_.push_back(expr); }
  const std::vector<Expr*>& Get() const { return exprs_; }

 private:
  std::vector<Expr*> exprs_;
};

class BinOpNode : public Expr {
 public:
  typedef enum {
    ADD,
    SUB,
    MUL,
    DIV,
    MOD,
    LT,
    LE,
    EQ,
    GE,
    GT,
    NE,
    LOGICAL_AND,
    LOGICAL_OR,
    BITWISE_AND,
    BITWISE_XOR,
    BITWISE_OR
  } Op;
  BinOpNode(Op op, Expr* lhs, Expr* rhs);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  bool   IsRelOp() const;
  Expr*  GetLHS() { return lhs_; }
  Expr*  GetRHS() { return rhs_; }
  Op     GetOp() { return op_; }

 private:
  Op    op_;
  Expr* lhs_;
  Expr* rhs_;
};

class Initializer : public Expr {
 public:
  Initializer(Type* type, ExprList* arglist);
  Result    Accept(Visitor* visitor) override;
  Type*     GetType(TypeTable* types) override { return type_; }
  Type*     GetType() { return type_; }
  ExprList* GetArgList() { return arglist_; }

 private:
  Type*     type_;
  ExprList* arglist_;
};

class UnresolvedInitializer : public Expr {
 public:
  UnresolvedInitializer(Type* type, ArgList* arglist, bool constructor);
  Result   Accept(Visitor* visitor) override;
  Type*    GetType(TypeTable* types) override { return type_; }
  Type*    GetType() { return type_; }
  ArgList* GetArgList() { return arglist_; }
  bool     IsConstructor() { return constructor_; }

 private:
  Type*    type_;
  ArgList* arglist_;
  bool     constructor_;
};

class UnresolvedListExpr : public Expr {
 public:
  UnresolvedListExpr(ArgList* arglist);
  Result   Accept(Visitor* visitor) override;
  Type*    GetType(TypeTable* types) override;
  ArgList* GetArgList() { return arglist_; }
  bool     IsUnresolvedListExpr() const override { return true; }

 private:
  ArgList* arglist_;
};

class ArrayAccess : public Expr {
 public:
  ArrayAccess(Expr* expr, Expr* index);
  Result Accept(Visitor* visitor) override;
  bool   IsArrayAccess() const override { return true; }
  Type*  GetType(TypeTable* types) override;
  Expr*  GetExpr() { return expr_; }
  Expr*  GetIndex() { return index_; }

 private:
  Expr* expr_;
  Expr* index_;
};

class UnresolvedDot : public Expr {
 public:
  UnresolvedDot(Expr* expr, std::string id);
  Result      Accept(Visitor* visitor) override;
  Type*       GetType(TypeTable* types) override { return nullptr; }
  Expr*       GetExpr() { return expr_; }
  std::string GetID() { return id_; }

 private:
  Expr*       expr_;
  std::string id_;
};

class UnresolvedIdentifier : public Expr {
 public:
  UnresolvedIdentifier(std::string id);
  Result      Accept(Visitor* visitor) override;
  Type*       GetType(TypeTable* types) override { return nullptr; }
  std::string GetID() { return id_; }

 private:
  std::string id_;
};

class UnresolvedMethodCall : public Expr {
 public:
  UnresolvedMethodCall(Expr* expr, std::string id, ArgList* arglist);
  Result      Accept(Visitor* visitor) override;
  Type*       GetType(TypeTable* types) override { return nullptr; }
  Expr*       GetExpr() { return expr_; }
  std::string GetID() { return id_; }
  ArgList*    GetArgList() { return arglist_; }

 private:
  Expr*       expr_;
  std::string id_;
  ArgList*    arglist_;
};

class UnresolvedStaticMethodCall : public Expr {
 public:
  UnresolvedStaticMethodCall(ClassType* classType, std::string id, ArgList* arglist);
  Result      Accept(Visitor* visitor) override;
  Type*       GetType(TypeTable* types) override { return nullptr; }
  ClassType*  classType() { return classType_; }
  std::string GetID() { return id_; }
  ArgList*    GetArgList() { return arglist_; }

 private:
  ClassType*  classType_;
  std::string id_;
  ArgList*    arglist_;
};

class MethodCall : public Expr {
 public:
  MethodCall(Method* method, ExprList* arglist);
  Result    Accept(Visitor* visitor) override;
  Type*     GetType(TypeTable* types) override { return method_->returnType; }
  Method*   GetMethod() { return method_; }
  ExprList* GetArgList() { return arglist_; }

 private:
  Method*   method_;
  ExprList* arglist_;
};

class LoadExpr : public Expr {
 public:
  LoadExpr(Expr* expr);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Expr*  GetExpr() const { return expr_; }

 private:
  Expr* expr_;
};

class VarExpr : public Expr {
 public:
  VarExpr(Var* var);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Var*   GetVar() const { return var_; }
  bool   IsVarExpr() const override { return true; }

 private:
  Var* var_;
};

class TempVarExpr : public Expr {
 public:
  TempVarExpr(Type* type, Expr* initExpr = nullptr);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Type*  GetType() const { return type_; }
  Expr*  GetInitExpr() const { return initExpr_; }

 private:
  Type* type_;
  Expr* initExpr_;
};

class SmartToRawPtr : public Expr {
 public:
  SmartToRawPtr(Expr* expr);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Expr*  GetExpr() { return expr_; }

 private:
  Expr* expr_;
};

class RawToWeakPtr : public Expr {
 public:
  RawToWeakPtr(Expr* expr);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Expr*  GetExpr() { return expr_; }

 private:
  Expr* expr_;
};

class FieldAccess : public Expr {
 public:
  FieldAccess(Expr* expr, Field* field);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Expr*  GetExpr() { return expr_; }
  Field* GetField() { return field_; }
  bool   IsFieldAccess() const override { return true; }

 private:
  Expr*  expr_;
  Field* field_;
};

class UnresolvedSwizzleExpr : public Expr {
 public:
  UnresolvedSwizzleExpr(Expr* expr, int index);
  Result        Accept(Visitor* visitor) override;
  virtual Type* GetType(TypeTable* types) override;
  virtual bool  IsUnresolvedSwizzleExpr() const override { return true; }
  Expr*         GetExpr() { return expr_; }
  int           GetIndex() { return index_; }

 private:
  Expr* expr_;
  int   index_;
};

class ExtractElementExpr : public Expr {
 public:
  ExtractElementExpr(Expr* expr, int index);
  Result        Accept(Visitor* visitor) override;
  virtual Type* GetType(TypeTable* types) override;
  Expr*         GetExpr() { return expr_; }
  int           GetIndex() { return index_; }

 private:
  Expr* expr_;
  int   index_;
};

class InsertElementExpr : public Expr {
 public:
  InsertElementExpr(Expr* expr, Expr* newElement, int index);
  Result        Accept(Visitor* visitor) override;
  virtual Type* GetType(TypeTable* types) override;
  Expr*         GetExpr() { return expr_; }
  Expr*         newElement() { return newElement_; }
  int           GetIndex() { return index_; }

 private:
  Expr* expr_;
  Expr* newElement_;
  int   index_;
};

class LengthExpr : public Expr {
 public:
  LengthExpr(Expr* expr);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Expr*  GetExpr() { return expr_; }

 private:
  Expr* expr_;
};

class Stmt : public ASTNode {
 public:
  virtual bool ContainsReturn() const { return false; }
};

class Stmts : public Stmt {
 public:
  Stmts();
  Result                    Accept(Visitor* visitor) override;
  void                      Append(Stmt* stmt) { stmts_.push_back(stmt); }
  void                      Prepend(Stmt* stmt) { stmts_.insert(stmts_.begin(), stmt); }
  Scope*                    GetScope() { return scope_; }
  void                      SetScope(Scope* scope) { scope_ = scope; }
  const std::vector<Stmt*>& GetStmts() { return stmts_; }
  void                      AppendVar(std::shared_ptr<Var> v);
  const VarVector&          GetVars() const { return vars_; }
  bool                      ContainsReturn() const override;

 private:
  std::vector<Stmt*> stmts_;
  Scope*             scope_;
  VarVector          vars_;
};

class ExprStmt : public Stmt {
 public:
  ExprStmt(Expr* expr);
  Result Accept(Visitor* visitor) override;
  Expr*  GetExpr() { return expr_; }

 private:
  Expr* expr_;
};

class ExprWithStmt : public Expr {
 public:
  ExprWithStmt(Expr* expr, Stmt* stmt);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Expr*  GetExpr() const { return expr_; }
  Stmt*  GetStmt() const { return stmt_; }

 private:
  Expr* expr_;
  Stmt* stmt_;
};

class StoreStmt : public Stmt {
 public:
  StoreStmt(Expr* lhs, Expr* rhs);
  Result Accept(Visitor* visitor) override;
  Expr*  GetLHS() { return lhs_; }
  Expr*  GetRHS() { return rhs_; }

 private:
  Expr* lhs_;
  Expr* rhs_;
};

class DestroyStmt : public Stmt {
 public:
  DestroyStmt(Expr* expr);
  Result Accept(Visitor* visitor) override;
  Expr*  GetExpr() const { return expr_; }

 private:
  Expr*     expr_;
};

class IncDecExpr : public Expr {
 public:
  enum class Op { Inc, Dec };
  IncDecExpr(Op op, Expr* addr, bool returnOrigValue);
  Type*  GetType(TypeTable* types) override;
  Result Accept(Visitor* visitor) override;
  Op     GetOp() const { return op_; }
  Expr*  GetExpr() { return expr_; }
  bool   returnOrigValue() { return returnOrigValue_; }

 private:
  Op    op_;
  Expr* expr_;
  bool  returnOrigValue_;
};

class ZeroInitStmt : public Stmt {
 public:
  ZeroInitStmt(Expr* lhs);
  Result Accept(Visitor* visitor) override;
  Expr*  GetLHS() { return lhs_; }

 private:
  Expr* lhs_;
};

class VarDeclaration : public Stmt {
 public:
  VarDeclaration(std::string id, Type* type, Expr* initExpr);
  Result      Accept(Visitor* visitor) override;
  Type*       GetType() { return type_; }
  std::string GetID() { return id_; }
  Expr*       GetInitExpr() { return initExpr_; }
  void        SetType(Type* type) { type_ = type; }

 private:
  Type*       type_;
  std::string id_;
  Expr*       initExpr_;
};

class IfStatement : public Stmt {
 public:
  IfStatement(Expr* expr, Stmt* stmt, Stmt* optElse);
  Result Accept(Visitor* visitor) override;
  Expr*  GetExpr() { return expr_; }
  Stmt*  GetStmt() { return stmt_; }
  Stmt*  GetOptElse() { return optElse_; }

 private:
  Expr* expr_;
  Stmt* stmt_;
  Stmt* optElse_;
};

class WhileStatement : public Stmt {
 public:
  WhileStatement(Expr* cond, Stmt* body);
  Result Accept(Visitor* visitor) override;
  Expr*  GetCond() { return cond_; }
  Stmt*  GetBody() { return body_; }

 private:
  Expr* cond_;
  Stmt* body_;
};

class DoStatement : public Stmt {
 public:
  DoStatement(Stmt* stmt, Expr* expr);
  Result Accept(Visitor* visitor) override;
  Stmt*  GetBody() { return body_; }
  Expr*  GetCond() { return cond_; }

 private:
  Stmt* body_;
  Expr* cond_;
};

class ForStatement : public Stmt {
 public:
  ForStatement(Stmt* initStmt, Expr* cond, Stmt* loopStmt, Stmt* body);
  Result Accept(Visitor* visitor) override;
  Stmt*  GetInitStmt() { return initStmt_; }
  Expr*  GetCond() { return cond_; }
  Stmt*  GetLoopStmt() { return loopStmt_; }
  Stmt*  GetBody() { return body_; }

 private:
  Stmt* initStmt_;
  Expr* cond_;
  Stmt* loopStmt_;
  Stmt* body_;
};

class ReturnStatement : public Stmt {
 public:
  ReturnStatement(Expr* expr);
  Result Accept(Visitor* visitor) override;
  bool   ContainsReturn() const override { return true; }
  Expr*  GetExpr() { return expr_; }

 private:
  Expr*  expr_;
};

class NewArrayExpr : public Expr {
 public:
  NewArrayExpr(Type* type, Expr* sizeExpr);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Type*  GetElementType() { return elementType_; }
  Expr*  GetSizeExpr() { return sizeExpr_; }

 private:
  Type* elementType_;
  Expr* sizeExpr_;
};

class UnresolvedNewExpr : public Expr {
 public:
  UnresolvedNewExpr(Type* type, Expr* length, ArgList* arglist);
  Result   Accept(Visitor* visitor) override;
  Type*    GetType(TypeTable* types) override;
  Type*    GetType() { return type_; }
  Expr*    GetLength() { return length_; }
  ArgList* GetArgList() { return arglist_; }

 private:
  Type*    type_;
  Expr*    length_;  // used for unsized arrays as last field
  ArgList* arglist_;
};

class NewExpr : public Expr {
 public:
  NewExpr(Type* type, Expr* length, Method* constructor, ExprList* args);
  Result    Accept(Visitor* visitor) override;
  Type*     GetType(TypeTable* types) override;
  Type*     GetType() { return type_; }
  Expr*     GetLength() { return length_; }
  Method*   GetConstructor() { return constructor_; }
  ExprList* GetArgs() { return args_; }

 private:
  Type*     type_;
  Expr*     length_;  // used for unsized arrays as last field
  Method*   constructor_;
  ExprList* args_;
};

class UnresolvedClassDefinition : public Stmt {
 public:
  UnresolvedClassDefinition(Scope* scope);
  Result Accept(Visitor* visitor) override;
  Scope* GetScope() { return scope_; }

 private:
  Scope* scope_;
};

class UnaryOp : public Expr {
 public:
  enum class Op { Minus, Negate };
  UnaryOp(Op op, Expr* rhs);
  Result Accept(Visitor* visitor) override;
  Type*  GetType(TypeTable* types) override;
  Op     GetOp() { return op_; }
  Expr*  GetRHS() { return rhs_; }

 private:
  Expr* rhs_;
  Op    op_;
};

class NodeVector {
 public:
  NodeVector();
  template <typename T, typename... ARGS>
  T* Make(ARGS&&... args) {
    T* node = new T(std::forward<ARGS>(args)...);
    nodes_.push_back(std::unique_ptr<ASTNode>(node));
    return node;
  }

 private:
  std::vector<std::unique_ptr<ASTNode>> nodes_;
};

class Visitor {
 public:
  virtual Result Visit(Arg* node) { return Default(node); }
  virtual Result Visit(ArgList* node) { return Default(node); }
  virtual Result Visit(ArrayAccess* node) { return Default(node); }
  virtual Result Visit(BinOpNode* node) { return Default(node); }
  virtual Result Visit(BoolConstant* node) { return Default(node); }
  virtual Result Visit(CastExpr* node) { return Default(node); }
  virtual Result Visit(Data* node) { return Default(node); }
  virtual Result Visit(EnumConstant* node) { return Default(node); }
  virtual Result Visit(SmartToRawPtr* node) { return Default(node); }
  virtual Result Visit(DoStatement* node) { return Default(node); }
  virtual Result Visit(DoubleConstant* node) { return Default(node); }
  virtual Result Visit(ExprList* node) { return Default(node); }
  virtual Result Visit(ExprStmt* node) { return Default(node); }
  virtual Result Visit(ExprWithStmt* node) { return Default(node); }
  virtual Result Visit(ExtractElementExpr* node) { return Default(node); }
  virtual Result Visit(FieldAccess* node) { return Default(node); }
  virtual Result Visit(FloatConstant* node) { return Default(node); }
  virtual Result Visit(ForStatement* node) { return Default(node); }
  virtual Result Visit(IfStatement* node) { return Default(node); }
  virtual Result Visit(Initializer* node) { return Default(node); }
  virtual Result Visit(InsertElementExpr* node) { return Default(node); }
  virtual Result Visit(IntConstant* node) { return Default(node); }
  virtual Result Visit(UIntConstant* node) { return Default(node); }
  virtual Result Visit(LengthExpr* node) { return Default(node); }
  virtual Result Visit(NewArrayExpr* node) { return Default(node); }
  virtual Result Visit(NewExpr* node) { return Default(node); }
  virtual Result Visit(NullConstant* node) { return Default(node); }
  virtual Result Visit(RawToWeakPtr* node) { return Default(node); }
  virtual Result Visit(ReturnStatement* node) { return Default(node); }
  virtual Result Visit(MethodCall* node) { return Default(node); }
  virtual Result Visit(Stmts* node) { return Default(node); }
  virtual Result Visit(TempVarExpr* node) { return Default(node); }
  virtual Result Visit(UnaryOp* node) { return Default(node); }
  virtual Result Visit(DestroyStmt* node) { return Default(node); }
  virtual Result Visit(UnresolvedInitializer* node) { return Default(node); }
  virtual Result Visit(UnresolvedDot* node) { return Default(node); }
  virtual Result Visit(UnresolvedIdentifier* node) { return Default(node); }
  virtual Result Visit(UnresolvedListExpr* node) { return Default(node); }
  virtual Result Visit(UnresolvedClassDefinition* node) { return Default(node); }
  virtual Result Visit(UnresolvedNewExpr* node) { return Default(node); }
  virtual Result Visit(UnresolvedMethodCall* node) { return Default(node); }
  virtual Result Visit(UnresolvedStaticMethodCall* node) { return Default(node); }
  virtual Result Visit(UnresolvedSwizzleExpr* node) { return Default(node); }
  virtual Result Visit(VarDeclaration* node) { return Default(node); }
  virtual Result Visit(VarExpr* node) { return Default(node); }
  virtual Result Visit(LoadExpr* node) { return Default(node); }
  virtual Result Visit(StoreStmt* node) { return Default(node); }
  virtual Result Visit(ZeroInitStmt* node) { return Default(node); }
  virtual Result Visit(IncDecExpr* node) { return Default(node); }
  virtual Result Visit(WhileStatement* node) { return Default(node); }
  virtual Result Default(ASTNode* node) = 0;
};

};  // namespace Toucan
#endif  // _AST_AST_H_
