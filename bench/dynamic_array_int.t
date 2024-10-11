{
  var outer_count = 1000000;
  var a = new int[1024];
  for (var i = 0; i < a.length; ++i) {
    a[i] = 2000000;
  }
  for (var j = 0; j < outer_count; ++j) {
    for (var i = 0; i < a.length; ++i) {
      a[i] = a[i] * 2 + 1;
    }
  }
}
