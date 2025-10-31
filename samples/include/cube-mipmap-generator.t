class CubeResamplingUniforms {
  var targetSize : uint<2>;
}

class CubeResamplingBindings {
  var sampler : *Sampler;
  var texture : *SampleableTextureCube<float>;
  var uniforms : *uniform Buffer<CubeResamplingUniforms>;
}

var faceRotations = [6]float<3,3>{
  float<3,3>{ { 0.0,  0.0, -2.0 }, { 0.0, -2.0,  0.0 }, {  1.0,  1.0,   1.0 } },
  float<3,3>{ { 0.0,  0.0,  2.0 }, { 0.0, -2.0,  0.0 }, { -1.0,  1.0,  -1.0 } },   // neg-x
  float<3,3>{ { 2.0,  0.0,  0.0 }, { 0.0,  0.0,  2.0 }, { -1.0,  1.0,  -1.0 } },   // pos-y
  float<3,3>{ { 2.0,  0.0,  0.0 }, { 0.0,  0.0, -2.0 }, { -1.0, -1.0,   1.0 } },   // neg-y
  float<3,3>{ { 2.0,  0.0,  0.0 }, { 0.0, -2.0,  0.0 }, { -1.0,  1.0,   1.0 } },   // pos-z
  float<3,3>{ {-2.0,  0.0,  0.0 }, { 0.0, -2.0,  0.0 }, {  1.0,  1.0,  -1.0 } }    // neg-z
};

class CubeResamplingPipeline {
  vertex main(vb : &VertexBuiltins) : float<2> {
    var verts = [6]float<2>{
      { -1.0, -1.0 }, { 1.0, -1.0 }, { -1.0, 1.0 },
      { -1.0,  1.0 }, { 1.0, -1.0 }, {  1.0, 1.0 }
    };
    var v = verts[vb.vertexIndex];
    vb.position = {@v, 0.0, 1.0};
    return float<2>{1.0, 0.0} * float<2>{0.5, -0.5} + float<2>{0.5}; // FIXME
  }
  fragment main(fb : &FragmentBuiltins, texCoord : float<2>) {
    var b = bindings.Get();
    fragColor.Set(b.texture.Sample(b.sampler, float<3>{texCoord, 1.0}));
  }
  var fragColor : *ColorOutput<RGBA8unorm>;
  var bindings : *BindGroup<CubeResamplingBindings>;
};

class CubeMipmapGenerator {
  static Generate(device : *Device, texture : *renderable sampleable TextureCube<RGBA8unorm>) {
    var resamplingPipeline = new RenderPipeline<CubeResamplingPipeline>(device);
    var mipCount = 30 - Math.clz(texture.GetSize().x);

    var resamplingBindings : CubeResamplingBindings;
    resamplingBindings.sampler = new Sampler(device);
    resamplingBindings.uniforms = new uniform Buffer<CubeResamplingUniforms>(device);

    for (var mipLevel = 1u; mipLevel < mipCount; ++mipLevel) {
      resamplingBindings.texture = texture.CreateSampleableView(mipLevel - 1, 1u);
      resamplingBindings.uniforms.SetData({ targetSize = texture.GetSize(mipLevel) });
      var fb = texture.CreateRenderableView(mipLevel);
      var encoder = new CommandEncoder(device);
      var renderPass = new RenderPass<CubeResamplingPipeline>(encoder, {
        fragColor = fb.CreateColorOutput(LoadOp.Clear),
        bindings = new BindGroup<CubeResamplingBindings>(device, &resamplingBindings)
      });
      renderPass.SetPipeline(resamplingPipeline);
      renderPass.Draw(6, 1, 0, 0);
      renderPass.End();
      device.GetQueue().Submit(encoder.Finish());
    }
  }
}
