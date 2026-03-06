include "include/test.t"
#define WRAPPER
#define INT int #end
#end

WRAPPER

var a : INT = 7;
Test.Expect(a == 7);
