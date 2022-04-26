array[int] of int: readings;
int: start;
int: n = length(readings);
set of int: HOUR = 1..n;
set of int: HOUR0 = 0..n;

array[HOUR0] of var 25..30: temp;
array[HOUR] of var ACTION: choice;

enum ACTION = {heat, strongHeat, cool, strongCool, doNothing};
array[ACTION] of int: cost = [1, 5, 3, 9, 0];
array[ACTION] of int: heatEffect = [1, 4, -2, -5, 0];

constraint temp[0] = start;

constraint forall(h in HOUR)
                 (temp[h] = (temp[h-1] + readings[h]) div 2 + heatEffect[choice[h]]);                 
                                                 
var int: totalCost = sum(h in HOUR)(cost[choice[h]]);                                                   
                                                       
solve minimize totalCost;

output["temp \(temp) \n choice \(choice) \n total cost \(totalCost)"]


