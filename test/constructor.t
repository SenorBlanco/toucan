include "include/test.t"

class C {
  C(float v) {
    value = v;
  }
  float value;
}

C* c = new C(3.14159);
Test.Expect(c.value == 3.14159);
