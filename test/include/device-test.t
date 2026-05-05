#include "test.t"

class ExpectationResults {
  var count : int;
  var failures : [10]uint;
}

class ExpectationBindings {
  var results : *storage Buffer<ExpectationResults>;
}

class DeviceTest {
  deviceonly Expect(expr : bool, line : uint) {  // FIXME: implement System.GetSourceLine()
    if (!expr) {
      var results = expectationBindings.Get().results.Map();
      results.failures[results.count++] = line;
    }
  }

  var expectationBindings : *BindGroup<ExpectationBindings>;
}
