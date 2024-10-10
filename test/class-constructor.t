include "include/test.t"

class C {
  C(float _x, float _y) : { y = _x, x = _y } {}
  x : float;
  y : float;
}

var c = C(21.0, 42.0);
Test.Expect(c.x == 42.0);
Test.Expect(c.y == 21.0);
