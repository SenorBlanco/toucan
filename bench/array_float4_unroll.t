var outer_count = 1000000;
var a : float<4>[256];
var mul = float<4>(1.00001, 1.00001, 1.00001, 1.00001);
var add = float<4>(1.0, 1.0, 1.0, 1.0);
var init = float<4>(2000000.0, 2000000.0, 2000000.0, 2000000.0);
for (var i = 0; i < a.length; ++i) {
  a[i] = init;
}
for (var j = 0; j < outer_count; ++j) {
  for (var i = 0; i < a.length;) {
    a[i] = a[i] * mul + add;
    ++i;
    a[i] = a[i] * mul + add;
    ++i;
    a[i] = a[i] * mul + add;
    ++i;
    a[i] = a[i] * mul + add;
    ++i;
  }
}
