class Foo {
  float func() {
    return 1234.0;
  }
};

class Bar : Foo {
  float func() {
    return 2345.0;
  }
};

Bar* b = new Bar();
return b.func();
