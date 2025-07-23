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

#include "native_class.h"
#include "semantic_pass.h"

namespace Toucan {

APIValidationPass::APIValidationPass(SemanticPass* semanticPass,
                                     NodeVector* nodes,
                                     TypeTable* types)
    : semanticPass_(semanticPass), nodes_(nodes), types_(types) {}

void APIValidationPass::ValidateDeviceClass(ClassType* classType) {
  // Must only contain (recursively) int, uint, float, vectors (<=4), arrays or classes of same.
}

void APIValidationPass::ValidateVertexAttribute(Type* type) {
  // For now, must be one of:
  // int, int<2>, int<3>, int<4>
  // uint, uint<2>, uint<3>, uint<4>
  // float, float<2>, float<3>, float<4>
}

void APIValidationPass::ValidateVertexClass(ClassType* classType) {
  // Each field must be valid vertex attribute
}

void APIValidationPass::ValidateBuffer(ClassType* classType) {
  // If has uniform qualifier, must be valid device-side class, with padded layout.
  // If has storage qualifier, must be valid device-side class.
  // If has vertex qualifier, must be unsized array of valid vertex class.
  // If has index qualifier, must be unsized array of uint or ushort.
  // Can only have hostreadable or hostwriteable, not both.
    // If has either, cannot have GPU-side qualifiers (uniform, storage, vertex, index).
  // Cannot have sampleable, renderable, readonly, writeonly, unfilterable, coherent.
}

void APIValidationPass::ValidateBindGroup(ClassType* classType) {
  // Each field must be one of:
  //
  // *Sampler
  // *[uniform | storage | readonly storage ] Buffer<T>
  // *SampleableTexture1D<T> for ValidSampleType(T)
  // *SampleableTexture2D<T> for ValidSampleType(T)
  // *SampleableTexture2DArray<T> for ValidSampleType(T)
  // *SampleableTexture3D<T> for ValidSampleType(T)
  // *SampleableTextureCube<T> for ValidSampleType(T)
}

bool APIValidationPass::ValidateRenderPipelineField(Type* type) {
  if (!type->IsStrongPtr()) return false;

  type = static_cast<StrongPtrType*>(type)->GetBaseType();
  int qualifiers;
  type = type->GetUnqualifiedType(&qualifiers);
  if (!type->IsClass()) return false;
  auto classType = static_cast<ClassType*>(type);
  auto templ = classType->GetTemplate();
  if (templ == NativeClass::VertexInput) return true;
  if (templ == NativeClass::Buffer) return qualifiers == Type::Qualifier::Index;
  if (templ == NativeClass::ColorAttachment) return true; // FIXME check PixelFormat
  if (templ == NativeClass::DepthStencilAttachment) return true; // Ibid.
  if (templ == NativeClass::BindGroup) return true; // FIXME check bind group
  return false;
}

void APIValidationPass::ValidateRenderPipeline(ClassType* renderPipeline) {
  auto templateArgs = renderPipeline->GetTemplateArgs();
  assert(templateArgs.size() == 1);
  assert(templateArgs[0]->IsClass());
  auto classType = static_cast<ClassType*>(templateArgs[0]);
  for (const auto& field : classType->GetFields()) {
    if (!ValidateRenderPipelineField(field->type)) {
      semanticPass_->Error("%s is not a valid pipeline field type", field->type->ToString().c_str());
    }
  }
  // Must have (or parent must have) fragment & vertex entry points.
  // All functions called from entry points must be valid device functions.
}

void APIValidationPass::ValidateComputePipeline(ClassType* classType) {
  // Must have (or parent must have) compute entry point.
  // Fields must be valid compute pipeline member variables (*BindGroup<T>).
  // All functions called from entry point must be valid device functxions.
}

int APIValidationPass::Run() {
  for (auto type : types_->GetTypes()) {
    if (type->IsClass() && type->IsFullySpecified()) {  // FIXME: remove fully specified when called from semantic pass
      ClassType* classType = static_cast<ClassType*>(type);
      auto classTemplate = classType->GetTemplate();
      auto templateArgs = classType->GetTemplateArgs();
      if (classTemplate == NativeClass::Buffer) {
        ValidateBuffer(classType);
      } else if (classTemplate == NativeClass::BindGroup) {
        ValidateBindGroup(classType);
      } else if (classTemplate == NativeClass::RenderPipeline ||
                 classTemplate == NativeClass::RenderPass) {
        ValidateRenderPipeline(classType);
      } else if (classTemplate == NativeClass::ComputePipeline ||
                 classTemplate == NativeClass::ComputePass) {
        ValidateComputePipeline(classType);
      }
    }
  }
  return semanticPass_->GetNumErrors();
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
  assert(!"unknown node type");
  return {};
}

Result APIValidationPass::Resolve(ASTNode* node) { return node->Accept(this); }

};  // namespace Toucan
