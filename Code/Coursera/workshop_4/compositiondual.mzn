include "inverse.mzn";

int: n;
set of int: notes = 1..n;
set of int: differences = 1..n-1;

array[1..n] of var notes: order;
array[1..n-1] of var differences: diffs;
%inverse of above 
array[1..n] of var notes: posn;
array[1..n-1] of var differences: dposn;

constraint inverse(order, posn);
constraint inverse(diffs, dposn);
constraint forall(i in 1..n-1)
  (abs(order[i]-order[i+1])=diffs[i]);

output["\(order) \n  \(diffs)\n\(posn)\n  \(dposn)"];