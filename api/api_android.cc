// Copyright 2024 The Toucan Authors
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

#include <android/log.h>
#include <android_native_app_glue.h>

#include <cassert>

#include <webgpu/webgpu_cpp.h>

#include "api_internal.h"

#define LOGV(...) ((void)__android_log_print(ANDROID_LOG_VERBOSE, "Toucan App", __VA_ARGS__))

namespace Toucan {

static int                                     gNumWindows = 0;
static android_app*                            gAndroidApp;

struct Window {
  Window(ANativeWindow* w) : window(w) {}
  ANativeWindow* window;
};

Window* Window_Window(int32_t x, int32_t y, uint32_t width, uint32_t height) {
  ANativeWindow* window;
  if (gNumWindows == 0) {
    while (gAndroidApp->window == nullptr) {
      int                  events;
      void*                data;
      android_poll_source* source = nullptr;
      int ident = ALooper_pollOnce(-1, nullptr, &events, reinterpret_cast<void**>(&source));
      if (source != nullptr) { source->process(gAndroidApp, source); }
    }
    window = gAndroidApp->window;
  } else {
    // TODO: create a dialog of x, y, width, height
    window = nullptr;
  }
  if (!window) { return nullptr; }
  gNumWindows++;
  return new Window(window);
}

void Window_Destroy(Window* This) { delete This; }

static void PrintDeviceError(WGPUErrorType, const char* message, void*) {
  LOGV("Device error: %s", message);
}

Device* Device_Device() {
  wgpu::Device device = CreateDawnDevice(wgpu::BackendType::Vulkan, PrintDeviceError);
  if (!device) { return nullptr; }
  return new Device(device);
}

bool System_IsRunning() { return true; }

bool System_HasPendingEvents() { return AInputQueue_hasEvents(gAndroidApp->inputQueue); }

Event* System_GetNextEvent() {
  Event* result = new Event();
  result->type = EventType::Unknown;
  int                  events;
  void*                data;
  android_poll_source* source = nullptr;
  int ident = ALooper_pollOnce(-1, nullptr, &events, reinterpret_cast<void**>(&source));
  if (source != nullptr) { source->process(gAndroidApp, source); }
  return result;
}

wgpu::TextureFormat GetPreferredSwapChainFormat() { return wgpu::TextureFormat::RGBA8Unorm; }

SwapChain* SwapChain_SwapChain(int qualifiers, Type* format, Device* device, Window* window) {
  wgpu::SurfaceConfiguration config;
  config.device = device->device;
  config.format = wgpu::TextureFormat::RGBA8Unorm;
  config.width = ANativeWindow_getWidth(window->window);
  config.height = ANativeWindow_getHeight(window->window);
  config.presentMode = wgpu::PresentMode::Fifo;

  wgpu::SurfaceDescriptorFromAndroidNativeWindow awDesc;
  awDesc.window = window->window;
  wgpu::SurfaceDescriptor surfaceDesc;
  surfaceDesc.nextInChain = &awDesc;

  static wgpu::Instance instance = wgpu::CreateInstance({});

  wgpu::Surface surface = instance.CreateSurface(&surfaceDesc);

  surface.Configure(&config);

  return new SwapChain(surface, {config.width, config.height, 1}, config.format, nullptr);
}

double System_GetCurrentTime() {
  struct timeval now;

  gettimeofday(&now, NULL);
  return static_cast<double>(now.tv_sec) + static_cast<double>(now.tv_usec) / 1000000.0;
}

void SetAndroidApp(struct android_app* app) { gAndroidApp = app; }

};  // namespace Toucan
