include "include/test.t"

#def DECLARE_INT(A) var A : int #enddef

DECLARE_INT(i) = 42;
Test.Expect(i == 42);
