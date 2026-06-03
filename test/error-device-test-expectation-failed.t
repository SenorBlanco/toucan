#include "include/device-test.t"

class Compute : DeviceTest {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    this.Expect(false);
    this.Expect(false);
    this.Expect(true);
    this.Expect(false);
    this.Expect(false);
  }
}

var device = new Device();

var computePipeline = new ComputePipeline<Compute>(device);

var deviceBuf = new storage Buffer<ExpectationResults>(device);
var hostBuf = new hostreadable Buffer<ExpectationResults>(device);

var bg = new BindGroup<ExpectationBindings>(device, {results = deviceBuf});

var encoder = new CommandEncoder(device);
var computePass = new ComputePass<Compute>(encoder, {expectationBindings = bg});
computePass.SetPipeline(computePipeline);
computePass.Dispatch(1, 1, 1);
computePass.End();
hostBuf.CopyFromBuffer(encoder, deviceBuf);
device.GetQueue().Submit(encoder.Finish());

var results = hostBuf.MapRead();
for (var i = 0u; i < results.count; ++i) {
  System.Print(String.From(results.failures[i]).Get());
  System.PrintLine(": expectation failed");
}
