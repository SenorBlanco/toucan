using Vertex = float<4>;
var device = new Device();
var window = new Window({0, 0}, System.GetScreenSize());
var swapChain = new SwapChain<PreferredSwapChainFormat>(device, window);
var verts : Vertex[3] = { { 0.0, 1.0, 0.0, 1.0 }, {-1.0, -1.0, 0.0, 1.0 }, { 1.0, -1.0, 0.0, 1.0 } };
var vb = new vertex Buffer<Vertex[]>(device, &verts);
class Pipeline {
  static deviceonly Vertex helper(vertex Buffer<Vertex[]>* v) { return v.Get(); }
  void vertexShader(VertexBuiltins^ vb) vertex { vb.position = Pipeline.helper(vertices); }
  void fragmentShader(FragmentBuiltins^ fb) fragment { fragColor.Set( {0.0, 1.0, 0.0, 1.0} ); }
  var vertices : vertex Buffer<Vertex[]>*;
  var fragColor : ColorAttachment<PreferredSwapChainFormat>*;
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
