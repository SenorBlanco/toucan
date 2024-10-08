include "include/test.t"
float<4, 4> m;

class ComputeBindings {
  writeonly storage Buffer<float<4,4>[]>* buffer;
}

class Compute {
  void computeShader(ComputeBuiltins^ cb) compute(1, 1, 1) {
    auto buffer = bindings.Get().buffer.MapWriteStorage();
    int i0 = 0, i1 = 1, i2 = 2, i3 = 3;
    buffer[0][i0][i0] = 4.0;
    buffer[0][i0][i1] = 3.0;
    buffer[0][i0][i2] = 2.0;
    buffer[0][i0][i3] = 1.0;
    buffer[0][i3][i0] = 4.0;
    buffer[0][i3][i1] = 3.0;
    buffer[0][i3][i2] = 2.0;
    buffer[0][i3][i3] = 1.0;
  }
  BindGroup<ComputeBindings>* bindings;
}

Device* device = new Device();

ComputePipeline* computePipeline = new ComputePipeline<Compute>(device);

auto storageBuf = new writeonly storage Buffer<float<4,4>[]>(device, 1);
auto hostBuf = new readonly Buffer<float<4,4>[]>(device, 1);

auto bg = new BindGroup<ComputeBindings>(device, {buffer = storageBuf});

auto encoder = new CommandEncoder(device);
auto computePass = new ComputePass<Compute>(encoder, null);
computePass.SetPipeline(computePipeline);
computePass.Set({bindings = bg});
computePass.Dispatch(1, 1, 1);
computePass.End();
encoder.CopyBufferToBuffer(storageBuf, hostBuf);
device.GetQueue().Submit(encoder.Finish());

auto result = hostBuf.MapRead()[0];
Test.Expect(m[0][0] == 4.0);
Test.Expect(m[0][1] == 3.0);
Test.Expect(m[0][2] == 2.0);
Test.Expect(m[0][3] == 1.0);
Test.Expect(m[3][0] == 5.0);
Test.Expect(m[3][1] == 6.0);
Test.Expect(m[3][2] == 7.0);
Test.Expect(m[3][3] == 8.0);
