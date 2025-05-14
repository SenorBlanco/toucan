//class Vertex {
//  var position : float<3>;
//  var normal : float<3>;
//  var uv : float<2>;
//}

class Face {
  var normal : float<3>;
}

class Edge {
  var i2 : uint;
  var j2 : uint;
  var face : *Face;
  var next : *Edge;

  static Create(i : uint, j : uint, face : *Face, head : &*Edge) : *Edge {
    var edge = new Edge;
    edge.i2 = i;
    edge.j2 = j;
    edge.face = face;
    if (head != null) {
      edge.next = head;
    }
    head = edge;
    return edge;
  }
}

class Mesh {
  Mesh(positions : &[]float<3>, triangles : &[][3]uint) {
    vertices = [triangles.length * 3] new Vertex;
    indices = [triangles.length * 3] new uint;
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
        Edge.Create(i, (j + 1) % 3, face, &edgesByFirstIndex[t[j]]);
      }
    }
    var creaseAngle = 3.14159;
    var cosAngle = Math.cos(creaseAngle);
    for (var i = 0; i < triangles.length; ++i) {
      for (var j = 0; j < 3; ++j) {
        var v1 = triangles[i][j];
        for (var edge1 = edgesByFirstIndex[v1]; edge1 != null; edge1 = edge1.next) {
          var face1 = edge1.face;
          for (var edge2 = edgesByFirstIndex[triangles[edge1.i2][edge1.j2]]; edge2 != null; edge2 = edge2.next) {
            if (triangles[edge2.i2][edge2.j2] == v1) {
              var face2 = edge2.face;
              if (Math.dot(face1.normal, face2.normal) > cosAngle) {
                normals[i][j] += face2.normal;
                normals[edge2.i2][edge2.j2] = normals[i][j];
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
        indices[dstIndex] = dstIndex;
        dstIndex++;
      }
    }
  }
  var vertices : *[]Vertex;
  var indices : *[]uint;
}
