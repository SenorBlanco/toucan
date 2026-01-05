include "quaternion.t"

class Transform {
  static identity() : <4><4>float {
    return <4><4>float{{1.0, 0.0, 0.0, 0.0},
                       {0.0, 1.0, 0.0, 0.0},
                       {0.0, 0.0, 1.0, 0.0},
                       {0.0, 0.0, 0.0, 1.0}};
  }
  static scale(v : <3>float) : <4><4>float {
    return <4><4>float{{v.x, 0.0, 0.0, 0.0},
                       {0.0, v.y, 0.0, 0.0},
                       {0.0, 0.0, v.z, 0.0},
                       {0.0, 0.0, 0.0, 1.0}};
  }
  static translation(v : <3>float) : <4><4>float {
    return <4><4>float{{1.0, 0.0, 0.0, 0.0},
                       {0.0, 1.0, 0.0, 0.0},
                       {0.0, 0.0, 1.0, 0.0},
                       {v.x, v.y, v.z, 1.0}};
  }
  static rotation(axis : <3>float, angle : float) : <4><4>float {
    var q = Quaternion(axis, angle);
    return q.toMatrix();
  }
  static projection(n : float, f : float, l : float, r : float, b : float, t : float) : <4><4>float {
    return <4><4>float(
      <4>float(2.0 * n / (r - l), 0.0, 0.0, 0.0),
      <4>float(0.0, 2.0 * n / (t - b), 0.0, 0.0),
      <4>float((r + l) / (r - l), (t + b) / (t - b), -(f + n) / (f - n), -1.0),
      <4>float(0.0, 0.0, -2.0 * f * n / (f - n), 0.0));
  }
  static perspective(fovy : float, aspect : float, n: float, f : float) : <4><4>float {
    var a = 1.0 / Math.tan(fovy / 2.0);
    return <4><4>float(
      <4>float(a / aspect, 0.0, 0.0,                   0.0),
      <4>float(0.0,        a,   0.0,                   0.0),
      <4>float(0.0,        0.0, (f + n) / (n - f),    -1.0),
      <4>float(0.0,        0.0, 2.0 * f * n / (n - f), 0.0));
  }
  static lookAt(eye : <3>float, center : <3>float, up : <3>float) : <4><4>float {
    var f = Math.normalize(center - eye);
    up = Math.normalize(up);
    var s = Math.normalize(Math.cross(f, up));
    var u = Math.cross(s, f);
    var t = <3>float(Math.dot(s, -eye), Math.dot(u, -eye), Math.dot(f, eye));
    return <4><4>float(
      <4>float(s.x, u.x, -f.x, 0.0),
      <4>float(s.y, u.y, -f.y, 0.0),
      <4>float(s.z, u.z, -f.z, 0.0),
      <4>float(t.x, t.y,  t.z, 1.0));
  }
  static swapRows(m : <4><4>float, i : int, j : int) : <4><4>float {
    for (var k = 0; k < 4; ++k) {
      var tmp = m[k][i];
      m[k][i] = m[k][j];
      m[k][j] = tmp;
    }
    return m;
  }
  static invert(matrix : <4><4>float) : <4><4>float {
    var a = matrix;
    var b = Transform.identity();

    for (var j = 0; j < 4; ++j) {
      var i1 = j;
      for (var i = j + 1; i < 4; ++i)
        if (Math.fabs(a[j][i]) > Math.fabs(a[j][i1]))
          i1 = i;

      if (i1 != j) {
        a = Transform.swapRows(a, i1, j);
        b = Transform.swapRows(b, i1, j);
      }

      if (a[j][j] == 0.0) {
        return b;
      }

      var s = 1.0 / a[j][j];

      for (var i = 0; i < 4; ++i) {
        b[i][j] *= s;
        a[i][j] *= s;
      }

      for (var i = 0; i < 4; ++i) {
        if (i != j) {
          var t = a[j][i];
          for (var k = 0; k < 4; ++k) {
            b[k][i] -= t * b[k][j];
            a[k][i] -= t * a[k][j];
          }
        }
      }
    }
    return b;
  }
}
