include "event-handler.t"
include "quaternion.t"
include "transform.t"

class Vertex {
  var position: float<3>;
  var texCoord: float<2>;
}

var cubeVertices = [24]Vertex(
  // Right face
  { { 1.0, -1.0, -1.0}, {0.0, 0.0} },
  { { 1.0, -1.0,  1.0}, {0.0, 1.0} },
  { { 1.0,  1.0,  1.0}, {1.0, 1.0} },
  { { 1.0,  1.0, -1.0}, {1.0, 0.0} },

  // Left face
  { {-1.0, -1.0, -1.0}, {0.0, 0.0} },
  { {-1.0,  1.0, -1.0}, {0.0, 1.0} },
  { {-1.0,  1.0,  1.0}, {1.0, 1.0} },
  { {-1.0, -1.0,  1.0}, {1.0, 0.0} },

  // Bottom face
  { {-1.0, -1.0, -1.0}, {0.0, 0.0} },
  { { 1.0, -1.0, -1.0}, {0.0, 1.0} },
  { { 1.0, -1.0,  1.0}, {1.0, 1.0} },
  { {-1.0, -1.0,  1.0}, {1.0, 0.0} },

  // Top face
  { {-1.0,  1.0, -1.0}, {0.0, 0.0} },
  { {-1.0,  1.0,  1.0}, {0.0, 1.0} },
  { { 1.0,  1.0,  1.0}, {1.0, 1.0} },
  { { 1.0,  1.0, -1.0}, {1.0, 0.0} },

  // Front face
  { {-1.0, -1.0, -1.0}, {0.0, 0.0} },
  { { 1.0, -1.0, -1.0}, {0.0, 1.0} },
  { { 1.0,  1.0, -1.0}, {1.0, 1.0} },
  { {-1.0,  1.0, -1.0}, {1.0, 0.0} },

  // Back face
  { {-1.0, -1.0,  1.0}, {0.0, 0.0} },
  { { 1.0, -1.0,  1.0}, {0.0, 1.0} },
  { { 1.0,  1.0,  1.0}, {1.0, 1.0} },
  { {-1.0,  1.0,  1.0}, {1.0, 0.0} }
);

var cubeIndices = [36]uint(
  0,  1,   2,  0,  2,  3,
  4,  5,   6,  4,  6,  7,
  8,  9,  10,  8, 10, 11,
  12, 13, 14, 12, 14, 15,
  16, 17, 18, 16, 18, 19,
  20, 21, 22, 20, 22, 23
);

var device = new Device();
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

var window = new Window(System.GetScreenSize());
var swapChain = new SwapChain<PreferredPixelFormat>(device, window);

class Uniforms {
  var model       : float<4,4>;
  var view        : float<4,4>;
  var projection  : float<4,4>;
}

class Bindings {
  var sampler : *Sampler;
  var textureView : *SampleableTexture2D<float>;
  var uniforms : *uniform Buffer<Uniforms>;
}

class DrawPipeline {
    vertex main(vb : &VertexBuiltins) : float<2> {
        var v = vertices.Get();
        var uniforms = bindings.Get().uniforms.MapRead();
        var pos = float<4>(@v.position, 1.0);
        vb.position = uniforms.projection * uniforms.view * uniforms.model * pos;
        return v.texCoord;
    }

    fragment main(fb : &FragmentBuiltins, texCoord : float<2>) {
      var b = bindings.Get();
      fragColor.Set(b.textureView.Sample(b.sampler, texCoord));
    }

    var vertices : *VertexInput<Vertex>;
    var indexBuffer : *index Buffer<[]uint>;
    var fragColor : *ColorOutput<PreferredPixelFormat>;
    var depth : *DepthStencilOutput<Depth24Plus>;
    var bindings : *BindGroup<Bindings>;
};

var pipeline = new RenderPipeline<DrawPipeline>(device);
var bindings = Bindings{
  sampler = new Sampler(device),
  textureView = texture.CreateSampleableView(),
  uniforms = new uniform Buffer<Uniforms>(device)
};

var vb = new vertex Buffer<[]Vertex>(device, &cubeVertices);
var pipelineData = DrawPipeline{
  vertices = new VertexInput<Vertex>(vb),
  indexBuffer = new index Buffer<[]uint>(device, &cubeIndices),
  bindings = new BindGroup<Bindings>(device, &bindings)
};

var handler = EventHandler{ distance = 10.0 };
var teapotQuat = Quaternion(float<3>(1.0, 0.0, 0.0), -3.1415926 / 2.0);
teapotQuat.normalize();
var teapotRotation = teapotQuat.toMatrix();
var depthBuffer = new renderable Texture2D<Depth24Plus>(device, window.GetSize());
var uniforms : Uniforms;
var prevWindowSize = uint<2>{0, 0};
while (System.IsRunning()) {
  var orientation = Quaternion(float<3>(0.0, 1.0, 0.0), handler.rotation.x);
  orientation = orientation.mul(Quaternion(float<3>(1.0, 0.0, 0.0), handler.rotation.y));
  orientation.normalize();
  var newSize = window.GetSize();
  if (Math.any(newSize != prevWindowSize)) {
    swapChain.Resize(newSize);
    depthBuffer = new renderable Texture2D<Depth24Plus>(device, newSize);
    var aspectRatio = (float) newSize.x / (float) newSize.y;
    uniforms.projection = Transform.projection(0.5, 200.0, -aspectRatio, aspectRatio, -1.0, 1.0);
    prevWindowSize = newSize;
  }
  uniforms.view = Transform.translation({0.0, 0.0, -handler.distance});
  uniforms.view *= orientation.toMatrix();
  uniforms.model = Transform.scale({1.0, 1.0, 1.0});
  bindings.uniforms.SetData(&uniforms);
  uniforms.model = teapotRotation * Transform.scale({2.0, 2.0, 2.0});
  var encoder = new CommandEncoder(device);
  var fb = swapChain.GetCurrentTexture().CreateColorOutput(LoadOp.Clear);
  var db = depthBuffer.CreateDepthStencilOutput(LoadOp.Clear);
  var renderPass = new RenderPass<DrawPipeline>(encoder, { fragColor = fb, depth = db });

  var cubePass = new RenderPass<DrawPipeline>(renderPass);
  cubePass.SetPipeline(pipeline);
  cubePass.Set(&pipelineData);
  cubePass.DrawIndexed(cubeIndices.length, 1, 0, 0, 0);

  renderPass.End();
  var cb = encoder.Finish();
  device.GetQueue().Submit(cb);
  swapChain.Present();

  do {
    handler.Handle(System.GetNextEvent());
  } while (System.HasPendingEvents());
}
