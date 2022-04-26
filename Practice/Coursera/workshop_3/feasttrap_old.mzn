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
array[COURSE] of var DISH: dish;

% first dish must be salty.
constraint taste[dish[1]] = salty;
% last dish must be sweet.
constraint taste[dish[len]] = sweet;
% no dish can be served twice.
constraint alldifferent(dish);
% no taste can occur twice in a row.
constraint forall(i in 1..len-1)(taste[dish[i]] != taste[dish[i+1]]);
% spicy dishes must be followed by bland or sweet.
% sour dishes must be followed by bland or umami.
% sweet dishes must not be followed by spicy or umami.
constraint forall(i in 1..len-1)(if taste[dish[i]] = spicy then taste[dish[i+1]] = bland \/ taste[dish[i+1]] = sweet else if taste[dish[i]] = sour then taste[dish[i+1]] = bland \/ taste[dish[i+1]] = umame else if taste[dish[i]] = sweet then taste[dish[i+1]] != spicy /\ taste[dish[i+1]] != umame endif endif endif);

% after a hot dish, a cold dish cannot be served until a warm dish has been served.
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

