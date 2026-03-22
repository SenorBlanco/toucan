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

#def DECLARE(NAME, TYPE)
var NAME : TYPE;
#enddef

#def DECLARE_INT(NAME, VALUE)
DECLARE(NAME, int);
NAME = VALUE;
#enddef

DECLARE_INT(b, 42);
Test.Expect(b == 42);
