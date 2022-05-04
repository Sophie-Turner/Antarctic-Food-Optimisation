include "alldifferent.mzn";

var 1..9: B;
var 0..9: E;
var 0..9: A;
var 0..9: N;
var 0..9: S;
var 1..9: C;
var 0..9: R;
var 0..9: Y;
var 0..9: I;
var 0..9: G;

constraint alldifferent([B,E,A,N,S,C,R,Y,I,G]);

var int: beans = B*10000+E*1000+A*100+N*10+S;
var int: crying = C*100000+R*10000+Y*1000+I*100+N*10+G;

constraint crying = beans * 2;

solve satisfy;

output["beans = \(beans)\ncrying = \(crying)\nB=\(B) E=\(E) A=\(A) N=\(N) S=\(S)\nC=\(C) R=\(R) Y=\(Y) I=\(I) G=\(G)"];