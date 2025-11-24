include "../test/include/string.t"

var a = double<1>( 1.0d );
var count = 1000000000u;
var frac = 1.0d / (double) count;
var inc = double<1>( frac );
for(var i = 0u; i < count; ++i) {
  a += inc;
}
System.PrintLine(String.From((int) a.x).Get());
