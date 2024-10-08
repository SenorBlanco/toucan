include "include/test.t"

class ComputeBindings {
  writeonly storage Buffer<float<4>>* buffer;
}

class Compute {
  void computeShader(ComputeBuiltins^ cb) compute(1, 1, 1) {
    auto v = bindings.Get().buffer.MapWriteStorage();
    int i0 = 0, i1 = 1, i2 = 2, i3 = 3;
    v[i0] = 5.0;
    v[i1] = 6.0;
    v[i2] = 7.0;
    v[i3] = 8.0;
  }
  BindGroup<ComputeBindings>* bindings;
}

Device* device = new Device();

ComputePipeline* computePipeline = new ComputePipeline<Compute>(device);

auto storageBuf = new writeonly storage Buffer<float<4>>(device);
auto hostBuf = new readonly Buffer<float<4>>(device);

auto bg = new BindGroup<ComputeBindings>(device, {buffer = storageBuf});

auto encoder = new CommandEncoder(device);
auto computePass = new ComputePass<Compute>(encoder, null);
computePass.SetPipeline(computePipeline);
computePass.Set({bindings = bg});
computePass.Dispatch(1, 1, 1);
computePass.End();
encoder.CopyBufferToBuffer(storageBuf, hostBuf);
device.GetQueue().Submit(encoder.Finish());

float<4> v = *hostBuf.MapRead();
Test.Expect(v[0] == 5.0);
Test.Expect(v[1] == 6.0);
Test.Expect(v[2] == 7.0);
Test.Expect(v[3] == 8.0);
