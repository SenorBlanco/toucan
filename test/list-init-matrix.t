float<4, 4> m = {{1.0, 0.0, 0.0, 0.0},
                 {0.0, 1.0, 0.0, 0.0},
                 {0.0, 0.0, 1.0, 0.0},
                 {5.0,-3.0, 1.0, 1.0}};

return m[0][0] + m[3][0] + m[3][1];