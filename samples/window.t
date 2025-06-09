var device = new Device();
var window = new Window(System.GetScreenSize());
var swapChain = new SwapChain<PreferredSwapChainFormat>(device, window);
var encoder = new CommandEncoder(device);
class Pipeline {
  var color : ColorAttachment<PreferredSwapChainFormat>;
}
var renderPass = new RenderPass<Pipeline>(encoder, {
  { texture = swapChain.GetCurrentTexture(), clearValue = float<4>(0.0, 1.0, 0.0, 1.0) } });
renderPass.End();
device.GetQueue().Submit(encoder.Finish());
swapChain.Present();

while (System.IsRunning()) System.GetNextEvent();
