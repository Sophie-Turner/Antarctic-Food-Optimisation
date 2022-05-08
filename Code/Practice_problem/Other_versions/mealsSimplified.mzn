enum ingredients;
% A null ingredient is needed for static 2d array placeholders.
ingredients: nothing;

enum meals;
int: numMeals = length(meals);
int: maxIngredients;

array[meals, 1..maxIngredients] of ingredients: mealIngredients;
     
enum people;
int: numPeople = length(people);
int: maxRefusals;

array[people, 1..maxRefusals] of ingredients: doesNotEat;
 
array[people] of var meals: servedMeals;

% Make sure everyone can eat the ingredients in their meal.
constraint forall(person in people)
                 (forall(i in 1..maxRefusals 
                 % ignore null placeholders.
                  where doesNotEat[person, i] != nothing)
                 (forall(j in 1..maxIngredients)
                 (doesNotEat[person, i] != 
                  mealIngredients[servedMeals[person], j])));
           
% We don't want to make the cook prepare lots of different recipes.
include "global_cardinality_fn.mzn";
array[1..numMeals] of var int: occurrences = 
  global_cardinality(servedMeals, [i | i in 1..numMeals]); 

% We don't want to make the cook prepare lots of different recipes.
var int: numRecipes = count(o in occurrences)(o > 0);
solve minimize numRecipes;

output["\(people[i]) will be served \(servedMeals[i]).\n" | i in people];  
   



     