include "include/test.t"
#define INT int #end
#define SUM 3+4 #end

var a : INT = SUM;
Test.Expect(a == 7);
