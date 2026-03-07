include "include/test.t"
#def WRAPPER
#def INT int #enddef
#def SUM 3+4 #enddef
#enddef

WRAPPER

var a : INT = SUM;
Test.Expect(a == 7);
