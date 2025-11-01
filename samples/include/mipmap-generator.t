class ResamplingBindings {
  var sampler : *Sampler;
  var texture : *SampleableTexture2D<float>;
}

class ResamplingPipeline {
  vertex main(vb : &VertexBuiltins) : float<2> {
    var verts = [6]float<2>{
      { -1.0, -1.0 }, { 1.0, -1.0 }, { -1.0, 1.0 },
      { -1.0,  1.0 }, { 1.0, -1.0 }, {  1.0, 1.0 }
    };
    var v = verts[vb.vertexIndex];
    vb.position = {@v, 0.0, 1.0};
    return v * float<2>{0.5, -0.5} + float<2>{0.5};
  }
  fragment main(fb : &FragmentBuiltins, texCoord : float<2>) {
    var b = bindings.Get();
    fragColor.Set(b.texture.Sample(b.sampler, texCoord));
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

    for (var mipLevel = 1u; mipLevel < mipCount; ++mipLevel) {
      resamplingBindings.texture = texture.CreateSampleableView(mipLevel - 1, 1u);
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
