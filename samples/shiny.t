class Foo {
  static void Bar(Foo^ f) {
  }
  float placeholder;
}

class BicubicComputePipeline {
  void computeShader(ComputeBuiltins cb) compute(8, 8, 1) {
    Foo[1] foo;
    Foo.Bar(&foo[0]);
  }
}

Device* device = new Device();

auto tessPipeline = new ComputePipeline<BicubicComputePipeline>(device);
