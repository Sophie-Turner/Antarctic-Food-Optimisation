% assignment 2
% select a set of raiding warrior
enum WARRIOR;
WARRIOR: dummy;
enum CLAN; % the clan they belong too

int: l; % minimum raid party size
int: u; % maximum raid party size
int: m; % limit of hatreds

array[WARRIOR] of int: strength;
array[WARRIOR] of CLAN: clan;

array[CLAN,CLAN] of 0..1: hates;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
var int: partySize;
constraint partySize >= l;
constraint partySize <= u;

var set of WARRIOR: raid;
constraint card(raid) = partySize;
constraint not(dummy in raid);

var int: totalHates = sum(i,j in raid where i < j)(hates[clan[i], clan[j]]);
constraint totalHates <= m;

var int: obj = sum(person in raid)(strength[person]);

solve maximize obj;

output[" obj: \(obj) \n raid: \(raid)"];

  
