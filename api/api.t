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

enum PrimitiveTopology {
  PointList, LineList, LineStrip, TriangleList, TriangleStrip
}

enum FrontFace { CCW, CW }

enum CullMode { None, Front, Back }

class CommandBuffer {
 ~CommandBuffer();
}

class Queue {
 ~Queue();
  Submit(commandBuffer : &CommandBuffer);
}

class Device {
  Device();
 ~Device();
  GetQueue() : *Queue;
}

class CommandEncoder;

class Buffer<T> {
  Buffer(device : &Device, size : uint = 1u);
  Buffer(device : &Device, t : &T);
 ~Buffer();
  SetData(data : &T);
  CopyFromBuffer(encoder : &CommandEncoder, source : &Buffer<T>);
  deviceonly MapRead() uniform : *readonly uniform T;
  deviceonly MapWrite() writeonly storage : *writeonly storage T;
  deviceonly Map() storage : *storage T;
  MapRead() hostreadable : *readonly T;
  MapWrite() hostwriteable : *writeonly T;
}

class DepthStencilState {
  var depthWriteEnabled = false;
  var stencilReadMask = 0xFFFFFFFF;
  var stencilWriteMask = 0xFFFFFFFF;
  var depthBias = 0;
  var depthBiasSlopeScale = 0.0;
  var depthBiasClamp = 0.0;
}

enum BlendOp {
  Add,
  Subtract,
  ReverseSubtract,
  Min,
  Max
}

enum BlendFactor {
  Zero,
  One,
  Src,
  OneMinusSrc,
  SrcAlpha,
  OneMinusSrcAlpha,
  Dst,
  OneMinusDst,
  DstAlpha,
  OneMinusDstAlpha,
  SrcAlphaSaturated,
  Constant,
  OneMinusConstant
}

class BlendComponent {
  var operation = BlendOp.Add;
  var srcFactor = BlendFactor.One;
  var dstFactor = BlendFactor.Zero;
}

class BlendState {
  var color : BlendComponent;
  var alpha : BlendComponent;
}

class RenderPipeline<T> {
  RenderPipeline(device : &Device, primitiveTopology = PrimitiveTopology.TriangleList, frontFace = FrontFace.CCW, cullMode = CullMode.None, depthStencilState : &DepthStencilState = {}, blendState : &BlendState = {});
 ~RenderPipeline();
}

class ComputePipeline<T> {
  ComputePipeline(device : &Device);
 ~ComputePipeline();
}

class BindGroup<T> {
  BindGroup(device : &Device, data : &T);
 ~BindGroup();
  deviceonly Get() : T;
}

enum LoadOp {
  Undefined,
  Clear,
  Load
}

enum StoreOp {
  Undefined,
  Store,
  Discard
}

class VertexInput<T> {
  VertexInput(buffer : &vertex Buffer<[]T>);
  deviceonly Get() : T;
 ~VertexInput();
}

class ColorOutput<PF> {
  deviceonly Set(value : <4>PF:DeviceType);
 ~ColorOutput();
}

class DepthStencilOutput<PF> {
 ~DepthStencilOutput();
}

enum AddressMode { Repeat, MirrorRepeat, ClampToEdge };

enum FilterMode { Nearest, Linear };

class Sampler {
  Sampler(device : &Device, addressModeU = AddressMode.ClampToEdge, addressModeV = AddressMode.ClampToEdge, addressModeW = AddressMode.ClampToEdge, magFilter = FilterMode.Linear, minFilter = FilterMode.Linear, mipmapFilter = FilterMode.Linear);
 ~Sampler();
}

class SampleableTexture1D<ST> {
 ~SampleableTexture1D();
  deviceonly Sample(sampler : &Sampler, coord : float) : <4>ST;
  deviceonly Load(coord : uint, level : uint) : <4>ST;
  deviceonly GetSize() : uint;
}

