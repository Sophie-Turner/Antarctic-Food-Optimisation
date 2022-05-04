% Beauty Trap
% Create the most magnificient feast 
enum DISH;
enum TASTE = {spicy, sour, salty, sweet, umame, bland};
enum TEMP = {hot, cold, warm};
%int: ndish;
%set of int: DISH = 1..ndish;
%set of int: TASTE = 1..6;
%int: spicy = 1; int: sour = 2; int: salty = 3; int: sweet = 4; int: umame = 5; int: bland = 6;
%set of int: TEMP = 1..3;
%int: hot = 1; int: cold = 2; int: warm = 3;


array[DISH] of TASTE: taste;
array[DISH] of TEMP: temp;
array[DISH] of bool: heavy;
array[DISH] of int: value;

int: len; % length of banquet
set of int: COURSE = 1..len;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
include "alldifferent.mzn";
include "regular.mzn";

array[COURSE] of var DISH: dish;

% no dish can be served twice.
constraint alldifferent(dish);

array[1..7,TASTE] of 0..7: tasteTransitions = 
[|0,0,4,0,0,0   
 |0,0,0,5,0,7
 |0,0,0,0,6,7
 |2,3,0,5,6,7
 |0,3,4,0,0,7
 |2,3,4,5,0,7
 |2,3,4,5,6,0
|];

constraint regular([taste[dish[i]] | i in COURSE], 7, 6, tasteTransitions, 1, {5});

% after a hot dish, a cold dish cannot be served until a warm dish has been served.
array[1..2,TEMP] of 0..2: tempTransitions = 
[|2,1,1
 |2,0,1
|];

constraint regular([temp[dish[i]] | i in COURSE], 2, 3, tempTransitions, 1, {1,2});

constraint forall(i in 1..len-1)
  ((temp[dish[i]] = hot -> 
   forall(j in i+1..len)
   ((temp[dish[j]] = cold) -> 
   exists(k in i+1..j-1)
  (temp[dish[k]] = warm))));

% no more than 2 heavies in a row.
constraint forall(i in 1..len-2)(if heavy[dish[i]] /\ heavy[dish[i+1]] then not(heavy[dish[i+2]]) endif); 

var int: totalValue = sum(i in 1..len)(value[dish[i]]);
var int: tasteChanges = len-1;
var int: tempChanges = sum(i in 1..len-1)(temp[dish[i]] != temp[dish[i+1]]);
var int: weightChanges = sum(i in 1..len-1)(heavy[dish[i]] != heavy[dish[i+1]]);
var int: obj = totalValue + tasteChanges + tempChanges + weightChanges; 

solve maximize obj;

output[" dish: \(dish)\n obj: \(obj)"];

