var outer_count = 1000000;
var a = new float[1024];
for (var i = 0; i < a.length; ++i) {
  a[i] = 2000000.0;
}
for (var j = 0; j < outer_count; ++j) {
  for (var i = 0; i < a.length; ++i) {
    a[i] = a[i] * 1.00001 + 1.0;
  }
}
