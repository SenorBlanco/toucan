include "include/test.t"

var a = [3] new int;
var b = [3] new int{};
var c = [3] new int{42};
var d = [3] new int{3, 2, 1};

Test.Expect(a[0] == 0 && a[1] == 0 && a[2] == 0);
Test.Expect(b[0] == 0 && b[1] == 0 && b[2] == 0);
Test.Expect(c[0] == 42 && c[1] == 42 && c[2] == 42);
Test.Expect(d[0] == 3 && d[1] == 2 && d[2] == 1);
