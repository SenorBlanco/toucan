class Vertex {
  var position : float<2>;
  var texCoord : float<2>;
}

class Transform3 {
  static Scale(v : float<2>) : float<3,3> {
    return float<3,3>{float<3>{v.x, 0.0, 0.0},
                      float<3>{0.0, v.y, 0.0},
                      float<3>{0.0, 0.0, 1.0}};
  }
  static Translation(v : float<2>) : float<3,3> {
    return float<3,3>{float<3>{1.0, 0.0, 0.0},
                      float<3>{0.0, 1.0, 0.0},
                      float<3>{v.x, v.y, 1.0}};
  }
}

class Uniforms {
  var matrix : float<3,3>;
}

class Bindings {
  var sampler : *Sampler;
  var texture : *SampleableTexture2D<float>;
  var uniforms : *uniform Buffer<Uniforms>;
}

class Pipeline {
    vertex main(vb : &VertexBuiltins) : float<2> {
        var u = bindings.Get().uniforms.MapRead();
        var verts = [6]float<2>{
          { 0.0, 0.0 }, { 1.0, 0.0 }, { 0.0, 1.0 },
          { 0.0, 1.0 }, { 1.0, 0.0 }, { 1.0, 1.0 }
        };
        var v = verts[vb.vertexIndex];
        vb.position = {@(u.matrix * float<3>{@v, 1.0}), 1.0};
        return float<2>{v.x, 1.0 - v.y};
    }
    fragment main(fb : &FragmentBuiltins, texCoord : float<2>) {
      var b = bindings.Get();
      fragColor.Set(b.texture.Sample(b.sampler, texCoord));
    }
    var fragColor : *ColorOutput<BGRA8unorm>;
    var bindings : *BindGroup<Bindings>;
};

class ResamplingBindings {
  var sampler : *Sampler;
  var texture : *SampleableTexture2D<float>;
  var uniforms : *uniform Buffer<Uniforms>;
}

class ResamplingPipeline {
    vertex main(vb : &VertexBuiltins) : float<2> {
        var verts = [6]float<2>{
          { 0.0, 0.0 }, { 1.0, 0.0 }, { 0.0, 1.0 },
          { 0.0, 1.0 }, { 1.0, 0.0 }, { 1.0, 1.0 }
        };
        var v = verts[vb.vertexIndex];
        vb.position = {@(v * 2.0 - float<2>(1.0)), 0.0, 1.0};
        return float<2>(v.x, 1.0 - v.y);
    }
    fragment main(fb : &FragmentBuiltins, texCoord : float<2>) {
      var b = bindings.Get();
      fragColor.Set(b.texture.Sample(b.sampler, texCoord));
    }
    var fragColor : *ColorOutput<BGRA8unorm>;
    var bindings : *BindGroup<ResamplingBindings>;
};

var device = new Device();

var window = new Window({1023 + 11, 512});
var swapChain = new SwapChain<BGRA8unorm>(device, window);
var image = new Image<BGRA8unorm>(inline("third_party/libjpeg-turbo/testimages/testorig.jpg"));
var imageSize = image.GetSize();

var verts = [4]Vertex{
  { position = { 0.0,  1.0}, texCoord = {0.0, 0.0} },
  { position = { 1.0,  1.0}, texCoord = {1.0, 0.0} },
  { position = { 0.0,  0.0}, texCoord = {0.0, 1.0} },
  { position = { 1.0,  0.0}, texCoord = {1.0, 1.0} }
};

var pipeline = new RenderPipeline<Pipeline>(device);
var resamplingPipeline = new RenderPipeline<ResamplingPipeline>(device);
var encoder = new CommandEncoder(device);
var texSize = imageSize;
var mipCount = 8;
var texture = new renderable sampleable Texture2D<BGRA8unorm>(device, imageSize, mipCount);
var buffer = new hostwriteable Buffer<[]ubyte<4>>(device, texture.MinBufferWidth() * imageSize.y);
image.Decode(buffer.MapWrite(), texture.MinBufferWidth());
var copyEncoder = new CommandEncoder(device);
texture.CopyFromBuffer(copyEncoder, buffer, imageSize);
device.GetQueue().Submit(copyEncoder.Finish());

var resamplingBindings : ResamplingBindings;
resamplingBindings.sampler = new Sampler(device);

var mipSize = uint<2>{ texSize.x, texSize.y };
for (var mipLevel = 0u; mipLevel < mipCount - 1; ++mipLevel) {
  resamplingBindings.texture = texture.CreateSampleableView(baseMipLevel = mipLevel, mipLevelCount = 1);
  var fb = texture.CreateRenderableView(mipLevel + 1u);
  var matrix = Transform3.Scale({1.0, 1.0});
  resamplingBindings.uniforms = new uniform Buffer<Uniforms>(device, { matrix = matrix });

  var dummy : Pipeline;
  dummy.fragColor = fb.CreateColorOutput(LoadOp.Clear);
  var renderPass = new RenderPass<ResamplingPipeline>(encoder, {
    fragColor = fb.CreateColorOutput(LoadOp.Clear),
    bindings = new BindGroup<ResamplingBindings>(device, &resamplingBindings)
  });
  renderPass.SetPipeline(resamplingPipeline);
  renderPass.Draw(6, 1, 0, 0);
  renderPass.End();

  mipSize.x /= 2;
  mipSize.y /= 2;
}

device.GetQueue().Submit(encoder.Finish());

var bindings : Bindings;

var viewMatrix = Transform3.Translation({-1.0, -1.0});
viewMatrix *= Transform3.Scale(2.0 / (float<2>)window.GetSize());

bindings.sampler = new Sampler(device);

while (System.IsRunning()) {
  var encoder = new CommandEncoder(device);
  var fb = swapChain.GetCurrentTexture().CreateColorOutput(LoadOp.Load);

  var position = int<2>{0, 0};
  var size = texSize;
  for (var mipLevel = 0; mipLevel < mipCount; ++mipLevel) {
    bindings.texture = texture.CreateSampleableView(baseMipLevel = mipLevel, mipLevelCount = 1);
    var modelMatrix = Transform3.Translation((float<2>) position);
    modelMatrix *= Transform3.Scale((float<2>) size);
    bindings.uniforms = new uniform Buffer<Uniforms>(device, { matrix = viewMatrix * modelMatrix });

    var renderPass = new RenderPass<Pipeline>(encoder, {
      fragColor = fb,
      bindings = new BindGroup<Bindings>(device, &bindings)
    });
    renderPass.SetPipeline(pipeline);
    renderPass.Draw(6, 1, 0, 0);
    renderPass.End();

    position.x += size.x + 1;
    size /= int<2>{2};
  }
  
  var cb = encoder.Finish();
  device.GetQueue().Submit(cb);
  swapChain.Present();

  while (System.HasPendingEvents()) {
    System.GetNextEvent();
  }
}
