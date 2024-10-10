include "include/test.t"

var a = 3.0;
class Foo {
  Weak() : void^ { return new Foo(); }
  Strong() : void* { return new Foo(); }
  WeakNull() : void^ { return null; }
  StrongNull() : void* { return null; }
}
var f = new Foo();
f.Weak();
f.Strong();
f.WeakNull();
f.StrongNull();
Test.Expect(a == 3.0);
