
// Copyright 2025 The Toucan Authors
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

#include "constant_folder.h"

namespace Toucan {

ConstantFolder::ConstantFolder(TypeTable* types, void* data) : types_(types), data_(data) {
}

void ConstantFolder::Resolve(ASTNode* node) {
  node->Accept(this);
}

void ConstantFolder::Resolve(ASTNode* node, void* data) {
  auto prevData = data_;
  data_ = data;
  node->Accept(this);
  data_ = prevData;
}

Result ConstantFolder::Visit(CastExpr* node) {
  Type* srcType = node->GetExpr()->GetType(types_);
  Type* dstType = node->GetType(types_);
  // FIXME: refactor into "IsTransparentCast()"
  if (srcType->IsInt() && dstType->IsUInt() ||
      srcType->IsUInt() && dstType->IsInt() ||
      srcType->IsShort() && dstType->IsUShort() ||
      srcType->IsUShort() && dstType->IsShort() ||
      srcType->IsByte() && dstType->IsUByte() ||
      srcType->IsUByte() && dstType->IsByte()) {
    Resolve(node->GetExpr());
  } else {
    assert(false);
  }
  return {};
}

template <class T> Result ConstantFolder::Append(T value) {
  auto d = static_cast<T*>(data_);
  *d = value;
  d += sizeof(T);
  data_ = d;
  return {};
}

Result ConstantFolder::Visit(IntConstant* node) {
  return Append<int32_t>(node->GetValue());
}

Result ConstantFolder::Visit(UIntConstant* node) {
  return Append<uint32_t>(node->GetValue());
}

Result ConstantFolder::Visit(FloatConstant* node) {
  return Append<float>(node->GetValue());
}

Result ConstantFolder::Visit(DoubleConstant* node) {
  return Append<double>(node->GetValue());
}

Result ConstantFolder::Visit(BoolConstant* node) {
  return Append<bool>(node->GetValue());
}

Result ConstantFolder::Visit(Initializer* node) {
  Resolve(node->GetArgList());
  return {};
}

template <class T> void ConstantFolder::IntegralBinOp(void* lhs, void* rhs, BinOpNode::Op op) {
  auto l = *static_cast<T*>(lhs);
  auto r = *static_cast<T*>(rhs);
  switch (op) {
    case BinOpNode::ADD:           Append<T>(l + r);
    case BinOpNode::SUB:           Append<T>(l - r);
    case BinOpNode::MUL:           Append<T>(l * r);
    case BinOpNode::DIV:           Append<T>(l / r);
    case BinOpNode::MOD:           Append<T>(l % r);
    case BinOpNode::LT:            Append<T>(l < r);
    case BinOpNode::LE:            Append<T>(l <= r);
    case BinOpNode::EQ:            Append<T>(l == r);
    case BinOpNode::GE:            Append<T>(l >= r);
    case BinOpNode::GT:            Append<T>(l > r);
    case BinOpNode::NE:            Append<T>(l != r);
    case BinOpNode::LOGICAL_AND:   Append<T>(l && r);
    case BinOpNode::BITWISE_AND:   Append<T>(l & r);
    case BinOpNode::LOGICAL_OR:    Append<T>(l || r);
    case BinOpNode::BITWISE_OR:    Append<T>(l | r);
    case BinOpNode::BITWISE_XOR:   Append<T>(l ^ r);
    default: assert(false);
  }
}

template <class T> void ConstantFolder::FloatingPointBinOp(void* lhs, void* rhs, BinOpNode::Op op) {
  auto l = *static_cast<T*>(lhs);
  auto r = *static_cast<T*>(rhs);
  switch (op) {
    case BinOpNode::ADD:           Append<T>(l + r);
    case BinOpNode::SUB:           Append<T>(l - r);
    case BinOpNode::MUL:           Append<T>(l * r);
    case BinOpNode::DIV:           Append<T>(l / r);
    case BinOpNode::LT:            Append<T>(l < r);
    case BinOpNode::LE:            Append<T>(l <= r);
    case BinOpNode::EQ:            Append<T>(l == r);
    case BinOpNode::GE:            Append<T>(l >= r);
    case BinOpNode::GT:            Append<T>(l > r);
    case BinOpNode::NE:            Append<T>(l != r);
    default: assert(false);
  }
}

Result ConstantFolder::Visit(BinOpNode* node) {
  auto lhsType = node->GetLHS()->GetType(types_);
  auto rhsType = node->GetLHS()->GetType(types_);
  std::vector<char> lhs(lhsType->GetSizeInBytes());
  std::vector<char> rhs(rhsType->GetSizeInBytes());
  auto l = lhs.data();
  auto r = rhs.data();
  Resolve(node->GetLHS(), l);
  Resolve(node->GetRHS(), r);
  if (lhsType->IsInt()) {
    IntegralBinOp<int32_t>(l, r, node->GetOp());
  } else if (lhsType->IsUInt()) {
    IntegralBinOp<uint32_t>(l, r, node->GetOp());
  } else if (lhsType->IsShort()) {
    IntegralBinOp<int16_t>(l, r, node->GetOp());
  } else if (lhsType->IsUShort()) {
    IntegralBinOp<uint16_t>(l, r, node->GetOp());
  } else if (lhsType->IsByte()) {
    IntegralBinOp<int8_t>(l, r, node->GetOp());
  } else if (lhsType->IsUByte()) {
    IntegralBinOp<uint8_t>(l, r, node->GetOp());
  } else if (lhsType->IsFloat()) {
    FloatingPointBinOp<float>(l, r, node->GetOp());
  } else if (lhsType->IsDouble()) {
    FloatingPointBinOp<double>(l, r, node->GetOp());
  } else {
    assert(false);
  }
  return {};
}

template<class T> void ConstantFolder::IntegralUnaryOp() {
  auto l = *static_cast<T*>(lhs);
  switch (op) {
    case UnaryOp::Op::Minus:       Append<T>(-r);
    case UnaryOp::Op::Negate:      Append<T>(!r);
    default: assert(false);
  }
}

Result ConstantFolder::Visit(UnaryOp* node) {
  auto type = node->GetRHS()->GetType(types_);
  std::vector<char> rhs(rhsType->GetSizeInBytes());
  auto r = rhs.data();
  Resolve(node->GetRHS(), r);
  if (lhsType->IsInt()) {
    IntegralUnaryOp<int32_t>(r, node->GetOp());
  } else if (lhsType->IsUInt()) {
    IntegralUnaryOp<uint32_t>(r, node->GetOp());
  } else if (lhsType->IsShort()) {
    IntegralUnaryOp<int16_t>(r, node->GetOp());
  } else if (lhsType->IsUShort()) {
    IntegralUnaryOp<uint16_t>(r, node->GetOp());
  } else if (lhsType->IsByte()) {
    IntegralUnaryOp<int8_t>(r, node->GetOp());
  } else if (lhsType->IsUByte()) {
    IntegralUnaryOp<uint8_t>(r, node->GetOp());
  } else if (lhsType->IsFloat()) {
    FloatingPointUnaryOp<float>(r, node->GetOp());
  } else if (lhsType->IsDouble()) {
    FloatingPointUnaryOp<double>(r, node->GetOp());
  } else {
    assert(false);
  }
  return {};
}

Result ConstantFolder::Visit(ExprList* node) {
  char* d = static_cast<char*>(data_);
  for (auto expr : node->Get()) {
    Resolve(expr);
  }
  return {};
}

Result ConstantFolder::Default(ASTNode* node) {
  assert(!"that node is not implemented");
  return {};
}

};  // namespace Toucan
