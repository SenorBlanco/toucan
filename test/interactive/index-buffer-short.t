class Vertex {
  var position : float<4>;
  var color : float<4>;
};
using Varyings = float<4>;
var device = new Device();
var window = new Window({0, 0}, {640, 480});
var queue = device.GetQueue();
var swapChain = new SwapChain<PreferredSwapChainFormat>(device, window);
var verts : [4] Vertex;
verts[0] = { {-1.0, -1.0, 0.0, 1.0}, {1.0, 1.0, 1.0, 1.0} };
verts[1] = { { 1.0, -1.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0} };
verts[2] = { {-1.0,  1.0, 0.0, 1.0}, {0.0, 1.0, 0.0, 1.0} };
verts[3] = { { 1.0,  1.0, 0.0, 1.0}, {0.0, 0.0, 1.0, 1.0} };
var indices : [6] ushort = {0us, 1us, 2us, 1us, 2us, 3us};
var vb = new vertex Buffer<[]Vertex>(device, &verts);
var ib = new index Buffer<[]ushort>(device, &indices);
class Pipeline {
  vertex main(vb : ^VertexBuiltins) : Varyings {
    var v = vertices.Get();
    vb.position = v.position;
    return v.color;
  }
  fragment main(fb : ^FragmentBuiltins, v : Varyings) { fragColor.Set(v); }
  var vertices : *vertex Buffer<[]Vertex>;
  var indices : *index Buffer<[]ushort>;
  var fragColor : *ColorAttachment<PreferredSwapChainFormat>;
}
var pipeline = new RenderPipeline<Pipeline>(device, null, TriangleList);
var encoder = new CommandEncoder(device);
var fb = swapChain.GetCurrentTexture().CreateColorAttachment(Clear, Store);
var renderPass = new RenderPass<Pipeline>(encoder, { vertices = vb, indices = ib, fragColor = fb });
renderPass.SetPipeline(pipeline);
renderPass.DrawIndexed(6, 1, 0, 0, 0);
renderPass.End();
device.GetQueue().Submit(encoder.Finish());
swapChain.Present();

while (System.IsRunning()) System.GetNextEvent();
