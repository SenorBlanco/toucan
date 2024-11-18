var a : [3]int = {1, 2, 3};
var pa = (&[]int) &a;
pa[0] = 0;
