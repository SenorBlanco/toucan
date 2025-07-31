class ResamplingUniforms {
  var targetSize : uint<2>;
}

class ResamplingBindings {
  var sampler : *Sampler;
  var texture : *SampleableTexture2D<float>;
  var uniforms : *uniform Buffer<ResamplingUniforms>;
}

class ResamplingPipeline {
  vertex main(vb : &VertexBuiltins) {
    var verts = [6]float<2>{
      { -1.0, -1.0 }, { 1.0, -1.0 }, { -1.0, 1.0 },
      { -1.0,  1.0 }, { 1.0, -1.0 }, {  1.0, 1.0 }
    };
    vb.position = {@verts[vb.vertexIndex], 0.0, 1.0};
  }
  fragment main(fb : &FragmentBuiltins) {
    var b = bindings.Get();
    var coord = fb.fragCoord.xy / (float<2>) b.uniforms.MapRead().targetSize;
    fragColor.Set(b.texture.Sample(b.sampler, coord));
  }
  var fragColor : *ColorOutput<RGBA8unorm>;
  var bindings : *BindGroup<ResamplingBindings>;
};

class MipmapGenerator {
  static Generate(device : *Device, texture : *renderable sampleable Texture2D<RGBA8unorm>) {
    var resamplingPipeline = new RenderPipeline<ResamplingPipeline>(device);
    var mipCount = 30 - Math.clz(texture.GetSize().x);

    var resamplingBindings : ResamplingBindings;
    resamplingBindings.sampler = new Sampler(device);
    resamplingBindings.uniforms = new uniform Buffer<ResamplingUniforms>(device);

    for (var mipLevel = 1u; mipLevel < mipCount; ++mipLevel) {
      resamplingBindings.texture = texture.CreateSampleableView(mipLevel - 1, 1u);
      resamplingBindings.uniforms.SetData({ targetSize = texture.GetSize(mipLevel) });
      var fb = texture.CreateRenderableView(mipLevel);
      var encoder = new CommandEncoder(device);
      var renderPass = new RenderPass<ResamplingPipeline>(encoder, {
        fragColor = fb.CreateColorOutput(LoadOp.Clear),
        bindings = new BindGroup<ResamplingBindings>(device, &resamplingBindings)
      });
      renderPass.SetPipeline(resamplingPipeline);
      renderPass.Draw(6, 1, 0, 0);
      renderPass.End();
      device.GetQueue().Submit(encoder.Finish());
    }
  }
}
