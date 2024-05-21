double<4> a = {1.0d, 2.0d, 3.0d, 4.0d};
int count = 100000000000;
double scale = 1.0d / (double) count;
double<4> inc = {scale, scale, scale, scale};
for(int i = 0; i < count; ++i) {
  a += inc;
}
return (float) (a.x + a.y + a.z + a.w);
