Device* device = new Device();
Queue* queue = device.GetQueue();
Window* window1 = new Window(device, 0, 0, 640, 480);
Window* window2 = new Window(device, 100, 100, 640, 480);
SwapChain* swapChain1 = new SwapChain(window1);
SwapChain* swapChain2 = new SwapChain(window2);
while (System.IsRunning()) {
  System.GetNextEvent();
  renderable Texture2DView* framebuffer1 = swapChain1.GetCurrentTextureView();
  renderable Texture2DView* framebuffer2 = swapChain2.GetCurrentTextureView();
  CommandEncoder* encoder = new CommandEncoder(device);
  RenderPassEncoder* passEncoder1 = encoder.BeginRenderPass(framebuffer1, null, 0.0, 1.0, 0.0, 1.0);
  passEncoder1.End();
  RenderPassEncoder* passEncoder2 = encoder.BeginRenderPass(framebuffer2, null, 0.0, 0.0, 1.0, 1.0);
  passEncoder2.End();
  CommandBuffer* cb = encoder.Finish();
  queue.Submit(cb);
  swapChain1.Present();
  swapChain2.Present();
}
return 0.0;