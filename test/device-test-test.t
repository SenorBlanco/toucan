#include "include/device-test.t"

class Compute : DeviceTest {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    this.Expect(false, 42u);
    this.Expect(false, 21u);
    this.Expect(true,  9999u);
    this.Expect(false, 14u);
    this.Expect(false, 84u);
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

Test.Expect(hostBuf.MapRead().failures[0] == 42u);
Test.Expect(hostBuf.MapRead().failures[1] == 21u);
Test.Expect(hostBuf.MapRead().failures[2] == 14u);
Test.Expect(hostBuf.MapRead().failures[3] == 84u);
