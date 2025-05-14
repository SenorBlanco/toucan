//class Vertex {
//  var position : float<3>;
//  var normal : float<3>;
//  var uv : float<2>;
//}

class Face {
  var normal : float<3>;
}

class Edge {
  var v2 : int;
  var face : *Face;
  var next : *Edge;

  static Create(v2 : uint, face : *Face, head : &*Edge) : *Edge {
    var edge = new Edge;
    edge.v2 = v2;
    edge.face = face;
    if (head != null) {
      edge.next = head;
    }
    head = edge;
    return edge;
  }
}

class Mesh {
  Mesh(positions : &[]float<3>, triangles : &[][3]uint, creaseAngle : float) {
    vertices = [triangles.length * 3] new Vertex;
    indices = [triangles.length * 3] new ushort;
    var edgesByFirstIndex = [positions.length] new *Edge;
    var normals = [triangles.length] new [3]float<3>;
    for (var i = 0; i < triangles.length; ++i) {
      var t = triangles[i];
      var p : [3]float<3>;
      for (var j = 0; j < 3; ++j) {
        p[j] = positions[t[j]];
      }
      var face = new Face;
      face.normal = Math.normalize(Math.cross(p[1] - p[0], p[2] - p[0]));
      for (var j = 0; j < 3; ++j) {
        normals[i][j] = face.normal;
        Edge.Create(t[(j + 1) % 3], face, &edgesByFirstIndex[t[j]]);
      }
    }
    var cosAngle = Math.cos(creaseAngle);
    for (var i = 0; i < triangles.length; ++i) {
      for (var j = 0; j < 3; ++j) {
        var v1 = triangles[i][j];
        for (var edge1 = edgesByFirstIndex[v1]; edge1 != null; edge1 = edge1.next) {
          for (var edge2 = edgesByFirstIndex[edge1.v2]; edge2 != null; edge2 = edge2.next) {
            if (edge2.v2 == v1) {
              if (Math.dot(edge1.face.normal, edge2.face.normal) > cosAngle) {
                normals[i][j] += edge2.face.normal;
              }
            }
          }
        }
      }
    }
    var dstIndex = 0;
    for (var i = 0; i < triangles.length; ++i ) {
      for (var j = 0; j < 3; ++j) {
        var v : Vertex;
        v.position = positions[triangles[i][j]];
        v.normal = Math.normalize(normals[i][j]);
        vertices[dstIndex] = v;
        indices[dstIndex] = (ushort) dstIndex;
        dstIndex++;
      }
    }
  }
  var vertices : *[]Vertex;
  var indices : *[]ushort;
}
