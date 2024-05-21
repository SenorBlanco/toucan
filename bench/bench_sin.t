float<4> a = {1.0, 2.0, 3.0, 4.0};
for(int i = 0; i < 1000000000; ++i) {
  a = Math.sin(a);
}
return a.x + a.y + a.z + a.w;
