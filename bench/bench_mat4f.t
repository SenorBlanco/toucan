class Utils {
  static dot(v1 : float<4>, v2 : float<4>) : float {
    var r = v1 * v2;
    return r.x + r.y;
  }
}
var m0 = float<4>(1.0, 0.0, 0.0, 0.0);
var m1 = float<4>(0.0, 1.0, 0.0, 0.0);
var m2 = float<4>(0.0, 0.0, 1.0, 0.0);
var m3 = float<4>(0.0, 0.0, 0.0, 1.0);
var v = float<4>(1.0, 2.0, 3.0, -4.0);
for(var i = 0; i < 1000000000; i = i + 1) {
  var x = Utils.dot(m0, v);
  var y = Utils.dot(m1, v);
  var z = Utils.dot(m2, v);
  var w = Utils.dot(m3, v);
}
