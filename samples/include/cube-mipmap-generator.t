class CubeResamplingUniforms {
  var face : uint;
}

class CubeResamplingBindings {
  var sampler : *Sampler;
  var texture : *SampleableTextureCube<float>;
  var uniforms : *uniform Buffer<CubeResamplingUniforms>;
}

class CubeResamplingPipeline {
  vertex main(vb : &VertexBuiltins) : float<2> {
    var verts = [6]float<2>{
      { -1.0, -1.0 }, { 1.0, -1.0 }, { -1.0, 1.0 },
      { -1.0,  1.0 }, { 1.0, -1.0 }, {  1.0, 1.0 }
    };
    var v = verts[vb.vertexIndex];
    vb.position = {@v, 0.0, 1.0};
    return v * float<2>{0.5, -0.5} + float<2>{0.5, 0.5};
  }
  fragment main(fb : &FragmentBuiltins, texCoord : float<2>) {
    var faceMatrices = [6]float<3,3>{
      { { 0.0, 0.0, -2.0 }, { 0.0, -2.0,  0.0 }, {  1.0,  1.0,  1.0 } },
      { { 0.0, 0.0,  2.0 }, { 0.0, -2.0,  0.0 }, { -1.0,  1.0, -1.0 } },
      { { 2.0, 0.0,  0.0 }, { 0.0,  0.0,  2.0 }, { -1.0,  1.0, -1.0 } },
      { { 2.0, 0.0,  0.0 }, { 0.0,  0.0, -2.0 }, { -1.0, -1.0,  1.0 } },
      { { 2.0, 0.0,  0.0 }, { 0.0, -2.0,  0.0 }, { -1.0,  1.0,  1.0 } },
      { {-2.0, 0.0,  0.0 }, { 0.0, -2.0,  0.0 }, {  1.0,  1.0, -1.0 } }
    };
    var b = bindings.Get();
    var face = b.uniforms.MapRead().face;
    var coord = faceMatrices[face] * float<3>{@texCoord, 1.0};
    fragColor.Set(b.texture.Sample(b.sampler, coord));
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

    for (var face = 0u; face < 6u; ++face) {
      for (var mipLevel = 1u; mipLevel < mipCount; ++mipLevel) {
        resamplingBindings.texture = texture.CreateSampleableView(mipLevel - 1, 1u);
        resamplingBindings.uniforms.SetData({ face });
        var fb = texture.CreateRenderableView(face, mipLevel);
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
}
