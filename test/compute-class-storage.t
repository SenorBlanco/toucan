#include "include/test.t"

class Data {
  var array : [1]uint;
};

class ComputeBindings {
  var data : *storage Buffer<Data>;
}

class Compute {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    bindings.Get().data.MapWrite().array[0] = 42;
  }
  var bindings : *BindGroup<ComputeBindings>;
}

var device = new Device();

var computePipeline = new ComputePipeline<Compute>(device);

var storageBuf = new storage Buffer<Data>(device);
var hostBuf = new hostreadable Buffer<Data>(device);

var bg = new BindGroup<ComputeBindings>(device, {data = storageBuf});

var encoder = new CommandEncoder(device);
var computePass = new ComputePass<Compute>(encoder, {bindings = bg});
computePass.SetPipeline(computePipeline);
computePass.Dispatch(1, 1, 1);
computePass.End();
hostBuf.CopyFromBuffer(encoder, storageBuf);
device.GetQueue().Submit(encoder.Finish());

Test.Expect(hostBuf.MapRead().array[0] == 42);
