int: n; % number of court members
set of int: COURT = 1..n;
int: emperor = 1;
array[COURT] of int: rank;
array[COURT] of int: ability;

int: m; % number of horses
set of int: HORSE = 1..m;
array[HORSE] of int: beauty;
array[HORSE] of int: speed;

array[COURT,HORSE] of int: enjoy;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sophie's code:

% imports.
include "inverse.mzn";

% find the smallest number (m or n). This will be matches array length.
int: numPairs = min(n, m); 

% match one to one m to n, leaving out any         extras at the end. Array of matches. 
set of int: pairs = 1..numPairs;  
array[pairs] of var COURT: humans;
array[pairs] of var HORSE: horses;

% inverse thingies.
constraint inverse(humans, horses);

% If more humans than horses, Lowest ranked court members get left out.
 
% emperor must have a horse. 
 
% emperor must enjoy the day more than anyone else.

% For every human horse pair, higher rank -> prettier horse.

% order pairs by ascending horse speed.
% iterate and check if any rider abilities are not ascending. 
% for every human horse pair, if faster horse paired with lower ability, add 100 to penalty.

% objective = total enjoyment minus total penalty. 

% maximize objective.

% output.
output["\(humans) \(horses)"];