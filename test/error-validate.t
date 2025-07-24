class BadPipelineField {
  vertex main(vb : &VertexBuiltins) {}
  fragment main(fb : &FragmentBuiltins) {}
  var bad : int;
};

class NoVertexShader {
  fragment main(fb : &FragmentBuiltins) {}
};

class NoFragmentShader {
  vertex main(vb : &VertexBuiltins) {}
};

class NoShaders {
};

var device = new Device();
var encoder = new CommandEncoder(device);

new RenderPipeline<BadPipelineField>(device);
new RenderPass<BadPipelineField>(encoder, {});
new RenderPipeline<NoVertexShader>(device);
new RenderPipeline<NoFragmentShader>(device);
new RenderPipeline<NoShaders>(device);
