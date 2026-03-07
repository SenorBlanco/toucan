include "include/test.t"
#def INT int #enddef
#def SUM 3+4 #enddef

var a : INT = SUM;
Test.Expect(a == 7);
