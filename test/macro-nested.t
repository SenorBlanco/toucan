include "include/test.t"
#define WRAPPER
#define INT int #end
#define SUM 3+4 #end
#end

WRAPPER

var a : INT = SUM;
Test.Expect(a == 7);
