double<32> a = {1.0d, 2.0d, 3.0d, 4.0d, 5.0d, 6.0d, 7.0d, 8.0d, 9.0d, 10.0d, 11.0d, 12.0d, 13.0d, 14.0d, 15.0d, 16.0d, 17.0d, 18.0d, 19.0d, 20.0d, 21.0d, 22.0d, 23.0d, 24.0d, 25.0d, 26.0d, 27.0d, 28.0d, 29.0d, 30.0d, 31.0d, 32.0d};
uint count = 1000000000;
double frac = 1.0d / (double) count;
double<32> inc = double<32>( frac );
for(uint i = 0; i < count; ++i) {
  a += inc;
}
return (float) (a.x + a.y + a.z + a.w);
