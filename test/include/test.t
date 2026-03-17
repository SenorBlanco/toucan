include "string.t"
class Test {
  static Expect(expr : bool, file : ^[]ubyte = System.GetSourceFile(), line : uint = System.GetSourceLine()) {
    if (!expr) {
      System.Print(file);
      System.Print(":");
      System.Print(String.From(line).Get());
      System.PrintLine(": expectation failed");
    }
  }
  static Assert(expr : bool, file : ^[]ubyte = System.GetSourceFile(), line : uint = System.GetSourceLine()) {
    if (!expr) {
      System.Print(file);
      System.Print(":");
      System.Print(String.From(line).Get());
      System.PrintLine(": assertion failed");
      System.Abort();
    }
  }
}

#def DEVICE_EXPECT(EXPR) {

class Bindings {
  var result : *storage Buffer<int>;
}

class TestPipeline {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    var result = bindings.Get().result.MapWrite();
    if (EXPR) {
      result: = 1;
    } else {
      result: = 0;
    }
  }
  var bindings : *BindGroup<Bindings>;
}

var device = new Device();
var hostBuffer = new hostreadable Buffer<int>(device);
var deviceBuffer = new storage Buffer<int>(device);
var pipeline = new ComputePipeline<TestPipeline>(device);
var encoder = new CommandEncoder(device);
var bindings = new BindGroup<Bindings>(device, { deviceBuffer });
var pass = new ComputePass<TestPipeline>(encoder, { bindings });
pass.SetPipeline(pipeline);
pass.Dispatch(1, 1, 1);
pass.End();
hostBuffer.CopyFromBuffer(encoder, deviceBuffer);
device.GetQueue().Submit(encoder.Finish());

Test.Expect(hostBuffer.MapRead(): == 1);

}
#enddef

#def HOST_EXPECT(EXPR)
Test.Expect(EXPR);
#enddef

#def EXPECT(EXPR)
DEVICE_EXPECT(EXPR);
HOST_EXPECT(EXPR);
#enddef
