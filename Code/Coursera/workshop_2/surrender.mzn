% workshop 2
% select a set of trade negotiation party
enum NEGOTIATOR;
NEGOTIATOR: dummy; 

int: l; % minimum party size
int: u; % maximum party size
int: m; % minimum joint ability

array[NEGOTIATOR] of int: honor;
array[NEGOTIATOR,NEGOTIATOR] of int: joint;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%num members between l and u
var int: members;
constraint members >= l;
constraint members <= u;

%define party
%party is a set of negotiator
var set of NEGOTIATOR: party;

constraint card(party) = members;

% Don't include the dummy.
constraint not(dummy in party);

%look up joint values from pairs values
var int: total = sum(i,j in party where i < j)(joint[i, j]);

%sum of pairs >= m
constraint total >= m;

var int: obj;
constraint obj = min([honor[i] | i in party]);

solve maximize obj;

output[" party: \(party) \n minhonor: \(obj) \n members: \(members) \n total: \(total)"];


