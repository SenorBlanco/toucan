include "include/test.t"
class C<T> {
  static Foo(a = 3) : T {
    return (T) a;
  }
}

Test.Expect(C<float>.Foo() == 3.0);
Test.Expect(C<float>.Foo(42) == 42.0);
