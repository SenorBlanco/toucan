class Utils {
  static makeFloat3(v : float<4>) : float<3> {
    return float<3>(v.x, v.y, v.z);
  }
  static makeFloat4(v : float<2>, z : float, w : float) : float<4> {
    return float<4>(v.x, v.y, z, w);
  }
  static makeFloat4(v : float<3>, w : float) : float<4> {
    return float<4>(v.x, v.y, v.z, w);
  }
}