class SampleableTexture2D<ST> {
 ~SampleableTexture2D();
  deviceonly Sample(sampler : &Sampler, coords : <2>float) : <4>ST;
  deviceonly Load(coord : <2>uint, level : uint) : <4>ST;
  deviceonly GetSize() : <2>uint;
}

class SampleableTexture2DArray<ST> {
 ~SampleableTexture2DArray();
  deviceonly Sample(sampler : &Sampler, coords : <2>float, layer : uint) : <4>ST;
  deviceonly Load(coord : <2>uint, layer : uint, level : uint) : <4>ST;
  deviceonly GetSize() : <2>uint;
}

class SampleableTexture3D<ST> {
 ~SampleableTexture3D();
  deviceonly Sample(sampler : &Sampler, coords : <3>float) : <4>ST;
  deviceonly Load(coord : <3>uint, level : uint) : <4>ST;
  deviceonly GetSize() : <3>uint;
}

class SampleableTextureCube<ST> {
 ~SampleableTextureCube();
  deviceonly Sample(sampler : &Sampler, coords : <3>float) : <4>ST;
  deviceonly GetSize() : <2>uint;
}

class Texture1D<PF> {
  Texture1D(device : &Device, width : uint, mipLevelCount = 1u);
 ~Texture1D();
  GetSize(mipLevel = 0u) : uint;
  CreateSampleableView(baseMipLevel = 0u, mipLevelCount = 0u) sampleable : *SampleableTexture1D<PF:DeviceType>;
  CreateStorageView(mipLevel = 0u) : *storage Texture1D<PF>;
  CopyFromBuffer(encoder : &CommandEncoder, source : &Buffer<[]PF:HostType>, width : uint, origin = 0u, mipLevel = 0u);
}

class Texture2D<PF> {
  Texture2D(device : &Device, size : <2>uint, mipLevelCount = 1u);
 ~Texture2D();
  GetSize(mipLevel = 0u) : <2>uint;
  MinBufferWidth() : uint;
  CreateSampleableView(baseMipLevel = 0u, mipLevelCount = 0u) sampleable : *SampleableTexture2D<PF:DeviceType>;
  CreateRenderableView(mipLevel = 0u) : *renderable Texture2D<PF>;
  CreateStorageView(mipLevel = 0u) : *storage Texture2D<PF>;
  CreateColorOutput(loadOp = LoadOp.Load, storeOp = StoreOp.Store, clearValue = <4>float(0.0, 0.0, 0.0, 0.0)) renderable : *ColorOutput<PF>;
  CreateDepthStencilOutput(depthLoadOp = LoadOp.Load, depthStoreOp = StoreOp.Store, depthClearValue = 1.0, stencilLoadOp = LoadOp.Undefined, stencilStoreOp = StoreOp.Undefined, stencilClearValue = 0) renderable : *DepthStencilOutput<PF>;
  CopyFromBuffer(encoder : &CommandEncoder, source : &Buffer<[]PF:HostType>, size : <2>uint, origin = <2>uint{0, 0}, mipLevel = 0u);
}

class Texture2DArray<PF> {
  Texture2DArray(device : &Device, size : <2>uint, numLayers : uint, mipLevelCount = 1u);
 ~Texture2D();
  GetSize(mipLevel = 0u) : <2>uint;
  GetNumLayers() : uint;
  MinBufferWidth() : uint;
  CreateSampleableView(baseMipLevel = 0u, mipLevelCount = 0u, baseArrayLayer = 0u, arrayLayerCount = 0u) sampleable : *SampleableTexture2DArray<PF:DeviceType>;
  CreateRenderableView(layee : uint, mipLevel = 0u) : *renderable Texture2D<PF>;
  CreateStorageView(layer : uint, mipLevel = 0u) : *storage Texture2DArray<PF>;
  CopyFromBuffer(encoder : &CommandEncoder, source : &Buffer<[]PF:HostType>, size : <2>uint, layer : uint, numLayers = 1u, origin = <2>uint{0, 0}, mipLevel = 0u);
}

