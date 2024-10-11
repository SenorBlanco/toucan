var a = 0;
var b = 2;
for(var i = 0; i < 1000000; ++i) {
  a += b;
}
var f = 0.0;
while(a > 0) {
  f += 1.0;
  --a;
}
