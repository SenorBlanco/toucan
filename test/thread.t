class Foo {
  thread main() {
    System.PrintLine("hi from thread");
  }
}

var t = new Thread<Foo>(new Foo{});
t.Join();
