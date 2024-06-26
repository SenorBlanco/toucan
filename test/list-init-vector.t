include "include/test.t"

float<2> v21 = {1.0, 0.0};
float<2> v22 = {2.0, 3.0};

int<4> v = {1, 2, 3, 4};
v = {1, 1, 1, 1};

Test.Expect(v21.x == 1.0);
Test.Expect(v21.y == 0.0);
Test.Expect(v22.x == 2.0);
Test.Expect(v22.y == 3.0);
Test.Expect(v.x == 1);
Test.Expect(v.y == 1);
Test.Expect(v.z == 1);
Test.Expect(v.w == 1);
