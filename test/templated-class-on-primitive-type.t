include "include/test.t"

class Template<T> {
  T foo;
  void set(T t) { foo = t; }
  T get() { return foo; }
}

Template<float>* t = new Template<float>();
t.set(3.0);
Test.Expect(t.get() == 3.0);
