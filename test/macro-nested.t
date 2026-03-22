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

#def DECLARE(NAME, TYPE) var NAME : TYPE; #enddef

#def DECLARE_INT(NAME) DECLARE(int, NAME); #enddef

DECLARE(b, int);
