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

#ifndef _APIINTERNAL_H
#define _APIINTERNAL_H

#include <ast/type.h>
#include <webgpu/webgpu_cpp.h>
#include <cassert>

namespace Toucan {

class Type;

struct Device {
  Device(wgpu::Device d) : device(d) {}
  wgpu::Device device;
};

#ifndef __ANDROID__
struct SwapChain {
  SwapChain(wgpu::Surface s, wgpu::Device d, wgpu::Extent3D e, wgpu::TextureFormat f, void* p)
      : surface(s), device(d), extent(e), format(f), pool(p) {}
  wgpu::Surface       surface;
  wgpu::Device        device;
  wgpu::Extent3D      extent;
  wgpu::TextureFormat format;
  void*               pool;
};
#endif

inline uint32_t BytesPerPixel(wgpu::TextureFormat format) {
  switch (format) {
    case wgpu::TextureFormat::RGBA8Unorm:
    case wgpu::TextureFormat::RGBA8Snorm:
    case wgpu::TextureFormat::RGBA8Uint:
    case wgpu::TextureFormat::RGBA8Sint:
    case wgpu::TextureFormat::BGRA8Unorm: return 4;
    case wgpu::TextureFormat::RGBA16Float: return 8;
    default: assert(!"unknown Format"); return 0;
  }
}

wgpu::TextureFormat GetPreferredPixelFormat();
wgpu::TextureFormat ToDawnTextureFormat(Type* type);
wgpu::Device CreateDawnDevice(wgpu::BackendType type, const wgpu::DeviceDescriptor* desc);

inline wgpu::TextureUsage ToDawnTextureUsage(int qualifiers) {
  wgpu::TextureUsage result = wgpu::TextureUsage::CopySrc | wgpu::TextureUsage::CopyDst;

  if (qualifiers & Type::Qualifier::Storage) { result |= wgpu::TextureUsage::StorageBinding; }
  if (qualifiers & Type::Qualifier::Sampleable) { result |= wgpu::TextureUsage::TextureBinding; }
  if (qualifiers & Type::Qualifier::Renderable) { result |= wgpu::TextureUsage::RenderAttachment; }
  return result;
}

struct Texture {
  Texture(wgpu::Texture t, wgpu::TextureView v) : texture(t), view(v) {}
  Texture(int                    qualifiers,
          Type*                  pixelFormat,
          wgpu::Device           device,
          wgpu::TextureDimension dimension,
          wgpu::Extent3D         size,
          uint32_t               mipLevelCount) {
    wgpu::TextureDescriptor desc;
    desc.usage = ToDawnTextureUsage(qualifiers);
    desc.size = size;
    desc.mipLevelCount = mipLevelCount;
    desc.format = ToDawnTextureFormat(pixelFormat);
    desc.dimension = dimension;
    texture = device.CreateTexture(&desc);
    view = texture.CreateView();
  }
  Texture(Texture* t, wgpu::TextureView view) : Texture(t->texture, view) {}
  virtual ~Texture() = default;

  uint32_t MinBufferWidth() {
    uint32_t bytesPerPixel = BytesPerPixel(texture.GetFormat());
    return (((texture.GetWidth() * bytesPerPixel + 255) >> 8) << 8) / bytesPerPixel;
  }

  const uint32_t* Get2DSize(uint32_t mipLevel) {
    static uint32_t size[2];
    size[0] = texture.GetWidth() >> mipLevel;
    size[1] = texture.GetHeight() >> mipLevel;
    return size;
  }

  void CopyFromBuffer(wgpu::CommandEncoder encoder,
                      wgpu::Buffer         source,
                      wgpu::Extent3D       extent,
                      wgpu::Origin3D       origin,
                      uint32_t             mipLevel) {
    wgpu::TexelCopyBufferInfo sourceInfo;
    sourceInfo.buffer = source;
    sourceInfo.layout.bytesPerRow = MinBufferWidth() * BytesPerPixel(texture.GetFormat());
    sourceInfo.layout.rowsPerImage = texture.GetHeight();
    wgpu::TexelCopyTextureInfo destInfo;
    destInfo.texture = texture;
    destInfo.origin = origin;
    destInfo.mipLevel = mipLevel;
    encoder.CopyBufferToTexture(&sourceInfo, &destInfo, &extent);
  }

  virtual wgpu::TextureViewDimension GetViewDimension() const = 0;
  wgpu::TextureView CreateView(
      uint32_t                   baseMipLevel = 0,
      uint32_t                   mipLevelCount = 0,
      uint32_t                   baseArrayLayer = 0,
      uint32_t                   arrayLayerCount = 0,
      wgpu::TextureViewDimension dimension = wgpu::TextureViewDimension::Undefined) {
    if (mipLevelCount == 0) mipLevelCount = wgpu::kMipLevelCountUndefined;
    if (arrayLayerCount == 0) arrayLayerCount = wgpu::kArrayLayerCountUndefined;
    if (dimension == wgpu::TextureViewDimension::Undefined) dimension = GetViewDimension();
    wgpu::TextureViewDescriptor desc;
    desc.format = texture.GetFormat();
    desc.dimension = dimension;
    desc.baseMipLevel = baseMipLevel;
    desc.mipLevelCount = mipLevelCount;
    desc.baseArrayLayer = baseArrayLayer;
    desc.arrayLayerCount = arrayLayerCount;
    return texture.CreateView(&desc);
  }
  wgpu::TextureView Create2DView(uint32_t baseMipLevel = 0, uint32_t baseArrayLayer = 0) {
    return CreateView(baseMipLevel, 1, baseArrayLayer, 1, wgpu::TextureViewDimension::e2D);
  }
  wgpu::Texture     texture;
  wgpu::TextureView view;
};

struct Texture1D : public Texture {
  using Texture::Texture;
  wgpu::TextureViewDimension GetViewDimension() const override {
    return wgpu::TextureViewDimension::e1D;
  }
};
struct Texture2D : public Texture {
  using Texture::Texture;
  wgpu::TextureViewDimension GetViewDimension() const override {
    return wgpu::TextureViewDimension::e2D;
  }
};
struct Texture2DArray : public Texture {
  using Texture::Texture;
  wgpu::TextureViewDimension GetViewDimension() const override {
    return wgpu::TextureViewDimension::e2DArray;
  }
};
struct Texture3D : public Texture {
  using Texture::Texture;
  wgpu::TextureViewDimension GetViewDimension() const override {
    return wgpu::TextureViewDimension::e3D;
  }
};
struct TextureCube : public Texture {
  using Texture::Texture;
  wgpu::TextureViewDimension GetViewDimension() const override {
    return wgpu::TextureViewDimension::Cube;
  }
};

}  // namespace Toucan
#endif  // _APIINTERNAL_H
