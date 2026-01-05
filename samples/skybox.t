include "cube.t"
include "cube-loader.t"
include "event-handler.t"
include "mipmap-generator.t"
include "quaternion.t"
include "transform.t"

class Vertex {
  var position : <3>float;
  var normal : <3>float;
}

var device = new Device();

var texture = new sampleable renderable TextureCube<RGBA8unorm>(device, {2176, 2176}, 12);
var loader = CubeLoader<RGBA8unorm>{device, texture};
loader.Load(inline("third_party/home-cube/right.jpg"), 0);
loader.Load(inline("third_party/home-cube/left.jpg"), 1);
loader.Load(inline("third_party/home-cube/top.jpg"), 2);
loader.Load(inline("third_party/home-cube/bottom.jpg"), 3);
loader.Load(inline("third_party/home-cube/front.jpg"), 4);
loader.Load(inline("third_party/home-cube/back.jpg"), 5);

MipmapGenerator<RGBA8unorm>.Generate(device, texture);

var window = new Window(System.GetScreenSize());
var swapChain = new SwapChain<PreferredPixelFormat>(device, window);

var cubeVB = new vertex Buffer<[]<3>float>(device, &cubeVerts);
var cubeInput = new VertexInput<<3>float>(cubeVB);
var cubeIB = new index Buffer<[]uint>(device, &cubeIndices);

class Uniforms {
  var model       : <4><4>float;
  var view        : <4><4>float;
  var projection  : <4><4>float;
}

class Bindings {
  var sampler : *Sampler;
  var textureView : *SampleableTextureCube<float>;
  var uniforms : *uniform Buffer<Uniforms>;
}

class SkyboxPipeline {
    vertex main(vb : &VertexBuiltins) : <3>float {
        var v = vertices.Get();
        var uniforms = bindings.Get().uniforms.MapRead();
        var pos = <4>float(@v, 1.0);
        vb.position = uniforms.projection * uniforms.view * uniforms.model * pos;
        return v;
    }
    fragment main(fb : &FragmentBuiltins, position : <3>float) {
      var p = Math.normalize(position);
      var b = bindings.Get();
      // TODO: figure out why the skybox is X-flipped
      fragColor.Set(b.textureView.Sample(b.sampler, <3>float(-p.x, p.y, p.z)));
    }
    var vertices : *VertexInput<<3>float>;
    var indices : *index Buffer<[]uint>;
    var fragColor : *ColorOutput<PreferredPixelFormat>;
    var depth : *DepthStencilOutput<Depth24Plus>;
    var bindings : *BindGroup<Bindings>;
};

var cubePipeline = new RenderPipeline<SkyboxPipeline>(device);
var cubeBindings = Bindings{
  uniforms = new uniform Buffer<Uniforms>(device),
  sampler = new Sampler(device),
  textureView = texture.CreateSampleableView()
};
var cubeBindGroup = new BindGroup<Bindings>(device, &cubeBindings);

var handler = EventHandler{ distance = 10.0 };
var windowSize = window.GetSize();
var aspectRatio = windowSize.x as float / windowSize.y as float;
var projection = Transform.projection(0.5, 200.0, -aspectRatio, aspectRatio, -1.0, 1.0);
var depthBuffer = new renderable Texture2D<Depth24Plus>(device, window.GetSize());
while (System.IsRunning()) {
  var orientation = Quaternion(<3>float(0.0, 1.0, 0.0), handler.rotation.x);
  orientation = orientation.mul(Quaternion(<3>float(1.0, 0.0, 0.0), handler.rotation.y));
  orientation.normalize();
  var uniforms : Uniforms;
  uniforms.projection = projection;
  uniforms.view = Transform.translation({0.0, 0.0, -handler.distance});
  uniforms.view *= orientation.toMatrix();
  uniforms.model = Transform.scale({100.0, 100.0, 100.0});
  cubeBindings.uniforms.SetData(&uniforms);
  var encoder = new CommandEncoder(device);
  var p : SkyboxPipeline;
  var fb = swapChain.GetCurrentTexture().CreateColorOutput(LoadOp.Clear);
  var db = depthBuffer.CreateDepthStencilOutput(LoadOp.Clear);
  var renderPass = new RenderPass<SkyboxPipeline>(encoder,
    { fragColor = fb, depth = db, vertices = cubeInput, indices = cubeIB, bindings = cubeBindGroup }
  );

  renderPass.SetPipeline(cubePipeline);
  renderPass.DrawIndexed(cubeIndices.length, 1, 0, 0, 0);

  renderPass.End();
  var cb = encoder.Finish();
  device.GetQueue().Submit(cb);
  swapChain.Present();

  do {
    handler.Handle(System.GetNextEvent());
  } while (System.HasPendingEvents());
}
