include "include/test.t"

class C<T> {
  var a : T = (T) 3;
}

var c = new C<int>;
Test.Expect(c.a == 3);

var cf = new C<float>;
Test.Expect(cf.a == 3.0);
