class Vertex {
  float<4> position;
  float<3> color;
}

Device* device = new Device();
Window* window = new Window({0, 0}, {640, 480});
var swapChain = new SwapChain<PreferredSwapChainFormat>(device, window);
Vertex[3] verts = {
  { position = { 0.0,  1.0, 0.0, 1.0 }, color = { 1.0, 0.0, 0.0 } },
  { position = {-1.0, -1.0, 0.0, 1.0 }, color = { 0.0, 1.0, 0.0 } },
  { position = { 1.0, -1.0, 0.0, 1.0 }, color = { 0.0, 0.0, 1.0 } }
};

var vb = new vertex Buffer<Vertex[]>(device, &verts);
class Pipeline {
  float<3> vertexShader(VertexBuiltins^ vb) vertex {
    Vertex v = vertices.Get();
    vb.position = v.position;
    return v.color;
  }
  void fragmentShader(FragmentBuiltins^ fb, float<3> varyings) fragment {
    fragColor.Set(float<4>(varyings.r, varyings.g, varyings.b, 1.0));
  }
  ColorAttachment<PreferredSwapChainFormat>* fragColor;
  vertex Buffer<Vertex[]>* vertices;
}
var pipeline = new RenderPipeline<Pipeline>(device, null, TriangleList);
var encoder = new CommandEncoder(device);
var fb = new ColorAttachment<PreferredSwapChainFormat>(swapChain.GetCurrentTexture(), Clear, Store);
var renderPass = new RenderPass<Pipeline>(encoder, { vertices = vb, fragColor = fb });
renderPass.SetPipeline(pipeline);
renderPass.Draw(3, 1, 0, 0);
renderPass.End();
device.GetQueue().Submit(encoder.Finish());
swapChain.Present();
while (System.IsRunning()) System.GetNextEvent();
