#include "api.t"
#include "transform.t"

class Vertex {
  var position : float<2>;
  var texCoord : float<2>;
};

class Matrix {
  Matrix(imageSize : uint<2>, windowSize : uint<2>) {
    var imageAspect = imageSize.x as float / imageSize.y as float;
    var windowAspect = windowSize.x as float / windowSize.y as float;
    if (imageAspect > windowAspect) {
      m = Transform.scale({1.0, windowAspect / imageAspect, 1.0});
    } else {
      m = Transform.scale({imageAspect / windowAspect, 1.0, 1.0});
    }
  }
  var m : float<4,4>;
};

class Uniforms {
  var matrix   : Matrix;
  var mousePos : float<2>;
  var clamp    : uint;
}

class Bindings {
  var sampler : *Sampler;
  var textureView : *SampleableTexture2D<float>;
  var uniforms : *uniform Buffer<Uniforms>;
}

class Pipeline {
    vertex main(vb : &VertexBuiltins) : float<2> {
        var matrix = bindings.Get().uniforms.MapRead().matrix.m;
        var v = vertices.Get();
        vb.position = matrix * float<4>{@v.position, 0.0, 1.0};
        return v.texCoord;
    }
    fragment main(fb : &FragmentBuiltins, texCoord : float<2>) {
      var b = bindings.Get();
      var u = b.uniforms.MapRead();
      var color = b.textureView.Sample(b.sampler, texCoord);
      var distanceToMouse = Math.length(u.mousePos - fb.fragCoord.xy);
      const maxDistance = 200.0;
      var scale = Math.max((maxDistance - distanceToMouse) * 0.5, 1.0);
      color *= scale;
      if (u.clamp != 0u) {
        color = Math.min(color, float<4>{1.0});
      }
      fragColor.Set(color);
    }
    var vertices : *VertexInput<Vertex>;
    var indices : *index Buffer<[]uint>;
    var fragColor : *ColorOutput<RGBA16float>;
    var bindings : *BindGroup<Bindings>;
};

var device = new Device();
var image = new Image<RGBA16float>(inline("third_party/home-cube/montreal-sunset-hdr.jpg"));
var imageSize = image.GetSize();
var texture = new sampleable Texture2D<RGBA16float>(device, imageSize);
var buffer = new hostwriteable Buffer<[]ushort<4>>(device, texture.MinBufferWidth() * imageSize.y);
image.Decode(buffer.MapWrite(), texture.MinBufferWidth());
var copyEncoder = new CommandEncoder(device);
texture.CopyFromBuffer(copyEncoder, buffer, imageSize);
device.GetQueue().Submit(copyEncoder.Finish());

var window = new Window(size = System.GetScreenSize(), hdr = true);
var swapChain = new SwapChain<RGBA16float>(device, window);
var verts = [4]Vertex{
  { position = {-1.0,  1.0}, texCoord = {0.0, 0.0} },
  { position = { 1.0,  1.0}, texCoord = {1.0, 0.0} },
  { position = {-1.0, -1.0}, texCoord = {0.0, 1.0} },
  { position = { 1.0, -1.0}, texCoord = {1.0, 1.0} }
};
var indices = [6]uint{ 0, 1, 2, 1, 2, 3 };
var vb = new vertex Buffer<[]Vertex>(device, &verts);
var ib = new index Buffer<[]uint>(device, &indices);
var pipeline = new RenderPipeline<Pipeline>(device);
var uniforms = Uniforms{ matrix = Matrix(imageSize, window.GetSize()) };
var bindings = Bindings{
  sampler = new Sampler(device),
  textureView = texture.CreateSampleableView(),
  uniforms = new uniform Buffer<Uniforms>(device, &uniforms)
};
var bindGroup = new BindGroup<Bindings>(device, &bindings);
var p = Pipeline{
  vertices = new VertexInput<Vertex>(vb),
  indices = ib,
  bindings = bindGroup
};
var touchMoved = false;
do {
  var encoder = new CommandEncoder(device);
  p.fragColor = swapChain.GetCurrentTexture().CreateColorOutput(LoadOp.Clear);
  var renderPass = new RenderPass<Pipeline>(encoder, &p);
  renderPass.SetPipeline(pipeline);
  renderPass.DrawIndexed(6, 1, 0, 0, 0);
  renderPass.End();
  device.GetQueue().Submit(encoder.Finish());
  swapChain.Present();
  do {
    var event = System.GetNextEvent();
    if (event.type == EventType.MouseDown) {
      uniforms.clamp = 1u - uniforms.clamp;
    } else if (event.type == EventType.TouchStart) {
      touchMoved = false;
    } else if (event.type == EventType.TouchEnd) {
      if (!touchMoved) {
        uniforms.clamp = 1u - uniforms.clamp;
      }
      touchMoved = false;
    } else if (event.type == EventType.MouseMove) {
      uniforms.mousePos = event.position as float<2>;
    } else if (event.type == EventType.TouchMove) {
      uniforms.mousePos = event.touches[0] as float<2>;
      touchMoved = true;
    } else if (event.type == EventType.Resize) {
      swapChain.Resize(window.GetSize());
      uniforms.matrix = Matrix(imageSize, window.GetSize());
    }
    bindings.uniforms.Set(&uniforms);
  } while (System.HasPendingEvents());
} while (System.IsRunning());
