var a = float<4>(1.5, 0.5, -1.5, 5.0);
var c = float<4>(1.0, 1.0,  1.0, 1.0);
for(var i = 0; i < 100000000; ++i) {
  c = a * c;
}
