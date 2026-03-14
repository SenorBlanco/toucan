include "include/test.t"
#def FOO
#def BAR
#def INT int #enddef
#def SUM 3+4 #enddef
#enddef
BAR
#enddef

FOO

var a : INT = SUM;
Test.Expect(a == 7);
