include "alldifferent.mzn";

int: n;
set of int: notes = 1..n;
set of int: diffs = 1..n-1;

array[1..n] of var notes: order;
array[1..n-1] of var diffs: difference; 
constraint alldifferent(order);
constraint alldifferent(difference);
constraint forall(i in 1..n-1)
  (abs(order[i]-order[i+1])=difference[i]);

solve satisfy;

output["\(order) \n  \(difference)"];