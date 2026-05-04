#include "include/test.t"

class ExpectationResults {
  var count : int;
  var failures : []int;
}

class ExpectationBindings {
  var results : *storage Buffer<ExpectationResults>;
}

class DeviceTest {
  deviceonly Expect(expr : bool, line : uint) { // FIXME: add System.GetSourceLine()
    if (!expr) {
      var results = expectationBindings.Get().results.Map();
      results.failures[results.count++] = line;
    }
  }

  var expectationBindings : *BindGroup<ExpectationBindings>;
}

class Compute : DeviceTest {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    this.Expect(false, 42);
  }
}

var device = new Device();

var computePipeline = new ComputePipeline<Compute>(device);

var deviceBuf = new storage Buffer<ExpectationResults>(device, 1);
var hostBuf = new hostreadable Buffer<ExpectationResults>(device, 1);

var bg = new BindGroup<ExpectationBindings>(device, {results = deviceBuf});

var encoder = new CommandEncoder(device);
var computePass = new ComputePass<Compute>(encoder, {expectationBindings = bg});
computePass.SetPipeline(computePipeline);
computePass.Dispatch(1, 1, 1);
computePass.End();
hostBuf.CopyFromBuffer(encoder, deviceBuf);
device.GetQueue().Submit(encoder.Finish());

Test.Expect(hostBuf.MapRead().failures[0] == 42);
