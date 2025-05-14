//class Vertex {
//  var position : float<3>;
//  var normal : float<3>;
//  var uv : float<2>;
//}

class Face {
  var normal : float<3>;
}

class Edge {
  var f1 : ^Face;
  var f2 : ^Face;
  var next : ^Edge;

  static InsertInto(head : &^Edge, edge : ^Edge) {
    if (head == null) {
      head = edge;
    } else {
      edge.next = head;
      head.next = edge;
    }
  }
}

class Mesh {
  Mesh(positions : &[]float<3>, triangles : &[][3]uint) {
    vertices = [triangles.length * 3] new Vertex;
    indices = [triangles.length * 3] new uint;
    var numFaces = triangles.length;
    var edgesByIndex = [positions.length] new ^Edge;
    var faces = [triangles.length] new Face;
    var j = 0u;
    for (var i = 0; i < triangles.length; ++i) {
      var t = triangles[i];
      var p = t[0];
      var q = t[1];
      var r = t[2];
      var edge1 = new Edge{p, q};
      Edge.InsertInto(&edgesByIndex[p], edge1);
      Edge.InsertInto(&edgesByIndex[q], edge1);
      var edge2 = new Edge{q, r};
      Edge.InsertInto(&edgesByIndex[q], edge2);
      Edge.InsertInto(&edgesByIndex[r], edge2);
      var edge3 = new Edge{r, p};
      Edge.InsertInto(&edgesByIndex[r], edge3);
      Edge.InsertInto(&edgesByIndex[p], edge3);
      var p0 = positions[p];
      var p1 = positions[q];
      var p2 = positions[r];
      var normal = Math.cross(Math.normalize(p1 - p0), Math.normalize(p2 - p0));
      indices[j] = j; vertices[j++] = { p0, normal, float<2>(0.0, 0.0) };
      indices[j] = j; vertices[j++] = { p1, normal, float<2>(1.0, 0.0) };
      indices[j] = j; vertices[j++] = { p2, normal, float<2>(1.0, 1.0) };
    }
  }
  var vertices : *[]Vertex;
  var indices : *[]uint;
}
