include "include/test.t"

class Foo {
  foo() {
    this.bar("hi");
  }
  bar(str : &[]ubyte) {
    System.PrintLine(str);
  }
};

var foo : Foo;
foo.foo("abc");
