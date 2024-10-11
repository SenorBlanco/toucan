var a = 1.0000001;
var c = 1.0;
for(var i = 0; i < 100000000; ++i) {
  c = a * c;
}
