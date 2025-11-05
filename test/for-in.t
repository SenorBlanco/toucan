include "include/test.t"

var numbers : int<5> = {1, 2, 3, 4, 5};
var sum = 0;
for (a in numbers) {
  sum += a;
}
Test.Expect(sum == 15);
