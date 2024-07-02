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

#include <sys/time.h>

#include <memory>

#include <webgpu/webgpu_cpp.h>

#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include "api_internal.h"

@interface ToucanWindowDelegate : NSObject {
  Toucan::Window* window;
}
- (instancetype)initWithWindow:(Toucan::Window*)w;
@end

@interface ToucanAppDelegate : NSObject <NSApplicationDelegate>
@end

static bool gIsRunning = true;
static uint32_t gScreenSize[2];

namespace Toucan {

namespace {
void PrintDeviceError(WGPUErrorType, const char* message, void*) {
  printf("Device error: %s\n", message);
}

}  // namespace

static bool                                    gInitialized = false;

struct Window {
  Window(NSWindow*     nsw,
         NSView*       v,
         CAMetalLayer* l,
         id<MTLDevice> md,
         const uint32_t      sz[2])
      : window(nsw), view(v), layer(l), mtlDevice(md) { size[0] = sz[0]; size[1] = sz[1]; }
  NSWindow*     window;
  NSView*       view;
  CAMetalLayer* layer;
  id<MTLDevice> mtlDevice;
  uint32_t      size[2];
};

namespace {

unsigned ToToucanEventModifiers(NSEventModifierFlags modifiers) {
  unsigned result = 0;
  if (modifiers & NSEventModifierFlagShift) { result |= Shift; }
  if (modifiers & NSEventModifierFlagControl) { result |= Control; }
  return result;
}

void Initialize() {
  NSApplication* app = [NSApplication sharedApplication];
  [app setActivationPolicy:NSApplicationActivationPolicyRegular];

  NSMenu* menuBar = [[NSMenu alloc] init];
  [NSApp setMainMenu:menuBar];

  NSMenuItem* menu = [[NSMenuItem alloc] init];
  [menuBar addItem:menu];

  NSMenu* subMenu = [[NSMenu alloc] init];
  [menuBar setSubmenu:subMenu forItem:menu];
  [menu release];

  NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                action:@selector(terminate:)
                                         keyEquivalent:@"q"];
  [subMenu addItem:item];
  [item release];
  [subMenu release];
  [menuBar release];

  ToucanAppDelegate* delegate = [[ToucanAppDelegate alloc] init];
  [NSApp setDelegate:delegate];

  if (![[NSRunningApplication currentApplication] isFinishedLaunching]) { [NSApp run]; }
}

}  // namespace

const uint32_t* Window_GetSize(Window* This) {
  return This->size;
}

