include "include/test.t"

class C {
  C(float v = 3.0) {
    value = v;
  }
  value : float;
}

var c = new C();
Test.Expect(c.value == 3.0);
