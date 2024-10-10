include "include/test.t"

class C {
  f : float;
  array : int[];
};
var c = new [5]C();
c.array[2] = 42;

Test.Expect(c.array[2] == 42);
