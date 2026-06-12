#include "api.t"

var device = new Device();
var window = new Window(System.GetScreenSize());
var swapChain = new SwapChain<RGBA16float>(device, window);
var framebuffer = swapChain.GetCurrentTexture();
var encoder = new CommandEncoder(device);
class Pipeline {
  var color : *ColorOutput<RGBA16float>;
}
var fb = framebuffer.CreateColorOutput(LoadOp.Clear, StoreOp.Store, float<4>(10.0, 1.0, 1.0, 1.0));
var renderPass = new RenderPass<Pipeline>(encoder, { fb });
renderPass.End();
device.GetQueue().Submit(encoder.Finish());
swapChain.Present();

while (System.IsRunning()) System.GetNextEvent();
