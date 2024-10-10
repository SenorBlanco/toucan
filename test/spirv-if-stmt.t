using Vertex = float<4>;

class ComputeBindings {
  var vertStorage : storage Buffer<Vertex[]>*;
}

class BumpCompute {
  void computeShader(ComputeBuiltins^ cb) compute(1, 1, 1) {
    var verts = bindings.Get().vertStorage.MapReadWriteStorage();
    var pos = cb.globalInvocationId.x;
    if (pos % 2 == 1) {
      verts[pos] += float<4>( 1.0, 0.0, 0.0, 0.0);
    }
  }
  var bindings : BindGroup<ComputeBindings>*;
}

var device = new Device();

// This test passes by producing valid SPIR-V.
var pipeline = new ComputePipeline<BumpCompute>(device);
