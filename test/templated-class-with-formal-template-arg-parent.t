#include "include/test.t"

class Base {
  const answer = 42;
}

class Template<BASE, T> : BASE {
  GetAnswer() : T { return answer as T; }
}

var s = new Template<Base, int>;
Test.Expect(s.GetAnswer() == 42);

var t = new Template<Base, float>;
Test.Expect(t.GetAnswer() == 42.0);
