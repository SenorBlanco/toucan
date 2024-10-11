var a = float<4>(1.5, 0.5, -1.5, 5.0);
var c = float<4>(1.0, 1.0,  1.0, 1.0);
var i = 0;
while(i < 100000000) {
  c *= a;
  ++i;
}
