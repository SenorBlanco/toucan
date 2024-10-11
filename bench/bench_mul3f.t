var a = float<3>(1.5, 0.5, -1.5);
var b = float<3>(2.5, -1.5, 0.5);
var c = float<3>(0.0, 0.0,  0.0);
for(var i = 0; i < 10000000; i = i + 1) {
  c = a * b;
}
