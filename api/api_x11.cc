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

#include <dlfcn.h>
#include <sys/time.h>

#include <cassert>
#include <cstring>
#include <memory>

#define Window XWindow
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#undef Window
#undef Status
#undef Success
#undef Always
#undef None
#undef Bool

#include <webgpu/webgpu_cpp.h>

#include "api_internal.h"

namespace Toucan {

namespace {
int ToToucanEventModifiers(int state) {
  int result = 0;
  if (state & ShiftMask) { result |= Shift; }
  if (state & ControlMask) { result |= Control; }
  return result;
}
}  // namespace

static int  gNumWindows = 0;
static Atom gWM_DELETE_WINDOW;

struct Window {
  Window(Display* dpy, XWindow w) : display(dpy), window(w) {}
  Display* display;
  XWindow  window;
  uint32_t size[2] = {0, 0};
};

static Display* gDisplay;

Window* Window_Window(const int32_t* position, const uint32_t* size) {
  if (!gDisplay) gDisplay = ::XOpenDisplay(0);
  if (!gDisplay) return nullptr;
  XWindow     rootWindow = RootWindow(gDisplay, DefaultScreen(gDisplay));
  XVisualInfo visualInfo;
  if (!XMatchVisualInfo(gDisplay, DefaultScreen(gDisplay), 24, TrueColor, &visualInfo)) {
    return nullptr;
  }
  Colormap colorMap = ::XCreateColormap(gDisplay, rootWindow, visualInfo.visual, AllocNone);

  XSetWindowAttributes windowAttributes;
  windowAttributes.border_pixel = BlackPixel(gDisplay, visualInfo.screen);
  windowAttributes.colormap = colorMap;
  windowAttributes.event_mask = StructureNotifyMask;
  XWindow window = ::XCreateWindow(gDisplay, rootWindow, position[0], position[1], size[0], size[1],
                                   1, /* border_width */
                                   visualInfo.depth, InputOutput, visualInfo.visual,
                                   CWColormap | CWEventMask, &windowAttributes);
  if (!window) { return nullptr; }

  XSelectInput(
      gDisplay, window,
      ButtonPressMask | ButtonReleaseMask | ButtonMotionMask | PointerMotionMask | ExposureMask);
  if (!gWM_DELETE_WINDOW) { gWM_DELETE_WINDOW = XInternAtom(gDisplay, "WM_DELETE_WINDOW", False); }
  ::XSetWMProtocols(gDisplay, window, &gWM_DELETE_WINDOW, 1);
  ::XMapWindow(gDisplay, window);
  ::XSync(gDisplay, True);
  gNumWindows++;
  return new Window(gDisplay, window);
}

const uint32_t* Window_GetSize(Window* This) {
  XWindowAttributes attributes;
  XGetWindowAttributes(gDisplay, This->window, &attributes);
  This->size[0] = attributes.width;
  This->size[1] = attributes.height;
  return This->size;
}

void Window_Destroy(Window* This) {
  XDestroyWindow(gDisplay, This->window);
  delete This;
}

static void PrintDeviceError(WGPUErrorType, const char* message, void*) {
  printf("Device error: %s\n", message);
}

Device* Device_Device() {
  wgpu::Device device = CreateDawnDevice(wgpu::BackendType::Vulkan, PrintDeviceError);
  if (!device) { return nullptr; }
  return new Device(device);
}

bool System_IsRunning() { return gNumWindows > 0; }

bool System_HasPendingEvents() { return XPending(gDisplay) != 0; }

Event* System_GetNextEvent() {
  if (!gDisplay) return nullptr;
  Event* result = new Event();
  result->type = EventType::Unknown;
  XEvent event;
  ::XNextEvent(gDisplay, &event);
  switch (event.type) {
    case ButtonPress:
    case ButtonRelease:
      result->type = event.type == ButtonPress ? EventType::MouseDown : EventType::MouseUp;
      result->button = event.xbutton.button;
      result->mousePos[0] = event.xbutton.x;
      result->mousePos[1] = event.xbutton.y;
      result->modifiers = ToToucanEventModifiers(event.xbutton.state);
      break;
    case MotionNotify:
      result->type = EventType::MouseMove;
      result->mousePos[0] = event.xmotion.x;
      result->mousePos[1] = event.xmotion.y;
      result->modifiers = ToToucanEventModifiers(event.xmotion.state);
      break;
    case DestroyNotify: gNumWindows--; break;
    case ClientMessage:
      if (static_cast<Atom>(event.xclient.data.l[0]) == gWM_DELETE_WINDOW) {
        ::XDestroyWindow(gDisplay, event.xclient.window);
        gNumWindows--;
      }
      break;
    default: break;
  }
  return result;
}

wgpu::TextureFormat GetPreferredSwapChainFormat() { return wgpu::TextureFormat::BGRA8Unorm; }

SwapChain* SwapChain_SwapChain(int qualifiers, Type* format, Device* device, Window* window) {
  wgpu::SurfaceConfiguration config;
  config.device = device->device;
  config.format = wgpu::TextureFormat::BGRA8Unorm;
  XWindowAttributes attributes;
  XGetWindowAttributes(gDisplay, window->window, &attributes);
  config.width = attributes.width;
  config.height = attributes.height;
  config.presentMode = wgpu::PresentMode::Fifo;

  wgpu::SurfaceDescriptorFromXlibWindow xlibDesc;
  xlibDesc.display = gDisplay;
  xlibDesc.window = window->window;

  wgpu::SurfaceDescriptor surfaceDesc;
  surfaceDesc.nextInChain = &xlibDesc;

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

};  // namespace Toucan
