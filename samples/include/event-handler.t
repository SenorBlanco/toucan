include "utils.t"

class EventHandler {
  void Rotate(int<2> diff) {
    rotation += (float<2>) diff / 200.0;
  }
  void Handle(Event* event) {
    if (event.type == MouseDown) {
      mouseDown = true;
    } else if (event.type == MouseUp) {
      mouseDown = false;
    } else if (event.type == MouseMove) {
      var diff = event.position - prevPosition;
      if (mouseDown || (event.modifiers & Control) != 0) {
        this.Rotate(diff);
      } else if ((event.modifiers & Shift) != 0) {
        distance += (float) diff.y / 100.0;
      }
      prevPosition = event.position;
    } else if (event.type == TouchStart) {
      prevTouches = event.touches;
    } else if (event.type == TouchMove) {
      if (event.numTouches != prevNumTouches) {
      } else if (event.numTouches == 1) {
        this.Rotate(event.touches[0] - prevTouches[0]);
      } else if (event.numTouches == 2) {
        var prevDistance = Utils.length((float<2>) (prevTouches[1] - prevTouches[0]));
        var curDistance = Utils.length((float<2>) (event.touches[1] - event.touches[0]));
        distance *= prevDistance / curDistance;
      }
      prevTouches = event.touches;
      prevNumTouches = event.numTouches;
    }
  }
  var mouseDown : bool = false;
  var prevPosition : int<2>;
  var prevTouches : int<2>[10];
  var prevNumTouches : int;
  var rotation : float<2>;
  var distance : float;
}