class Texture3D<PF> {
  Texture3D(device : &Device, size : <3>uint, mipLevelCount = 1u);
 ~Texture3D();
  GetSize(mipLevel = 0u) : <3>uint;
  MinBufferWidth() : uint;
  CreateSampleableView(baseMipLevel = 0u, mipLevelCount = 0u) sampleable : *SampleableTexture3D<PF:DeviceType>;
  CreateRenderableView(depth : uint, mipLevel = 0u) : *renderable Texture2D<PF>;
  CreateStorageView(depth : uint, mipLevel = 0u) : *storage Texture3D<PF>;
  CopyFromBuffer(encoder : &CommandEncoder, source : &Buffer<[]PF:HostType>, size : <3>uint, origin = <3>uint{0, 0, 0}, mipLevel = 0u);
}

class TextureCube<PF> {
  TextureCube(device : &Device, size : <2>uint, mipLevelCount = 1u);
 ~TextureCube();
  GetSize(mipLevel = 0u) : <2>uint;
  MinBufferWidth() : uint;
  CreateSampleableView(baseMipLevel = 0u, mipLevelCount = 0u) sampleable : *SampleableTextureCube<PF:DeviceType>;
  CreateRenderableView(face : uint, mipLevel = 0u) : *renderable Texture2D<PF>;
  CreateStorageView(face : uint, mipLevel = 0u) : *storage TextureCube<PF>;
  CopyFromBuffer(encoder : &CommandEncoder, source : &Buffer<[]PF:HostType>, size : <2>uint, face : uint, numFaces = 1u, origin = <2>uint{0, 0}, mipLevel = 0u);
}

class CommandEncoder {
  CommandEncoder(device : &Device);
 ~CommandEncoder();
  Finish() : *CommandBuffer;
}

class RenderPass<T> {
  RenderPass(encoder : &CommandEncoder, data : &T);
  RenderPass(base : &RenderPass<T:BaseClass>);
 ~RenderPass();
  Draw(vertexCount : uint, instanceCount : uint, firstVertex : uint, firstInstance : uint);
  DrawIndexed(indexCount : uint, instanceCount : uint, firstIndex : uint, baseVertex : uint, firstIntance : uint);
  SetPipeline(pipeline : &RenderPipeline<T>);
  Set(data : &T);
  End();
}

class ComputePass<T> {
  ComputePass(encoder : &CommandEncoder, data : &T);
  ComputePass(base : &ComputePass<T:BaseClass>);
 ~ComputePass();
  Dispatch(workgroupCountX : uint, workgroupCountY : uint, workgroupCountZ : uint);
  SetPipeline(pipeline : &ComputePipeline<T>);
  Set(data : &T);
  End();
}

class Window {
  Window(size : <2>uint, position = <2>int(0, 0));
  GetSize() : <2>uint;
 ~Window();
}

class SwapChain<T> {
  SwapChain(device : &Device, window : &Window);
 ~SwapChain();
  Resize(size : <2>uint);
  GetCurrentTexture() : *renderable Texture2D<T>;
  Present();
}

