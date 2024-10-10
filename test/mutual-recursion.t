include "include/test.t"

class Foo {
  var y : float;
  void foo(int x) {
    if (x > 0) this.bar(x - 1);
    return;
  }
  void bar(int x) {
    y += 1.0;
    this.foo(x);
    return;
  }
};

var foo = new Foo();
foo.y = 0.0;
foo.foo(10);
Test.Expect(foo.y == 10.0);
