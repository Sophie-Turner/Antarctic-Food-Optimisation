enum ingredients;
% A null ingredient is needed for static 2d array placeholders.
ingredients: notIngredient;

enum contains = {none, meat, milk, gluten, egg, sugars};
contains: nothing;

enum costSources;
array[ingredients, costSources] of int: costs;

% Assumed that all meals contain enough vitamins and minerals apart from vitamin D which can be lacking in this environment. 
enum nutrients = {calories, carbohydrate, fat, fibre, protein};
% Amount of each nutrient in 100g of ingredient.
array[ingredients, nutrients] of int: nutrition;

enum meals;
int: numMeals = length(meals);
int: numOptions;
int: maxIngredients;
int: maxContains;

array[meals, 1..maxIngredients] of ingredients: mealIngredients;
array[meals, 1..maxContains] of contains: mealContains;
% add amounts of igredient required per meal to calculate cost and how much ingredient required.
array[meals, 1..maxIngredients] of int: mealIngredientsAmounts;
int: numPeople;
array[contains] of int: numRefusals;
 
array[1..numOptions] of var meals: mealsServed;
array[1..numOptions] of var int: numServed;  

% The minimum grams of nutrients people require per day.
array[nutrients] of int: minNutrients = [2000, 275, 60, 23, 45];
% It is higer in the winter because of the colder climate.
float: winterMultiplier = 0.25;
% People doing physical jobs need double the food of those doing sedentary jobs.
int: numPhysicalWorkers;
int: physicalMultiplier = 1;
% Men need 25% more food than women need.
int: numMen;
float: menMultiplier = 0.25;


array[nutrients] of var float: totalNutrientsRequired;
constraint forall(i in nutrients)
          (totalNutrientsRequired[i] = 
          (minNutrients[i] * numPeople) 
          + (minNutrients[i] * numPhysicalWorkers * physicalMultiplier)
          + (minNutrients[i] * numMen * menMultiplier));

% Make sure the correct variety of meal types exists (at least 1 vegan and 1 gluten free meal).
include "alldifferent.mzn";
constraint alldifferent(mealsServed);
                                
% There must be a variety of meals on offer.                                
constraint forall(count in numServed)(count > 0);                                 
                                
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(foodType in contains)
           (numRefusals[foodType] <= 
            sum(i in 1..numOptions)
           (forall(j in 1..maxContains)
           (mealContains[mealsServed[i], j] != foodType) 
            * numServed[i]));

var int: totalMealsServed = sum(numServed);
constraint totalMealsServed >= numPeople;

% For every meal served, for every ingredient in that meal and its amount, 
% find cost of that ingredient.                         
var int: totalCost = sum(i in 1..numOptions, j in 1..maxIngredients)
                   (sum(k in costSources)(costs[mealIngredients[mealsServed[i], j], k])
                    * mealIngredientsAmounts[mealsServed[i], j]
                    * numServed[i]);                     

solve minimize totalCost;

output["\(numServed[i]) servings of \(mealsServed[i]) will be provided.\n" | i in 1..numOptions];  
output["A total of \(totalMealsServed) servings of food will be provided.\n"];
output["The total cost will be \(totalCost)p.\n"];  