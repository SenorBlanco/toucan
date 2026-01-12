include "include/test.t"

class C<T> {
  static bar() : T<2> { return T{}; }
}

Test.Expect(Math.all(C<int>.bar() == int<2>{}));
Test.Expect(Math.all(C<float>.bar() == float<2>{}));
