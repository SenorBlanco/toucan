include "include/test.t"

class ComputeBindings {
  buffer : writeonly storage Buffer<int[]>*;
}

class Struct {
  a : int;
}

class Compute {
  static void set(int^ p, int value) {
    *p = value;
  }
  void computeShader(ComputeBuiltins^ cb) compute(1, 1, 1) {
    var buffer = bindings.Get().buffer.MapReadWriteStorage();
    var i : int;
    var array : int[1];
    var struct : Struct;
    this.set(&i, 7);
    this.set(&array[0], 21);
    this.set(&struct.a, 42);
    buffer[0] = i;
    buffer[1] = array[0];
    buffer[2] = struct.a;
  }
  bindings : BindGroup<ComputeBindings>*;
}

var device = new Device();

var computePipeline = new ComputePipeline<Compute>(device);

var storageBuf = new writeonly storage Buffer<int[]>(device, 3);
var hostBuf = new readonly Buffer<int[]>(device, 3);

var bg = new BindGroup<ComputeBindings>(device, {buffer = storageBuf});

var encoder = new CommandEncoder(device);
var computePass = new ComputePass<Compute>(encoder, null);
computePass.SetPipeline(computePipeline);
computePass.Set({bindings = bg});
computePass.Dispatch(1, 1, 1);
computePass.End();
encoder.CopyBufferToBuffer(storageBuf, hostBuf);
device.GetQueue().Submit(encoder.Finish());

Test.Expect(hostBuf.MapRead()[0] == 7);
Test.Expect(hostBuf.MapRead()[1] == 21);
Test.Expect(hostBuf.MapRead()[2] == 42);
