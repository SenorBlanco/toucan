float<4, 4> m = float<4,4>(float<4>(1.0, 0.0, 0.0, 0.0),
                           float<4>(0.0, 1.0, 0.0, 0.0),
                           float<4>(0.0, 0.0, 1.0, 0.0),
                           float<4>(5.0,-3.0, 1.0, 1.0));

return m[0][0] + m[3][0] + m[3][1];
