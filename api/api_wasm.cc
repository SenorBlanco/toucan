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

struct Window {
  Window(Device* d, wgpu::Surface s, uint32_t w, uint32_t h)
      : device(d), surface(s), width(w), height(h) {}
  Device*       device;
  wgpu::Surface surface;
  uint32_t      width, height;
};

Window* Window_Window(Device* device, int32_t x, int32_t y, uint32_t width, uint32_t height) {
  EM_ASM(
      {
        var w;
        var canvas;
        if (Module.numWindows == 0) {
          w = window;
          canvas = w.document.getElementById('canvas');
          canvas.width = $2;
          canvas.height = $3;
          Module.requestFullscreen = () => { canvas.requestFullscreen(); }
        } else {
          w = window.open("", "",
                          "left=" + $0 + ", top=" + $1 + ", width=" + $2 + ", height=" + $3);
          w.document.body.style.margin = 0;
          var canvas = w.document.createElement("canvas");
          canvas.style.display = "block";
          w.document.body.appendChild(canvas);
        }
        w.onbeforeunload = function() { Module.numWindows--; };
        w.onmousedown = w.onmouseup = w.onmousemove = (e) => {
          e.preventDefault;
          Module.events.push(e);
          if (Module.newInput) Module.newInput();
        };
        w.oncontextmenu = (e) => {e.preventDefault()};
        specialHTMLTargets["!toucanvas"] = canvas;
        Module.numWindows++;
      },
      x, y, width, height);

  wgpu::SurfaceDescriptorFromCanvasHTMLSelector canvasDesc{};
  canvasDesc.selector = "!toucanvas";

  wgpu::SurfaceDescriptor surfDesc{};
  surfDesc.nextInChain = &canvasDesc;
  wgpu::Instance instance = wgpuCreateInstance(nullptr);
  wgpu::Surface  surface = instance.CreateSurface(&surfDesc);
  return new Window(device, surface, width, height);
}

void Window_Destroy(Window* This) { delete This; }

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
  result->mousePos[0] = event["clientX"].as<int>();
  result->mousePos[1] = event["clientY"].as<int>();
  result->button = event["button"].as<int>();
  std::string type = event["type"].as<std::string>();
  if (type == "mousedown") {
    result->type = EventType::MouseDown;
  } else if (type == "mouseup") {
    result->type = EventType::MouseUp;
  } else if (type == "mousemove") {
    result->type = EventType::MouseMove;
  } else {
    result->type = EventType::Unknown;
  }
  result->modifiers = 0;
  if (event["shiftKey"].as<bool>()) { result->modifiers |= Shift; }
  if (event["ctrlKey"].as<bool>()) { result->modifiers |= Control; }
  return result;
}

double System_GetCurrentTime() {
  return EM_ASM_DOUBLE({ return Date.now() / 1000.0; });
}

SwapChain* SwapChain_SwapChain(Window* window) {
  Device*                   device = window->device;
  wgpu::SwapChainDescriptor desc;
  desc.usage = wgpu::TextureUsage::RenderAttachment;
  desc.format = wgpu::TextureFormat::BGRA8Unorm;
  desc.width = window->width;
  desc.height = window->height;
  desc.presentMode = wgpu::PresentMode::Fifo;
  wgpu::SwapChain swapChain = device->device.CreateSwapChain(window->surface, &desc);
  return new SwapChain(swapChain, nullptr);
}

EM_ASYNC_JS(void, JSWaitForRAF, (), {
  await new Promise(resolve => { requestAnimationFrame(resolve); });
});

void SwapChain_Present(SwapChain* swapChain) { JSWaitForRAF(); }

};  // namespace Toucan