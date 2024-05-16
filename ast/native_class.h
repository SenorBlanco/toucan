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

#ifndef NATIVE_CLASS_H_
#define NATIVE_CLASS_H_
#endif

// TODO: autogenerate this from api.t.

namespace Toucan {

class ClassType;

class NativeClass {
 public:
  static ClassType* BindGroup;
  static ClassType* Buffer;
  static ClassType* ColorAttachment;
  static ClassType* CommandBuffer;
  static ClassType* CommandEncoder;
  static ClassType* ComputeBuiltins;
  static ClassType* ComputePass;
  static ClassType* ComputePipeline;
  static ClassType* DepthStencilAttachment;
  static ClassType* DepthStencilState;
  static ClassType* Device;
  static ClassType* Event;
  static ClassType* FragmentBuiltins;
  static ClassType* ImageDecoder;
  static ClassType* Math;
  static ClassType* Queue;
  static ClassType* RenderPass;
  static ClassType* RenderPipeline;
  static ClassType* SampleableTexture1D;
  static ClassType* SampleableTexture2D;
  static ClassType* SampleableTexture2DArray;
  static ClassType* SampleableTexture3D;
  static ClassType* SampleableTextureCube;
  static ClassType* Sampler;
  static ClassType* SwapChain;
  static ClassType* System;
  static ClassType* Texture1D;
  static ClassType* Texture2D;
  static ClassType* Texture2DArray;
  static ClassType* Texture3D;
  static ClassType* TextureCube;
  static ClassType* VertexBuiltins;
  static ClassType* Window;

  static ClassType* PixelFormat;

  static ClassType* R8unorm;
  static ClassType* R8snorm;
  static ClassType* R8uint;
  static ClassType* R8sint;

  static ClassType* RG8unorm;
  static ClassType* RG8snorm;
  static ClassType* RG8uint;
  static ClassType* RG8sint;

  static ClassType* RGBA8unorm;
  static ClassType* RGBA8unormSRGB;
  static ClassType* RGBA8snorm;
  static ClassType* RGBA8uint;
  static ClassType* RGBA8sint;

  static ClassType* BGRA8unorm;
  static ClassType* BGRA8unormSRGB;

  static ClassType* R16uint;
  static ClassType* R16sint;
//  static ClassType* R16float;

  static ClassType* RG16uint;
  static ClassType* RG16sint;
//  static ClassType* RG16float;

  static ClassType* RGBA16uint;
  static ClassType* RGBA16sint;
//  static ClassType* class RGBA16float;

  static ClassType* R32uint;
  static ClassType* R32sint;
  static ClassType* R32float;

  static ClassType* RG32uint;
  static ClassType* RG32sint;
  static ClassType* RG32float;

  static ClassType* RGBA32uint;
  static ClassType* RGBA32sint;
  static ClassType* RGBA32float;

  static ClassType* RGB10A2unorm;
  static ClassType* RG11B10ufloat;

  static ClassType* Depth24Plus;

  static ClassType* PreferredSwapChainFormat;
};

};  // namespace Toucan
