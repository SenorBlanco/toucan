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

#def DEVICE_EXPECT_EQ(A, B) {

class Bindings {
  var result : *storage Buffer<uint>;
}

class TestPipeline {
  compute(1, 1, 1) main(cb : &ComputeBuiltins) {
    bindings.Get().result.Map(): = 1; // FIXME: EXPR
  }
  var bindings : *BindGroup<Bindings>;
}

var device = new Device();
var pipeline = new ComputePipeline<TestPipeline>(device);

var encoder = new CommandEncoder(device);
var buffer = new storage Buffer<uint>(device);
var bindings = new BindGroup<Bindings>(device, {buffer});
var pass = new ComputePass<TestPipeline>(encoder, {bindings});
pass.Dispatch(1, 1, 1);
device.GetQueue().Submit(encoder.Finish());

Test.Expect(buffer.Map(): == B);

}
#enddef
