class Utils {
  static makeFloat2(v : float<3>) : float<2> {
    return float<2>(v.x, v.y);
  }
  static makeFloat2(v : float<4>) : float<2> {
    return float<2>(v.x, v.y);
  }
  static makeFloat3(v : float<4>) : float<3> {
    return float<3>(v.x, v.y, v.z);
  }
  static makeFloat4(v : float<2>) : float<4> {
    return float<4>(v.x, v.y, 0.0, 1.0);
  }
  static makeFloat4(v : float<2>, z : float, w : float) : float<4> {
    return float<4>(v.x, v.y, z, w);
  }
  static makeFloat4(v : float<3>) : float<4> {
    return float<4>(v.x, v.y, v.z, 1.0);
  }
  static makeFloat4(v : float<3>, w : float) : float<4> {
    return float<4>(v.x, v.y, v.z, w);
  }
  static makeVector(x : float, y : float, z : float, placeholder : float<2>) : float<2> {
    return float<2>(x, y);
  }
  static makeVector(x : float, y : float, z : float, placeholder : float<3>) : float<3> {
    return float<3>(x, y, z);
  }
  static cross(a : float<3>, b : float<3>) : float<3> {
    return float<3>(a.y * b.z - a.z * b.y,
                    a.z * b.x - a.x * b.z,
                    a.x * b.y - a.y * b.x);
  }
}