class Math {
 ~Math();
  static all(v : <2>bool)   : bool;
  static all(v : <3>bool)   : bool;
  static all(v : <4>bool)   : bool;
  static any(v : <2>bool)   : bool;
  static any(v : <3>bool)   : bool;
  static any(v : <4>bool)   : bool;
  static sqrt(v : float)    : float;
  static sqrt(v : <2>float) : <2>float;
  static sqrt(v : <3>float) : <3>float;
  static sqrt(v : <4>float) : <4>float;
  static sin(v : float)     : float;
  static sin(v : <2>float)  : <2>float;
  static sin(v : <3>float)  : <3>float;
  static sin(v : <4>float)  : <4>float;
  static cos(v : float)     : float;
  static cos(v : <2>float)  : <2>float;
  static cos(v : <3>float)  : <3>float;
  static cos(v : <4>float)  : <4>float;
  static tan(v : float)     : float;
  static tan(v : <2>float)  : <2>float;
  static tan(v : <3>float)  : <3>float;
  static tan(v : <4>float)  : <4>float;
  static dot(v1 : <2>float, v2 : <2>float) : float;
  static dot(v1 : <3>float, v2 : <3>float) : float;
  static dot(v1 : <4>float, v2 : <4>float) : float;
  static cross(v1 : <3>float, v2 : <3>float) : <3>float;
  static fabs(v : float)    : float;
  static fabs(v : <2>float) : <2>float;
  static fabs(v : <3>float) : <3>float;
  static fabs(v : <4>float) : <4>float;
  static floor(v : float)   : float;
  static floor(v : <2>float) : <2>float;
  static floor(v : <3>float) : <3>float;
  static floor(v : <4>float) : <4>float;
  static ceil(v : float)   : float;
  static ceil(v : <2>float) : <2>float;
  static ceil(v : <3>float) : <3>float;
  static ceil(v : <4>float) : <4>float;
  static min(v1 : float,    v2 : float) : float;
  static min(v1 : <2>float, v2 : <2>float) : <2>float;
  static min(v1 : <3>float, v2 : <3>float) : <3>float;
  static min(v1 : <4>float, v2 : <4>float) : <4>float;
  static min(v1 : int,    v2 : int) : int;
  static min(v1 : <2>int, v2 : <2>int) : <2>int;
  static min(v1 : <3>int, v2 : <3>int) : <3>int;
  static min(v1 : <4>int, v2 : <4>int) : <4>int;
  static min(v1 : uint,    v2 : uint) : uint;
  static min(v1 : <2>uint, v2 : <2>uint) : <2>uint;
  static min(v1 : <3>uint, v2 : <3>uint) : <3>uint;
  static min(v1 : <4>uint, v2 : <4>uint) : <4>uint;
  static max(v1 : float,    v2 : float) : float;
  static max(v1 : <2>float, v2 : <2>float) : <2>float;
  static max(v1 : <3>float, v2 : <3>float) : <3>float;
  static max(v1 : <4>float, v2 : <4>float) : <4>float;
  static max(v1 : int,    v2 : int) : int;
  static max(v1 : <2>int, v2 : <2>int) : <2>int;
  static max(v1 : <3>int, v2 : <3>int) : <3>int;
  static max(v1 : <4>int, v2 : <4>int) : <4>int;
  static max(v1 : uint,    v2 : uint) : uint;
  static max(v1 : <2>uint, v2 : <2>uint) : <2>uint;
  static max(v1 : <3>uint, v2 : <3>uint) : <3>uint;
  static max(v1 : <4>uint, v2 : <4>uint) : <4>uint;
  static length(v : float) : float;
  static length(v : <2>float) : float;
  static length(v : <3>float) : float;
  static length(v : <4>float) : float;
  static pow(v1 : float,    v2 : float) : float;
  static pow(v1 : <2>float, v2 : <2>float) : <2>float;
  static pow(v1 : <3>float, v2 : <3>float) : <3>float;
  static pow(v1 : <4>float, v2 : <4>float) : <4>float;
  static clz(value : int)   : int;
  static rand()             : float;
  static normalize(v : <3>float) : <3>float;
  static reflect(incident : <3>float, normal : <3>float) : <3>float;
  static refract(incident : <3>float, normal : <3>float, eta : float) : <3>float;
  static inverse(m : <4><4>float) : <4><4>float;
  static transpose(m : <4><4>float) : <4><4>float;
}

class Image<PF> {
  Image(encodedImage : *[]ubyte);
 ~Image();
  GetSize() : <2>uint;
  Decode(buffer : &writeonly []PF:HostType, bufferWidth : uint);
}

