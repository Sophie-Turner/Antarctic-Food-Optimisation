% Dance trap starter code provided with assignment:

enum LEGS = {spin, leap, waltz, curtsey, prep, stand};
enum ARMS = {beckon, out, up, wrapped, neutral};
enum FACE = {smile, wink, batt, think, glow, blank};

int: maxlen; % max number of moves in dance. 
set of int: STEP = 1..maxlen;

% how many times each move can be made.
array[LEGS] of int: maxlegs; 
array[ARMS] of int: maxarms;
array[FACE] of int: maxface;
constraint assert(maxlegs[stand] >= maxlen, "maxlegs[stand] smaller than maxlen");
constraint assert(maxarms[neutral] >= maxlen, "maxarms[neutral] smaller than maxlen");
constraint assert(maxface[blank] >= maxlen, "maxface[blank] smaller than maxlen");
array[LEGS,ARMS] of int: dance_value;
array[ARMS,FACE] of int: entice_value;
constraint assert(dance_value[stand,neutral] = 0, "incorrect dance_value array");
constraint assert(entice_value[neutral,blank] = 0, "incorrect entice_value array");
int: boredom; % how bored each step makes the viewer

var STEP: len; % len is always 1
array[STEP] of var LEGS: legs;
array[STEP] of var ARMS: arms;
array[STEP] of var FACE: face;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sophie's code:

include "regular.mzn";

array[1..6,LEGS] of 0..6: legTransitions = 
[|0,0,0,4,5,6
 |1,0,3,0,0,6
 |1,0,3,0,5,6
 |1,0,3,4,0,6
 |1,2,3,4,5,6
 |1,0,3,4,5,6
|];

constraint regular([legs[i] | i in STEP], 6, 6, legTransitions, 6, {6});

% No more than 3 waltz in a row.
constraint forall(i in 1..maxlen-3)((legs[i]=waltz /\ legs[i+1]=waltz) /\ legs[i+2]=waltz -> legs[i+3]!=waltz);

% After a waltz she must stand before she can curtsey.
constraint forall(i in 1..maxlen-1)
                 ((legs[i]=waltz -> 
                 forall(j in i+1..maxlen)       
                 (legs[j]=curtsey -> 
                 exists(k in i+1..j-1)
                 (legs[k]=stand))));

% No more of each move than maxlegs for that move.
constraint forall(move in legs)((sum(i in legs)(i = move)) <= maxlegs[move]);
constraint forall(move in arms)((sum(i in arms)(i = move)) <= maxarms[move]);
constraint forall(move in face)((sum(i in face)(i = move)) <= maxface[move]);

array[1..5,ARMS] of 0..5: armTransitions = 
[|0,2,3,4,5
 |1,0,3,0,5
 |1,2,0,0,5
 |0,2,3,0,5
 |0,2,3,4,5
|];

constraint regular([arms[i] | i in STEP], 5, 5, armTransitions, 5, {5});

array[1..6,FACE] of 0..6: faceTransitions = 
[|0,2,3,0,5,6
 |1,0,3,4,5,6
 |1,2,0,0,5,6
 |1,2,3,0,5,6
 |1,2,3,4,0,6
 |1,2,3,4,5,6
|];

constraint regular([face[i] | i in STEP], 6, 6, faceTransitions, 6, {6});

var int: totalValue = sum(i in 1..len)(dance_value[legs[i], arms[i]]);
var int: totalEnticement = sum(j in 1..len)(entice_value[arms[j], face[j]]);

constraint legs[len] = stand;
constraint arms[len] = neutral;
constraint face[len] = blank;

var int: dancePower =  (totalValue + totalEnticement) - (boredom * len);

solve maximize dancePower;

output[" dance power: \(dancePower) \n length of dance: \(len) \n legs: \(legs) \n arms: \(arms) \n face: \(face)"];