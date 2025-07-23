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

#include <ast/native_class.h>

namespace Toucan {

APIValidationPass::APIValidationPass(NodeVector* nodes, TypeTable* types)
    : nodes_(nodes), types_(types) {}

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

void APIValidationPass::ValidateRenderPipelineField(Type* type) {
  // Must be one of:
  // *VertexInput<T>
  // *index Buffer<T>
  // *ColorAttachment<T>
  // *DepthStencilAttachment<T>
  // *BindGroup<T>
}

void APIValidationPass::ValidateRenderPipeline(ClassType* renderPipeline) {
  auto templateArgs = renderPipeline->GetTemplateArgs();
  assert(templateArgs.size() == 1);
  if (!templateArgs[0]->IsClass()) {
    Error("RenderPipeline template argument must be of class type");
    return;
  }
  auto classType = static_cast<ClassType*>(templateArgs[0]);
  for (const auto& field : classType->GetFields()) {
    ValidateRenderPipelineField(field->type);
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
  return numErrors_;
}

void APIValidationPass::Error(const char* str) {
  fprintf(stderr, "%s\n", str);
  numErrors_++;
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
  Error(node, "Internal compiler error");
  return {};
}

Result APIValidationPass::Resolve(ASTNode* node) { return node->Accept(this); }

void APIValidationPass::Error(ASTNode* node, const char* fmt, ...) {
  const FileLocation& location = node->GetFileLocation();
  std::string         filename =
      location.filename ? std::filesystem::path(*location.filename).filename().string() : "";
  va_list argp;
  va_start(argp, fmt);
  fprintf(stderr, "%s:%d:  ", filename.c_str(), location.lineNum);
  vfprintf(stderr, fmt, argp);
  fprintf(stderr, "\n");
  numErrors_++;
}

};  // namespace Toucan
