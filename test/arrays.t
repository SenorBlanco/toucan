int[3] c;
float[3][3] e;
e[2][1] = 5.0;
float[]^ f = new float[3];
float[3][]^ g = new float[3][3];
f[0] = 1234.0;
g[2][1] = 3.0;
return g[2][1] + f[0] + e[2][1];
