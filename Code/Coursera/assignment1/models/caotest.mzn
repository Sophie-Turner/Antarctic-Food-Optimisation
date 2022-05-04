include "alldifferent.mzn";

var 1..9: C;
var 1..9: A;
var 0..9: O;
var 1..9: Z;
var 1..9: H;
var 1..9: I;
var 1..9: P;
var 1..9: T;
var 1..9: E;
var 1..9: S;

constraint alldifferent([C,A,O,Z,H,I,P,T,E,S]);

constraint P = 3*Z;

var int: cao = C*100+A*10+O;
var int: zhi = Z*100+H*10+I;
var int: pi = P*10+I;
var int: testWord = T*1000+E*100+S*10+T;

constraint testWord = cao*2+zhi+pi;

solve satisfy;
