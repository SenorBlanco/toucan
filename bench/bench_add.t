var a = float<256>{ 1.0 };
var count = 1000000000u;
var inc = float<256>{ 1.0 / (float) count };
for(var i = 0u; i < count; ++i) {
  a += inc;
}
