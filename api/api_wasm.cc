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

#include <api.h>  // generated by generate_bindings

#include <emscripten.h>
#include <emscripten/val.h>

#include "api_internal.h"

namespace Toucan {

namespace {

static uint32_t gScreenSize[2];
static std::unordered_map<int, Window*> gWindows;

void copyMouseEvent(emscripten::val event, Event* result) {
  result->button = event["button"].as<int>();
  result->position[0] = event["clientX"].as<int>();
  result->position[1] = event["clientY"].as<int>();
}

void copyTouches(emscripten::val touches, Event* result) {
  int length = touches["length"].as<int>();
  if (length > 10) length = 10;
  result->numTouches = length;
  for (int i = 0; i < length; ++i) {
    emscripten::val touch = touches.call<emscripten::val>("item", i);
    result->touches[i][0] = touch["clientX"].as<int>();
    result->touches[i][1] = touch["clientY"].as<int>();
  }
}

}  // namespace

struct Window {
  Window(int i, wgpu::Surface s, const uint32_t sz[2])
      : id(i), surface(s) { size[0] = sz[0]; size[1] = sz[1]; }
  int           id;
  wgpu::Surface surface;
  uint32_t      size[2];
};

EM_JS(int, createWindow, (int32_t x, int32_t y, int32_t width, int32_t height), {
    var w;
    var canvas;
    if (Module.numWindows == 0) {
      w = window;
      canvas = w.document.getElementById("canvas");
      canvas.width = width;
      canvas.height = height;
      Module.requestFullscreen = () => { canvas.requestFullscreen(); }
    } else {
      w = window.open("", "",
                      "left=" + x + ", top=" + y + ", width=" + width + ", height=" + height);
      w.document.body.style.margin = 0;
      var canvas = w.document.createElement("canvas");
      canvas.style.display = "block";
      w.document.body.appendChild(canvas);
    }
    const events = ["mousedown", "mousemove", "mouseup", "touchstart", "touchmove", "touchend", "resize"];
    var inputListener = (e) => {
      e.preventDefault();
      Module.events.push(e);
      if (Module.newInput) Module.newInput();
    };
    events.forEach((eventType) => canvas.addEventListener(eventType, inputListener, { passive: false }));
    w.oncontextmenu = (e) => { e.preventDefault() };
    specialHTMLTargets["!toucanvas"] = canvas;
    return w.id = Module.numWindows++;
});

Window* Window_Window(const int32_t* position, const uint32_t* size) {
  int id = EM_ASM_INT({ createWindow($0, $1, $2, $3) }, position[0], position[1], size[0], size[1]);

  wgpu::SurfaceDescriptorFromCanvasHTMLSelector canvasDesc{};
  canvasDesc.selector = "!toucanvas";

  wgpu::SurfaceDescriptor surfDesc{};
  surfDesc.nextInChain = &canvasDesc;
  wgpu::Instance instance = wgpuCreateInstance(nullptr);
  wgpu::Surface  surface = instance.CreateSurface(&surfDesc);
  return gWindows[id] = new Window(id, surface, size);
}

void Window_Destroy(Window* This) { delete This; }

const uint32_t* Window_GetSize(Window* This) {
  return This->size;
}

static void PrintDeviceError(WGPUErrorType, const char* message, void*) {
  printf("Device error: %s\n", message);
}

EM_ASYNC_JS(WGPUDevice, JSInitDevice, (), {
  const adapter = await navigator.gpu.requestAdapter();
  const device = await  adapter.requestDevice();
  const deviceWrapper = {queueId : WebGPU.mgrQueue.create(device["queue"])};
  return WebGPU.mgrDevice.create(device, deviceWrapper);
});

Device* Device_Device() {
  wgpu::Device device = wgpu::Device::Acquire(JSInitDevice());
  EM_ASM({
    Module.numWindows = 0;
    Module.events = [];
    Module.newInput = null;
  });
  if (!device) { return nullptr; }
  device.SetUncapturedErrorCallback(PrintDeviceError, nullptr);
  return new Device(device);
}

bool System_IsRunning() {
  int numWindows = EM_ASM_INT({ return Module.numWindows; });
  return numWindows > 0;
}

bool System_HasPendingEvents() {
  return EM_ASM_INT({ return Module.events.length; }) > 0;
}

EM_ASYNC_JS(void, JSWaitForNextEvent, (), {
  if (Module.events.length == 0) {
    await new Promise(resolve => { Module.newInput = resolve; });
    Module.newInput = null;
  }
});

Event* System_GetNextEvent() {
  Event* result = new Event();
  result->type = EventType::Unknown;
  JSWaitForNextEvent();
  emscripten::val events = emscripten::val::global("Module")["events"];
  emscripten::val event = events.call<emscripten::val>("shift");
  result->type = EventType::MouseMove;
  std::string type = event["type"].as<std::string>();
  if (type == "mousedown") {
    copyMouseEvent(event, result);
    result->type = EventType::MouseDown;
  } else if (type == "mouseup") {
    copyMouseEvent(event, result);
    result->type = EventType::MouseUp;
  } else if (type == "mousemove") {
    copyMouseEvent(event, result);
    result->type = EventType::MouseMove;
  } else if (type == "touchstart") {
    copyTouches(event["touches"], result);
    result->type = EventType::TouchStart;
  } else if (type == "touchmove") {
    copyTouches(event["touches"], result);
    result->type = EventType::TouchMove;
  } else if (type == "touchend") {
    result->type = EventType::TouchEnd;
  } else if (type == "resize") {
    if (Window* w = gWindows[EM_ASM_INT("window.id")]) {
      w->size[0] = EM_ASM_INT("return window.innerWidth");
      w->size[1] = EM_ASM_INT("return window.innerHeight");
    }
  }
  result->modifiers = 0;
  if (event["shiftKey"].as<bool>()) { result->modifiers |= static_cast<uint32_t>(EventModifiers::Shift); }
  if (event["ctrlKey"].as<bool>()) { result->modifiers |= static_cast<uint32_t>(EventModifiers::Control); }
  return result;
}

const uint32_t* System_GetScreenSize() {
  gScreenSize[0] = static_cast<uint32_t>(EM_ASM_INT("return window.innerWidth"));
  gScreenSize[1] = static_cast<uint32_t>(EM_ASM_INT("return window.innerHeight"));
  return gScreenSize;
}

double System_GetCurrentTime() {
  return EM_ASM_DOUBLE({ return Date.now() / 1000.0; });
}

wgpu::TextureFormat GetPreferredSwapChainFormat() {
  int format = EM_ASM_INT({
    return WebGPU.Int_PreferredFormat[navigator.gpu.getPreferredCanvasFormat()];
  });
  return static_cast<wgpu::TextureFormat>(format);
}

SwapChain* SwapChain_SwapChain(int qualifiers, Type* format, Device* device, Window* window) {
  wgpu::SwapChainDescriptor desc;
  desc.usage = wgpu::TextureUsage::RenderAttachment;
  desc.format = ToDawnTextureFormat(format);
  desc.width = window->size[0];
  desc.height = window->size[1];
  desc.presentMode = wgpu::PresentMode::Fifo;
  wgpu::SwapChain swapChain = device->device.CreateSwapChain(window->surface, &desc);
  return new SwapChain(swapChain, window->surface, device->device, {desc.width, desc.height, 1}, desc.format, nullptr);
}

void SwapChain_Resize(SwapChain* swapChain, const uint32_t* size) {
  wgpu::SwapChainDescriptor desc;
  desc.usage = wgpu::TextureUsage::RenderAttachment;
  desc.format = swapChain->format;
  desc.width = size[0];
  desc.height = size[1];
  desc.presentMode = wgpu::PresentMode::Fifo;
  swapChain->swapChain = swapChain->device.CreateSwapChain(swapChain->surface, &desc);
}

EM_ASYNC_JS(void, JSWaitForRAF, (), {
  await new Promise(resolve => { requestAnimationFrame(resolve); });
});

void SwapChain_Present(SwapChain* swapChain) { JSWaitForRAF(); }

};  // namespace Toucan
