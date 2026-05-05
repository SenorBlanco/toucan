#include "include/test.t"

class ExpectationResults {
  var count : int;
  var failures : [10]uint;
}

class ExpectationBindings {
  var results : *storage Buffer<ExpectationResults>;
}

class DeviceTest {
  deviceonly Expect(expr : uint, line : uint) {  // FIXME: implement System.GetSourceLine()
    if (expr == 0u) {
      var results = expectationBindings.Get().results.Map();
      results.failures[results.count++] = line;
    }
  }

  var expectationBindings : *BindGroup<ExpectationBindings>;
}

class Compute : DeviceTest {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    this.Expect(0u, 42u);
    this.Expect(0u, 21u);
    this.Expect(0u, 14u);
    this.Expect(0u, 84u);
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
