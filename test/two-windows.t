Device* device = new Device();
Queue* queue = device.GetQueue();
Window* window1 = new Window(device, 0, 0, 640, 480);
Window* window2 = new Window(device, 100, 100, 640, 480);
auto swapChain1 = new SwapChain<PreferredSwapChainFormat>(window1);
auto swapChain2 = new SwapChain<PreferredSwapChainFormat>(window2);
auto framebuffer1 = swapChain1.GetCurrentTexture();
auto framebuffer2 = swapChain2.GetCurrentTexture();
CommandEncoder* encoder = new CommandEncoder(device);
RenderPassEncoder* passEncoder1 = encoder.BeginRenderPass(framebuffer1, null, 0.0, 1.0, 0.0, 1.0);
passEncoder1.End();
RenderPassEncoder* passEncoder2 = encoder.BeginRenderPass(framebuffer2, null, 0.0, 0.0, 1.0, 1.0);
passEncoder2.End();
device.GetQueue().Submit(encoder.Finish());
swapChain1.Present();
swapChain2.Present();

while (System.IsRunning()) System.GetNextEvent();
return 0.0;
