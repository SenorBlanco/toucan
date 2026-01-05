enum ProjectedPlane {
  XY = 0,
  XZ = 1,
  YZ = 2
}

class TexCoordUtils<VertexType> {
  static ComputeProjectedPlaneUVs(vertices : *[]VertexType, plane : ProjectedPlane) {
    var extentMin = <2>float{ 1000000.0,  1000000.0};
    var extentMax = <2>float{-1000000.0, -1000000.0};
    var ProjectedPlaneToComponent : [3]<2>uint = {
      { 0, 1 }, { 0, 2 }, { 1, 2 }
    };
    var components = ProjectedPlaneToComponent[plane];
    for (var i = 0; i < vertices.length; ++i) {
      var v = &vertices[i];
      v.uv.x = v.position[components.x];
      v.uv.y = v.position[components.y];

      extentMin = Math.min(v.uv, extentMin);
      extentMax = Math.max(v.uv, extentMax);
    }
    for (var i = 0; i < vertices.length; ++i) {
      vertices[i].uv = (vertices[i].uv - extentMin) / (extentMax - extentMin);
    }
  }
}
