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

#include "native_class.h"

#include "type.h"

namespace Toucan {

ClassType* NativeClass::BindGroup;
ClassType* NativeClass::Buffer;
ClassType* NativeClass::ColorAttachment;
ClassType* NativeClass::CommandBuffer;
ClassType* NativeClass::CommandEncoder;
ClassType* NativeClass::ComputeBuiltins;
ClassType* NativeClass::ComputePass;
ClassType* NativeClass::ComputePipeline;
ClassType* NativeClass::DepthStencilAttachment;
ClassType* NativeClass::Device;
ClassType* NativeClass::DepthStencilState;
ClassType* NativeClass::Event;
ClassType* NativeClass::FragmentBuiltins;
ClassType* NativeClass::ImageDecoder;
ClassType* NativeClass::Math;
ClassType* NativeClass::Queue;
ClassType* NativeClass::RenderPass;
ClassType* NativeClass::RenderPipeline;
ClassType* NativeClass::SampleableTexture1D;
ClassType* NativeClass::SampleableTexture2D;
ClassType* NativeClass::SampleableTexture2DArray;
ClassType* NativeClass::SampleableTexture3D;
ClassType* NativeClass::SampleableTextureCube;
ClassType* NativeClass::Sampler;
ClassType* NativeClass::SwapChain;
ClassType* NativeClass::System;
ClassType* NativeClass::Texture1D;
ClassType* NativeClass::Texture2D;
ClassType* NativeClass::Texture2DArray;
ClassType* NativeClass::Texture3D;
ClassType* NativeClass::TextureCube;
ClassType* NativeClass::VertexBuiltins;
ClassType* NativeClass::Window;

ClassType* NativeClass::PixelFormat;

ClassType* NativeClass::R8unorm;
ClassType* NativeClass::R8snorm;
ClassType* NativeClass::R8uint;
ClassType* NativeClass::R8sint;

ClassType* NativeClass::RG8unorm;
ClassType* NativeClass::RG8snorm;
ClassType* NativeClass::RG8uint;
ClassType* NativeClass::RG8sint;

ClassType* NativeClass::RGBA8unorm;
ClassType* NativeClass::RGBA8unormSRGB;
ClassType* NativeClass::RGBA8snorm;
ClassType* NativeClass::RGBA8uint;
ClassType* NativeClass::RGBA8sint;

ClassType* NativeClass::BGRA8unorm;
ClassType* NativeClass::BGRA8unormSRGB;

ClassType* NativeClass::R16uint;
ClassType* NativeClass::R16sint;
//ClassType* NativeClass::R16float;

ClassType* NativeClass::RG16uint;
ClassType* NativeClass::RG16sint;
//ClassType* NativeClass::RG16float;

ClassType* NativeClass::RGBA16uint;
ClassType* NativeClass::RGBA16sint;
//ClassType* NativeClass::class RGBA16float;

ClassType* NativeClass::R32uint;
ClassType* NativeClass::R32sint;
ClassType* NativeClass::R32float;

ClassType* NativeClass::RG32uint;
ClassType* NativeClass::RG32sint;
ClassType* NativeClass::RG32float;

ClassType* NativeClass::RGBA32uint;
ClassType* NativeClass::RGBA32sint;
ClassType* NativeClass::RGBA32float;

ClassType* NativeClass::RGB10A2unorm;
ClassType* NativeClass::RG11B10ufloat;

ClassType* NativeClass::Depth24Plus;

ClassType* NativeClass::PreferredSwapChainFormat;

}  // namespace Toucan
