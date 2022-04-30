array[1..5] of int: testArray0 = [1,1,1,1,1];

array[1..5] of int: testArray1 = [1,2,3,4,5];

enum testEnum = {something1, something2, something3, something4, something5};

array[testEnum, 1..5] of int: test2dArray = [|1,2,3,4,5|6,7,8,9,0|1,2,3,4,5|6,7,8,9,0|1,2,3,4,5|];

int: testSum = sum(i in testArray0, j in testArray0)(i + j);
int: testSum2 = sum(i in testArray0)(sum(j in testArray0)(i+j));

output["\(testSum)"];
