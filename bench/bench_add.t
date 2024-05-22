double<1> a = double<1>( 1.0d );
uint count = 1000000000;
double frac = 1.0d / (double) count;
double<1> inc = double<1>( frac );
for(uint i = 0; i < count; ++i) {
  a += inc;
}
float v = (float) (a.x);
return v;
