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

#include <webgpu/webgpu_cpp.h>

namespace Toucan {

struct Device {
  Device(wgpu::Device d) : device(d) {}
  wgpu::Device device;
};

struct SwapChain {
  SwapChain(wgpu::SwapChain sc, void* p) : swapChain(sc), pool(p) {}
  wgpu::SwapChain swapChain;
  void*           pool;
};

struct Event {
  unsigned type;
  unsigned pad;
  int      mousePos[2];
  unsigned button;
  unsigned modifiers;
};

}  // namespace Toucan
#endif  // _APIINTERNAL_H