Window* Window_Window(const int32_t* position, const uint32_t* size) {
  NSApplication* app = [NSApplication sharedApplication];
  NSRect         rect = NSMakeRect(position[0], position[1], size[0], size[1]);
  int mask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable |
             NSWindowStyleMaskResizable;
  NSWindow* window = [[NSWindow alloc] initWithContentRect:rect
                                                 styleMask:mask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  [window setAcceptsMouseMovedEvents:YES];
  // FIXME: we assume Dawn is using the system default device.
  // this could be wrong on multi-GPU systems.
  id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();

  CGSize cgSize;
  cgSize.width = size[0];
  cgSize.height = size[1];
  [window makeKeyAndOrderFront:NSApp];

  CAMetalLayer* layer = [CAMetalLayer layer];
  [layer setDevice:mtlDevice];
  [layer setPixelFormat:MTLPixelFormatBGRA8Unorm];
  [layer setFramebufferOnly:YES];
  [layer setDrawableSize:cgSize];
  [layer setColorspace:CGColorSpaceCreateDeviceRGB()];

  NSView* view = [[NSView alloc] initWithFrame:rect];
  [view setWantsLayer:YES];
  [view setLayer:layer];

  [window setContentView:view];
  Window*       w = new Window(window, view, layer, mtlDevice, size);
  id            delegate = [[ToucanWindowDelegate alloc] initWithWindow:w];
  [window setDelegate:delegate];
  return w;
}

void Window_Destroy(Window* This) { delete This; }

wgpu::TextureFormat GetPreferredSwapChainFormat() {
  return wgpu::TextureFormat::BGRA8Unorm;
}

SwapChain* SwapChain_SwapChain(int qualifiers, Type* format, Device* device, Window* window) {
  wgpu::SurfaceConfiguration config;
  config.device = device->device;
  config.format = ToDawnTextureFormat(format);

  config.width = window->size[0];
  config.height = window->size[1];
  config.presentMode = wgpu::PresentMode::Fifo;

  wgpu::SurfaceDescriptorFromMetalLayer metalLayerDesc;
  metalLayerDesc.layer = window->layer;
  wgpu::SurfaceDescriptor desc;
  desc.nextInChain = &metalLayerDesc;
  static wgpu::Instance instance = wgpu::CreateInstance({});
  wgpu::Surface surface = instance.CreateSurface(&desc);

  surface.Configure(&config);

  return new SwapChain(surface, {config.width, config.height, 1}, config.format, [[NSAutoreleasePool alloc] init]);
}

void SwapChain_Present(SwapChain* swapChain) {
  swapChain->surface.Present();
  [static_cast<NSAutoreleasePool*>(swapChain->pool) release];
  swapChain->pool = [[NSAutoreleasePool alloc] init];
}

void SwapChain_Destroy(SwapChain* This) {
  [static_cast<NSAutoreleasePool*>(This->pool) release];
  delete This;
}

Device* Device_Device() {
  wgpu::Device device = CreateDawnDevice(wgpu::BackendType::Metal, PrintDeviceError);
  if (!device) { return nullptr; }
  return new Device(device);
}

bool System_IsRunning() { return gIsRunning; }

bool System_HasPendingEvents() {
  NSApplication* app = [NSApplication sharedApplication];
  NSEvent*       nsEvent = [app nextEventMatchingMask:NSEventMaskAny
                                      untilDate:nil
                                         inMode:NSDefaultRunLoopMode
                                        dequeue:NO];
  return nsEvent != nullptr;
}

Event* System_GetNextEvent() {
  if (!gInitialized) {
    Initialize();
    gInitialized = true;
  }
  NSApplication* app = [NSApplication sharedApplication];
  NSEvent*       nsEvent = [app nextEventMatchingMask:NSEventMaskAny
                                      untilDate:[NSDate distantFuture]
                                         inMode:NSDefaultRunLoopMode
                                        dequeue:YES];
  [NSApp sendEvent:nsEvent];
  Event* event = new Event();
  int    height = [[nsEvent.window contentView] frame].size.height;
  event->mousePos[0] = nsEvent.locationInWindow.x;
  event->mousePos[1] = height - nsEvent.locationInWindow.y;
  event->modifiers = ToToucanEventModifiers(nsEvent.modifierFlags);
  event->button = 0;
  event->type = EventType::Unknown;

  switch (nsEvent.type) {
    case NSEventTypeLeftMouseDown:
      event->type = EventType::MouseDown;
      event->button = 0;
      break;
    case NSEventTypeRightMouseDown:
      event->type = EventType::MouseDown;
      event->button = 2;
      break;
    case NSEventTypeMouseEntered: break;
    case NSEventTypeMouseExited: break;
    case NSEventTypeLeftMouseUp:
      event->type = EventType::MouseUp;
      event->button = 0;
      break;
    case NSEventTypeRightMouseUp:
      event->type = EventType::MouseUp;
      event->button = 2;
      break;
    case NSEventTypeOtherMouseDown:
      event->type = EventType::MouseDown;
      event->button = 1;
      break;
    case NSEventTypeOtherMouseUp:
      event->type = EventType::MouseUp;
      event->button = 1;
      break;
    case NSEventTypeKeyDown: break;
    case NSEventTypeKeyUp: break;
    case NSEventTypeMouseMoved:
    case NSEventTypeLeftMouseDragged:
    case NSEventTypeRightMouseDragged:
      if (nsEvent.window) { event->type = EventType::MouseMove; }
      break;
    case NSEventTypeAppKitDefined:
      switch ([nsEvent subtype]) {
        case NSEventSubtypeWindowExposed: break;
        case NSEventSubtypeApplicationActivated: break;
        case NSEventSubtypeScreenChanged: break;
        case NSEventSubtypeWindowMoved: break;
        default: break;
      }
      break;
    case NSEventTypeApplicationDefined: break;
    case NSEventTypeCursorUpdate: break;
    case NSEventTypeSystemDefined: break;
    case NSEventTypeFlagsChanged: break;
    case NSEventTypePeriodic: break;
    case NSEventTypeQuickLook: break;
    default: event->type = EventType::Unknown;
  }
  return event;
}

const uint32_t* System_GetScreenSize() {
  gScreenSize[0] = [[NSScreen mainScreen] frame].size.width;
  gScreenSize[1] = [[NSScreen mainScreen] frame].size.height;
  return gScreenSize;
}

double System_GetCurrentTime() {
  struct timeval now;

  gettimeofday(&now, NULL);
  return static_cast<double>(now.tv_sec) + static_cast<double>(now.tv_usec) / 1000000.0;
}

};  // namespace Toucan

@implementation ToucanWindowDelegate
- (instancetype)initWithWindow:(Toucan::Window*)w {
  self = [super init];
  if (self != nil) window = w;

  return self;
}

- (BOOL)windowShouldClose:(id)sender {
  return YES;
}

@end

@implementation ToucanAppDelegate : NSObject
- (id)init {
  self = [super init];
  gIsRunning = true;
  return self;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender {
  gIsRunning = false;
  return NSTerminateCancel;
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
  [NSApp stop:nil];
}
@end
