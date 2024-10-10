include "include/test.t"

class Foo {
  Foo() {}
  Foo^ self() { count += 1; return this; }
  var a : int;
  var count : int;
}

var foo = new Foo();
foo.self().a += 1;

Test.Expect(foo.a == 1);
Test.Expect(foo.count == 1);
