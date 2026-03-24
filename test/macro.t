#include "include/test.t"
#def INT int #enddef
#def SUM 3+4 #enddef

var a : INT = SUM;
Test.Expect(a == 7);

#def OP +           #enddef
#def NEWSUM 2 OP 2  #enddef

var b : int = NEWSUM;
Test.Expect(b == 4);
