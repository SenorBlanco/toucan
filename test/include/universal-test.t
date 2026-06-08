#include "string.t"

#def BEGIN_TEST
class ExpectationResults {
  var count : int;
  var failures : [10]uint;
}

class ExpectationBindings {
  var results : *storage Buffer<ExpectationResults>;
}


class DeviceTestBase {
  deviceonly Expect(expr : bool, line = System.GetSourceLine()) {
    if (!expr) {
      var results = expectationBindings.Get().results.Map();
      results.failures[results.count++] = line;
    }
  }
  var expectationBindings : *BindGroup<ExpectationBindings>;
}

class HostTestBase {
  Expect(expr : bool, line = System.GetSourceLine(), file = System.GetSourceFile()) {
    if (!expr) {
      System.Print(file);
      System.Print(":");
      System.Print(String.From(line).Get());
      System.PrintLine(": expectation failed (host)");
    }
  }
}

class Test<TestBase> : TestBase {
  RunTest() {
#enddef

#def END_TEST
  }
}

class DeviceTestPipeline : Test<DeviceTestBase> {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    this.RunTest();
  }
}

var device = new Device();
var computePipeline = new ComputePipeline<DeviceTestPipeline>(device);
var deviceBuf = new storage Buffer<ExpectationResults>(device);
var hostBuf = new hostreadable Buffer<ExpectationResults>(device);
var bg = new BindGroup<ExpectationBindings>(device, {results = deviceBuf});
var encoder = new CommandEncoder(device);
var computePass = new ComputePass<DeviceTestPipeline>(encoder, {expectationBindings = bg});
computePass.SetPipeline(computePipeline);
computePass.Dispatch(1, 1, 1);
computePass.End();
hostBuf.CopyFromBuffer(encoder, deviceBuf);
device.GetQueue().Submit(encoder.Finish());

var results = hostBuf.MapRead();
for (var i = 0u; i < results.count; ++i) {
  System.Print(String.From(results.failures[i]).Get());
  System.PrintLine(": expectation failed (device)");
}

var test : Test<HostTestBase>;
test.RunTest();
#enddef
