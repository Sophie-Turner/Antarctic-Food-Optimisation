enum ingredients;
enum meals;
enum people;
int: numPeople;
int: numMeals;
array[meals, ingredients] of bool: mealIngredients;
array[people, ingredients] of bool: eats;

array[people] of people: guests = people;
array[1..numPeople] of var meals: servedMeals;

% Make sure everyone can eat the ingredients.
constraint forall(i in 1..numPeople)
          (forall(item in ingredients)
          (mealIngredients[servedMeals[i], item] <= 
           eats[people[i], item]));

% We don't want to make the cook prepare lots of different recipes.
include "global_cardinality_fn.mzn";
array[1..numMeals] of var int: occurrences = 
  global_cardinality(servedMeals, [i | i in 1..numMeals]);

% Test to see if anyone is unable to eat any of the meals.
%solve minimize occurrences[numMeals]; 
%output["\(occurrences[numMeals])"];  

% Make sure everyone can be served a meal;
constraint (occurrences[numMeals] = 0);
% We don't want to make the cook prepare lots of different recipes.
var int: numRecipes = count(o in occurrences)(o > 0);
solve minimize numRecipes;

%output["\(occurrences) \n \(servedMeals) \n \(numRecipes)"];
output["\(guests[i]) will be served \(servedMeals[i]).\n" | i in people];
output["\(numRecipes) different recipes will be used."];

   




  