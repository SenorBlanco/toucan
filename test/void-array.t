float<3>[]* positions = new float<3>[10];
positions[9] = float<3>(3.0, 2.0, 1.0);
void[]* voidbuf = (void[]*) positions;
// float<3>[] new_positions = (float<3>[]) voidbuf;
return positions[9].y;
