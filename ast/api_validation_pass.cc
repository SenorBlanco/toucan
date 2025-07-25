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

#include "api_validation_pass.h"

#include <filesystem>
#include <stdarg.h>

#include "native_class.h"
#include "shader_validation_pass.h"

namespace Toucan {

APIValidationPass::APIValidationPass(TypeTable* types)
    : types_(types), numErrors_(0) {}

int APIValidationPass::Run() {
  for (auto type : types_->GetTypes()) {
    if (!type->IsClass() || !type->IsFullySpecified()) continue;

    auto classType = static_cast<ClassType*>(type);
    auto classTemplate = classType->GetTemplate();
    if (!classTemplate) continue;

    if (classTemplate == NativeClass::Buffer) {
      ValidateBuffer(classType);
    } else if (classTemplate == NativeClass::BindGroup) {
      ValidateBindGroup(classType);
    } else if (classTemplate == NativeClass::RenderPipeline) {
      ValidateRenderPipeline(classType);
    } else if (classTemplate == NativeClass::RenderPass) {
      ValidateRenderPipelineFields(classType);
    } else if (classTemplate == NativeClass::ComputePipeline) {
      ValidateComputePipeline(classType);
    } else if (classTemplate == NativeClass::ComputePass) {
      ValidateComputePipelineFields(classType);
    }
  }

  return numErrors_;
}

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

bool APIValidationPass::ValidateComputePipelineField(Type* type) {
  if (!type->IsStrongPtr()) return false;

  type = static_cast<StrongPtrType*>(type)->GetBaseType();
  int qualifiers;
  type = type->GetUnqualifiedType(&qualifiers);
  if (!type->IsClass()) return false;
  auto classType = static_cast<ClassType*>(type);
  auto templ = classType->GetTemplate();
  if (templ == NativeClass::BindGroup) return true; // FIXME check bind group
  return false;
}

void APIValidationPass::ValidateRenderPipelineFields(ClassType* renderPipeline) {
  auto pipelineClass = static_cast<ClassType*>(renderPipeline->GetTemplateArgs()[0]);
  for (const auto& field : pipelineClass->GetFields()) {
    if (!ValidateRenderPipelineField(field->type)) {
      Error(renderPipeline, "%s is not a valid render pipeline field type", field->type->ToString().c_str());
    }
  }
}

void APIValidationPass::ValidateComputePipelineFields(ClassType* computePipeline) {
  auto pipelineClass = static_cast<ClassType*>(computePipeline->GetTemplateArgs()[0]);
  for (const auto& field : pipelineClass->GetFields()) {
    if (!ValidateComputePipelineField(field->type)) {
      Error(computePipeline, "%s is not a valid compute pipeline field type", field->type->ToString().c_str());
    }
  }
}

void APIValidationPass::ValidateRenderPipeline(ClassType* renderPipeline) {
  ValidateRenderPipelineFields(renderPipeline);
  Method* vertexShader = nullptr;
  Method* fragmentShader = nullptr;
  auto pipelineClass = static_cast<ClassType*>(renderPipeline->GetTemplateArgs()[0]);
  for (ClassType* c = pipelineClass; c != nullptr && (!vertexShader || !fragmentShader);
       c = c->GetParent()) {
    for (auto& method : c->GetMethods()) {
      if (method->modifiers & Method::Modifier::Vertex) {
        if (!vertexShader) vertexShader = method.get();
      } else if (method->modifiers & Method::Modifier::Fragment) {
        if (!fragmentShader) fragmentShader = method.get();
      }
    }
  }
  if (!vertexShader) Error(renderPipeline, "no vertex shader found");
  if (!fragmentShader) Error(renderPipeline, "no fragment shader found");

  ShaderValidationPass shaderValidationPass;
  if (vertexShader) {
    shaderValidationPass.Run(vertexShader);
    numErrors_ += shaderValidationPass.GetNumErrors();
  }
  if (fragmentShader) {
    shaderValidationPass.Run(fragmentShader);
    numErrors_ += shaderValidationPass.GetNumErrors();
  }
}

void APIValidationPass::ValidateComputePipeline(ClassType* computePipeline) {
  ValidateComputePipelineFields(computePipeline);
  Method* shader = nullptr;
  auto pipelineClass = static_cast<ClassType*>(computePipeline->GetTemplateArgs()[0]);
  for (ClassType* c = pipelineClass; c != nullptr && !shader; c = c->GetParent()) {
    for (auto& method : c->GetMethods()) {
      if (method->modifiers & Method::Modifier::Compute) {
        shader = method.get();
      }
    }
  }
  if (!shader) {
    Error(computePipeline, "no compute shader found");
    return;
  }

  ShaderValidationPass shaderValidationPass;
  shaderValidationPass.Run(shader);
  numErrors_ += shaderValidationPass.GetNumErrors();
}

void APIValidationPass::Error(ClassType* instance, const char* fmt, ...) {
  const FileLocation& location = instance->GetFileLocation();
  std::string         filename = location.filename
                                     ? std::filesystem::path(*location.filename).filename().string()
                                     : "";
  va_list             argp;
  va_start(argp, fmt);
  fprintf(stderr, "%s:%d:  while instantiating %s: ", filename.c_str(), location.lineNum, instance->ToString().c_str());
  vfprintf(stderr, fmt, argp);
  fprintf(stderr, "\n");
  numErrors_++;
}

};  // namespace Toucan
