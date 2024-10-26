include "include/test.t"

class Foo {
  var x : int;
  var y : float;
};

var foo = new [100]Foo;
foo[23].y = 5.0;
Test.Expect(foo[23].y == 5.0);
