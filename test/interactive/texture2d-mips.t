class Vertex {
  var position : float<2>;
  var texCoord : float<2>;
};

class Bindings {
  var sampler : *Sampler;
  var textureView : *SampleableTexture2D<float>;
}

class Pipeline {
    vertex main(vb : &VertexBuiltins) : float<2> {
        var v = vertices.Get();
        vb.position = {@v.position, 0.0, 1.0};
        return v.texCoord;
    }
    fragment main(fb : &FragmentBuiltins, texCoord : float<2>) {
      var b = bindings.Get();
      fragColor.Set(b.textureView.Sample(b.sampler, texCoord));
    }
    var vertices : *VertexInput<Vertex>;
    var indices : *index Buffer<[]uint>;
    var fragColor : *ColorOutput<PreferredPixelFormat>;
    var bindings : *BindGroup<Bindings>;
};
var device = new Device();
var window = new Window({640, 480});
var swapChain = new SwapChain<PreferredPixelFormat>(device, window);
var verts = [4]Vertex{
  { position = {-1.0,  1.0}, texCoord = {0.0, 0.0} },
  { position = { 1.0,  1.0}, texCoord = {1.0, 0.0} },
  { position = {-1.0, -1.0}, texCoord = {0.0, 1.0} },
  { position = { 1.0, -1.0}, texCoord = {1.0, 1.0} }
};
var indices = [6]uint{ 0, 1, 2, 1, 2, 3 };
var vb = new vertex Buffer<[]Vertex>(device, &verts);
var pipeline = new RenderPipeline<Pipeline>(device);
var tex = new sampleable Texture2D<RGBA8unorm>(device, {2, 2}, 2u);
var width = tex.MinBufferWidth();
var buffer = new hostwriteable Buffer<[]ubyte<4>>(device, 2 * width);
{
  var data = buffer.MapWrite();
  data[0] =         {255ub,   0ub,   0ub, 255ub};
  data[1] =         {  0ub, 255ub,   0ub, 255ub};
  data[width    ] = {  0ub,   0ub, 255ub, 255ub};
  data[width + 1] = {  0ub, 255ub, 255ub, 255ub};
}
var copyEncoder = new CommandEncoder(device);
tex.CopyFromBuffer(copyEncoder, buffer, {2, 2}, {0, 0}, 0u);
var buffer2 = new hostwriteable Buffer<[]ubyte<4>>(device, 1);
{
  var data = buffer2.MapWrite();
  data[0] =         {255ub, 255ub, 255ub, 255ub};
}
tex.CopyFromBuffer(copyEncoder, buffer, {1, 1}, {0, 0}, 1u);
device.GetQueue().Submit(copyEncoder.Finish());
var bindGroup = new BindGroup<Bindings>(device, {
  sampler = new Sampler(device),
  textureView = tex.CreateSampleableView()
});

var encoder = new CommandEncoder(device);
var p = Pipeline{
  vertices = new VertexInput<Vertex>(vb),
  indices = new index Buffer<[]uint>(device, &indices),
  fragColor = swapChain.GetCurrentTexture().CreateColorOutput(LoadOp.Clear),
  bindings = bindGroup
};
var renderPass = new RenderPass<Pipeline>(encoder, &p);
renderPass.SetPipeline(pipeline);
renderPass.DrawIndexed(6, 1, 0, 0, 0);
renderPass.End();
device.GetQueue().Submit(encoder.Finish());
swapChain.Present();

while (System.IsRunning()) System.GetNextEvent();
