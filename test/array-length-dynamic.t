include "include/test.t"

var f = [3] new float;
// TODO: add a dereference here, once raw ptrs to array contain length
Test.Expect(f.length == 3);
