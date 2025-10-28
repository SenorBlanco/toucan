class Vertex {
  var position : float<2>;
  var texCoord : float<2>;
}

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

var window = new Window(System.GetScreenSize());
var swapChain = new SwapChain<PreferredPixelFormat>(device, window);

var verts = [4]Vertex{
  { position = {-1.0,  1.0}, texCoord = {0.0, 0.0} },
  { position = { 1.0,  1.0}, texCoord = {1.0, 0.0} },
  { position = {-1.0, -1.0}, texCoord = {0.0, 1.0} },
  { position = { 1.0, -1.0}, texCoord = {1.0, 1.0} }
};

var indices = [6]uint{ 0, 1, 2, 1, 2, 3 };

var pipeline = new RenderPipeline<Pipeline>(device);
var encoder = new CommandEncoder(device);
var size = uint<2>{1024, 1024};
var mipCount = 11;
var texture = new sampleable Texture2D<RGBA8unorm>(device, size, mipCount);
var mipColors = [11]ubyte<4>{
  { 255ub,   0ub,   0ub, 255ub },
  { 255ub, 255ub,   0ub, 255ub },
  {   0ub, 255ub,   0ub, 255ub },
  {   0ub, 255ub, 255ub, 255ub },
  {   0ub,   0ub, 255ub, 255ub },
  { 255ub,   0ub, 255ub, 255ub },
  { 255ub, 255ub, 255ub, 255ub },
  { 255ub, 128ub,   0ub, 255ub },
  { 128ub, 255ub,   0ub, 255ub },
  {   0ub, 255ub, 128ub, 255ub },
  {   0ub, 128ub, 255ub, 255ub }
};
var width = texture.MinBufferWidth();
var mipSize = uint<2>{ width, size.y };
for (var mipLevel = 0; mipLevel < mipCount; ++mipLevel) {
  var buffer = new hostwriteable Buffer<[]ubyte<4>>(device, width * mipSize.y);
  var data = buffer.MapWrite();
  for (var y = 0u; y < mipSize.y; ++y) {
    for (var x = 0u; x < mipSize.x; ++x) {
      data[y * width + x] = mipColors[mipLevel];
    }
  }
  data = null;
  texture.CopyFromBuffer(encoder, buffer, mipSize, {0, 0}, mipLevel);
  mipSize.x /= 2;
  mipSize.y /= 2;
}
device.GetQueue().Submit(encoder.Finish());
var bindings = Bindings{
  sampler = new Sampler(device),
  textureView = texture.CreateSampleableView(baseMipLevel = 4)
};

var vb = new vertex Buffer<[]Vertex>(device, &verts);
var pipelineData = Pipeline{
  vertices = new VertexInput<Vertex>(vb),
  indices = new index Buffer<[]uint>(device, &indices),
  bindings = new BindGroup<Bindings>(device, &bindings)
};

var prevWindowSize = uint<2>{0, 0};
while (System.IsRunning()) {
  var newSize = window.GetSize();
  if (Math.any(newSize != prevWindowSize)) {
    swapChain.Resize(newSize);
    var aspectRatio = (float) newSize.x / (float) newSize.y;
    prevWindowSize = newSize;
  }
  var encoder = new CommandEncoder(device);
  var fb = swapChain.GetCurrentTexture().CreateColorOutput(LoadOp.Clear);
  var renderPass = new RenderPass<Pipeline>(encoder, { fragColor = fb });

  renderPass.SetPipeline(pipeline);
  renderPass.Set(&pipelineData);
  renderPass.DrawIndexed(indices.length, 1, 0, 0, 0);

  renderPass.End();
  var cb = encoder.Finish();
  device.GetQueue().Submit(cb);
  swapChain.Present();

  while (System.HasPendingEvents()) {
    System.GetNextEvent();
  }
}
