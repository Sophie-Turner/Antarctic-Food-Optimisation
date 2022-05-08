enum ingredients;
% A null ingredient is needed for static 2d array placeholders.
ingredients: notIngredient;

enum contains = {none, meat, milk, gluten, egg, sugars};
contains: nothing;

array[ingredients] of int: ingredientsBuyCost;
array[ingredients] of int: ingredientsStorageCost;

enum meals;
int: numMeals = length(meals);
int: maxIngredients;
int: maxContains;

constraint assert(length(ingredientsBuyCost) = length(ingredients), "Each ingredient needs an associated cost.");
constraint assert(length(ingredientsStorageCost) = length(ingredients), "Each ingredient needs an associated cost.");

array[meals, 1..maxIngredients] of ingredients: mealIngredients;
array[meals, 1..maxContains] of contains: mealContains;
% add amounts of igredient required per meal to calculate cost and how much ingredient required.
array[meals, 1..maxIngredients] of int: mealIngredientsAmounts;
int: numPeople;
array[contains] of int: numRefusals;   
 
array[1..3] of var meals: mealsServed;
array[1..3] of var int: numServed;  

% Make sure the correct variety of meal types exists (at least 1 vegan and 1 gluten free meal).
include "alldifferent.mzn";
constraint alldifferent(mealsServed);
                                
% There must be 3 meals on offer.                                
constraint forall(count in numServed)(count > 0);                                 
                                
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(foodType in contains)
           (numRefusals[foodType] <= 
            sum(i in 1..3)
           (forall(j in 1..maxContains)
           (mealContains[mealsServed[i], j] != foodType) 
            * numServed[i]));

var int: totalMealsServed = sum(numServed);
constraint totalMealsServed >= numPeople;

% For every meal served, for every ingredient in that meal and its amount, 
% find cost of that ingredient.                         
var int: cost = sum(i in 1..3,
                       j in 1..maxIngredients)
                       ((ingredientsBuyCost[mealIngredients[mealsServed[i], j]] 
                        + ingredientsStorageCost[mealIngredients[mealsServed[i], j]]) 
                        * mealIngredientsAmounts[mealsServed[i], j]
                        * numServed[i]);

solve minimize cost;

output["\(numServed[i]) servings of \(mealsServed[i]) will be provided.\n" | i in 1..3];  
output["A total of \(totalMealsServed) servings of food will be provided.\n"];
output["The total cost will be \(cost)p."];
  