enum EventType { MouseMove, MouseDown, MouseUp, TouchStart, TouchMove, TouchEnd, Unknown }

enum EventModifiers { Shift = 0x01, Control = 0x02, Alt = 0x04 }

class Event {
 ~Event();
  var type : EventType;
  var position : <2>int;
  var button : uint;
  var modifiers : uint;
  var touches : [10]<2>int;
  var numTouches : int;
}

class System {
 ~System();
  static IsRunning() : bool;
  static HasPendingEvents() : bool;
  static GetNextEvent() : *Event;
  static GetScreenSize() : <2>uint;
  static StorageBarrier() : int;
  static GetCurrentTime() : double;
  static Print(str : &[]ubyte);
  static PrintLine(str : &[]ubyte);
  static GetSourceFile() : *[]ubyte;
  static GetSourceLine() : int;
  static Abort();
}

class VertexBuiltins {
  var vertexIndex : readonly int;
  var instanceIndex : readonly int;
  var position : writeonly <4>float;
}

class FragmentBuiltins {
  var fragCoord : readonly <4>float;
  var frontFacing : readonly bool;
}

class ComputeBuiltins {
  var localInvocationId : readonly <3>uint;
  var localInvocationIndex : readonly uint;
  var globalInvocationId : readonly <3>uint;
  var workgroupId : readonly <3>uint;
}

class PixelFormat<DeviceType, HostType> {}

class R8unorm : PixelFormat<float, ubyte> {}
class R8snorm : PixelFormat<float, byte> {}
class R8uint : PixelFormat<uint, ubyte> {}
class R8sint : PixelFormat<int, byte> {}

class RG8unorm : PixelFormat<float, <2>ubyte> {}
class RG8snorm : PixelFormat<float, <2>byte> {}
class RG8uint : PixelFormat<uint, <2>ubyte> {}
class RG8sint : PixelFormat<int, <2>byte> {}

class RGBA8unorm : PixelFormat<float, <4>ubyte> {}
class RGBA8unormSRGB : PixelFormat<float, <4>ubyte> {}
class RGBA8snorm : PixelFormat<float, <4>byte> {}
class RGBA8uint : PixelFormat<uint, <4>ubyte> {}
class RGBA8sint : PixelFormat<int, <4>byte> {}

class BGRA8unorm : PixelFormat<float, <4>ubyte> {}
class BGRA8unormSRGB : PixelFormat<float, <4>ubyte> {}

class R16uint : PixelFormat<uint, ushort> {}
class R16sint : PixelFormat<int, short> {}
class R16float : PixelFormat<float, ushort> {}

class RG16uint : PixelFormat<uint, <2>ushort> {}
class RG16sint : PixelFormat<int, <2>short> {}
class RG16float : PixelFormat<float, <2>ushort> {}

class RGBA16uint : PixelFormat<uint, <4>ushort> {}
class RGBA16sint : PixelFormat<int, <4>short> {}
class RGBA16float : PixelFormat<float, <4>ushort> {}

class R32uint : PixelFormat<uint, uint> {}
class R32sint : PixelFormat<int, int> {}
class R32float : PixelFormat<float, float> {}

class RG32uint : PixelFormat<uint, <2>uint> {}
class RG32sint : PixelFormat<int, <2>int> {}
class RG32float : PixelFormat<float, <2>float> {}

class RGBA32uint : PixelFormat<uint, <4>uint> {}
class RGBA32sint : PixelFormat<int, <4>int> {}
class RGBA32float : PixelFormat<float, <4>float> {}

class RGB10A2unorm : PixelFormat<float, uint> {}
class RG11B10ufloat : PixelFormat<float, uint> {}

class Depth24Plus : PixelFormat<float, uint> {}

class PreferredPixelFormat : PixelFormat<float, <4>ubyte> {}
