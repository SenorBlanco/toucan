#include "include/test.t"

class LogBindings {
  var log : *storage Buffer<[]int>;
  var logLength : *storage Buffer<int>;

}

class ShaderDebugger {
  Log(msg : []uint) {
    var log = logBindings.Get().log;
    var length = logBindings.Get().logLength;
    for (var i = 0; i < msg.length; ++i) {
      log[length:++] = msg[i];
    }
  }
  var logBindings : *BindGroup<LogBindings>;
}

class Compute : ShaderDebugger {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    this.Log({65, 66, 67});
  }
}

var device = new Device();

var computePipeline = new ComputePipeline<Compute>(device);

var storageBuf = new storage Buffer<[]int>(device, 1);
var hostBuf = new hostreadable Buffer<[]int>(device, 1);

var bg = new BindGroup<LogBindings>(device, {buffer = storageBuf});

var encoder = new CommandEncoder(device);
var computePass = new ComputePass<Compute>(encoder, {bindings = bg});
computePass.SetPipeline(computePipeline);
computePass.Dispatch(1, 1, 1);
computePass.End();
hostBuf.CopyFromBuffer(encoder, storageBuf);
device.GetQueue().Submit(encoder.Finish());

Test.Expect(hostBuf.MapRead()[0] == 42);
