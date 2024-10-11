var a : float<4>;
var b : float<4>;
a = float<4>(1.0, 2.0, 3.0, 4.0);
b = float<4>(0.0, 0.0, 0.0, 0.0);
for (var i = 0; i < 1000000000; ++i) {
  b += a;
}
