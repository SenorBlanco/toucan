include "include/test.t"

enum Enum { Foo, Bar, Baz };
class A {
  init() {
    f = Foo;
  }
  var f : Enum;
};
var a = new A;
a.init();
Test.Expect(a.f == Foo);
a.f = Bar;
Test.Expect(a.f == Bar);
var r = 0.0;
if (a.f == Bar ) {
  r = 1.0;
}
Test.Expect(r == 1.0);
