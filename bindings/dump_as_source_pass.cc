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

#include "dump_as_source_pass.h"
#include "bindings/gen_bindings.h"

#include <stdarg.h>

#include "ast/symbol.h"

namespace Toucan {

DumpAsSourcePass::DumpAsSourcePass(std::ostream& file, GenBindings* genBindings)
    : file_(file), genBindings_(genBindings) {
  map_[nullptr] = 0;
}

int DumpAsSourcePass::Resolve(ASTNode* node) {
  if (!map_[node]) { node->Accept(this); }
  return map_[node];
}

int DumpAsSourcePass::Output(ASTNode* node) {
  file_ << "  nodeList[" << nodeCount_ << "] = nodes->";
  map_[node] = nodeCount_;
  return nodeCount_++;
}

Result DumpAsSourcePass::Visit(ArgList* node) {
  // For now, support only empty ArgList.
  assert(node->GetArgs().size() == 0);
  Output(node);
  file_ << "Make<ArgList>();\n";
  return {};
}

Result DumpAsSourcePass::Visit(ArrayAccess* node) {
  int expr = Resolve(node->GetExpr());
  int index = Resolve(node->GetIndex());
  Output(node);
  file_ << "Make<ArrayAccess>(nodeList[" << expr << "], nodeList[" << index << "]);\n";
  return {};
}

Result DumpAsSourcePass::Visit(CastExpr* node) {
  int type = genBindings_->GenType(node->GetType());
  int expr = Resolve(node->GetExpr());
  Output(node);
  file_ << "Make<CastExpr>(type" << type << ", exprs[" << expr << "]);\n";
  return {};
}

Result DumpAsSourcePass::Visit(IntConstant* node) {
  Output(node);
  file_ << "Make<IntConstant>(" << node->GetValue() << ", " << node->GetBits() << ");\n";
  return {};
}

Result DumpAsSourcePass::Visit(UIntConstant* node) {
  Output(node);
  file_ << "Make<UIntConstant>(" << node->GetValue() << ", " << node->GetBits() << ");\n";
  return {};
}

Result DumpAsSourcePass::Visit(EnumConstant* node) {
  const EnumValue* value = node->GetValue();
  int type = genBindings_->GenType(value->type);
  Output(node);
  file_ << "Make<EnumConstant>(static_cast<EnumType*>(type" << type << ")->FindValue(\"" 
          << value->id << "\"));\n";
  return {};
}

Result DumpAsSourcePass::Visit(FloatConstant* node) {
  Output(node);
  file_ << "Make<FloatConstant>(" << node->GetValue() << ");\n";
  return {};
}

Result DumpAsSourcePass::Visit(DoubleConstant* node) {
  Output(node);
  file_ << "Make<DoubleConstant>(" << node->GetValue() << ");\n";
  return {};
}

Result DumpAsSourcePass::Visit(BoolConstant* node) {
  Output(node);
  file_ << "Make<BoolConstant>(" << (node->GetValue() ? "true" : "false") << ");\n";
  return {};
}

Result DumpAsSourcePass::Visit(NullConstant* node) {
  Output(node);
  file_ << "Make<NullConstant>();\n";
  return {};
}

Result DumpAsSourcePass::Visit(Stmts* stmts) {
  int id = Output(stmts);
  file_ << "Make<Stmts>();\n";

  if (stmts->GetScope()) {
    file_ << "  stmtss[" << id << "]->SetScope(symbols->PushNewScope());\n";
  }
  // FIXME: create an actual Stmts from elements
  for (Stmt* const& it : stmts->GetStmts()) {
    auto stmtsID = Resolve(it);
    file_ << "  stmtss[" << id << "]->Append(stmts[" << stmtsID << "]);\n";
  }
  if (stmts->GetScope()) { file_ << "  symbols->PopScope();\n"; }
  return {};
}

Result DumpAsSourcePass::Visit(ExprList* a) {
  int id = Output(a);
  file_ << "Make<ExprList>();\n";
  for (auto expr : a->Get()) {
    int exprID = Resolve(expr);
    file_ << "  exprLists[" << id << "]->Append(exprs[" << exprID << "]);\n";
  }
  return {};
}

Result DumpAsSourcePass::Visit(ExprStmt* stmt) {
  Output(stmt);
  int id = Resolve(stmt->GetExpr());
  file_ << "Make<ExprStmt>(exprs[" << id << "]);\n";
  return {};
}

Result DumpAsSourcePass::Visit(Initializer* node) {
  int type = genBindings_->GenType(node->GetType());
  int argList = Resolve(node->GetArgList());
  Output(node);
  file_ << "Make<Initializer>(type" << type << ", exprLists[" << argList << "]);\n";
  return {};
}

Result DumpAsSourcePass::Visit(VarDeclaration* decl) {
  int type = genBindings_->GenType(decl->GetType());
  int initExpr = Resolve(decl->GetInitExpr());
  Output(decl);
  file_ << "Make<VarDeclaration>(\"" << decl->GetID() << "\", type" << type << ", exprs["
          << initExpr <<  "]);\n";
  return {};
}

Result DumpAsSourcePass::Visit(LoadExpr* node) {
  int expr = Resolve(node->GetExpr());
  Output(node);
  file_ << "Make<LoadExpr>(exprs[" << expr << "]);\n";
  return {};
}

Result DumpAsSourcePass::Visit(StoreStmt* node) {
  int lhs = Resolve(node->GetLHS());
  int rhs = Resolve(node->GetRHS());
  Output(node);
  file_ << "Make<StoreStmt>(exprs[" << lhs << "], exprs[" << rhs << "]);\n";
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

Result DumpAsSourcePass::Visit(BinOpNode* node) {
  int lhs = Resolve(node->GetLHS());
  int rhs = Resolve(node->GetRHS());
  Output(node);
  file_ << "Make<BinOpNode>(BinOpNode::" << GetOp(node->GetOp()) << ", exprs[" << lhs
          << "], exprs[" << rhs << "]);\n";
  return {};
}


Result DumpAsSourcePass::Visit(UnresolvedListExpr* node) {
  int argList = Resolve(node->GetArgList());
  Output(node);
  file_ << "Make<UnresolvedListExpr>(argLists[" << argList << "]);\n";
  return {};
}

Result DumpAsSourcePass::Visit(ReturnStatement* stmt) {
  if (stmt->GetExpr()) {
    int expr = Resolve(stmt->GetExpr());
    Output(stmt);
    file_ << "Make<ReturnStatement>(exprs[" << expr << "]);\n";
  } else {
    Output(stmt);
    file_ << "Make<ReturnStatement>(nullptr);\n";
  }
  return {};
}

Result DumpAsSourcePass::Default(ASTNode* node) {
  assert(!"that node is not implemented");
  return {};
}

};  // namespace Toucan
