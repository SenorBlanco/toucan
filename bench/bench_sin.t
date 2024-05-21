double<4> a = {1.0d, 2.0d, 3.0d, 4.0d};
for(int i = 0; i < 1000000000; ++i) {
  a = Math.sin(a);
}
return (float) (a.x + a.y + a.z + a.w);
