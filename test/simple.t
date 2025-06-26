class String {
  String() { System.PrintLine("String constructed"); }
 ~String() { System.PrintLine("String destructed"); }
}

var a = new String();
//System.PrintLine(String.From(42).Get());
