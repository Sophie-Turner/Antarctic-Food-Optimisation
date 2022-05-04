include "alldifferent.mzn";

var 1..9: S;
var 0..9: E;
var 1..9: V;
var 0..9: N;
var 1..9: P;
var 0..9: A;
var 0..9: C;
var 0..9: R;

constraint alldifferent([S,E,V,N,P,A,C,R]);

var int: seven = S*10000 +E*1000 +V*100 +E*10 +N; 
var int: paces = P*10000 +A*1000 +C*100 +E*10 +S;
var int: verse = V*10000 +E*1000 +R*100 +S*10 +E;

constraint verse = seven + paces;

solve maximize verse; 

output["verse = \(verse)"];
