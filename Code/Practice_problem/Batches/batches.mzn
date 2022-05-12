enum ingredients;
% A null ingredient is needed for static 2d array placeholders.
ingredients: notIngredient;

enum contains = {none, meat, milk, gluten, egg, sugars};
contains: nothing;

int: batchSize; % Number of portions in a batch.

enum costSources;
array[ingredients, costSources] of int: costs;
array[ingredients, costSources] of var int: batchCosts;
constraint forall(i in ingredients, j in costSources)(batchCosts[i, j] = (costs[i, j] * batchSize));

% Assumed that all meals contain enough vitamins and minerals apart from vitamin D which can be lacking in this environment. 
enum nutrients = {calories, carbohydrate, fat, fibre, protein};
% Amount of each nutrient in 100g of ingredient.
array[ingredients, nutrients] of int: nutrition;
array[ingredients, nutrients] of var int: batchNutrition;
constraint forall(i in ingredients, j in nutrients)(batchNutrition[i, j] = (nutrition[i, j] * batchSize));

enum meals;
int: numMeals = length(meals);
int: numOptions; % Number of different meal options offered at this meal.
int: maxIngredients;
int: maxContains;

array[meals, 1..maxIngredients] of ingredients: mealIngredients;
array[meals, 1..maxContains] of contains: mealContains;
% add amounts of igredient required per meal to calculate cost and how much ingredient required.
array[meals, 1..maxIngredients] of int: mealIngredientsAmounts;
array[meals, 1..maxIngredients] of var int: batchIngredientsAmounts;
constraint forall(i in meals, j in 1..maxIngredients)
(batchIngredientsAmounts[i, j] = (mealIngredientsAmounts[i, j] * batchSize));

int: numPeople;
array[contains] of int: numRefusals;
 
array[1..numOptions] of var meals: mealsServed;  
array[1..numOptions] of var int: batchesServed;

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

% Work out how much nutrition the group needs per day.
array[nutrients] of var float: totalNutrientsRequired;
constraint forall(i in nutrients)
          (totalNutrientsRequired[i] = 
          (minNutrients[i] * numPeople) 
          + (minNutrients[i] * numPhysicalWorkers * physicalMultiplier)
          + (minNutrients[i] * numMen * menMultiplier)); 

% Make sure the correct variety of meal types exists (at least 1 vegan and 1 gluten free meal).
include "alldifferent.mzn";
constraint alldifferent(mealsServed);
                                
% There must be a variety of meals on offer, and no negative values.                                
constraint forall(count in batchesServed)(count > 0);                                  
                                
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(foodType in contains)
           (numRefusals[foodType] <= 
            sum(i in 1..numOptions)
           (forall(j in 1..maxContains)
           (mealContains[mealsServed[i], j] != foodType) 
            * batchesServed[i] * batchSize));
            
% Make sure there is a vegan option.            
constraint exists(option in mealsServed)
          (forall(item in 1..maxContains)
          (mealContains[option, item] != meat
          /\ mealContains[option, item] != egg
          /\ mealContains[option, item] != milk));

var int: totalMealsServed = sum(batchesServed) * batchSize;
constraint totalMealsServed >= numPeople;

% Work out the total nutrition on offer.
array[nutrients] of var int: totalNutritionServed;
constraint forall(nutrient in nutrients)
           (totalNutritionServed[nutrient] = 
            sum(i in 1..numOptions, j in 1..maxIngredients)
            (nutrition[mealIngredients[mealsServed[i], j], nutrient]
             * batchIngredientsAmounts[mealsServed[i], j]
             * batchesServed[i]));  
             
% Don't serve more than people can eat.             
constraint totalNutritionServed[calories] < totalNutrientsRequired[calories];

% For every meal served, for every ingredient in that meal and its amount, 
% find cost of that ingredient.                         
var int: totalCost = sum(i in 1..numOptions, j in 1..maxIngredients)
                   (sum(k in costSources)(batchCosts[mealIngredients[mealsServed[i], j], k] 
                    div batchSize)
                    * batchIngredientsAmounts[mealsServed[i], j]
                    * batchesServed[i]);                     

% maximise nutrition and minimise cost and food waste.
% giving extra weight to food waste otherwise it suggests silly amounts of food.
var float: objective = totalNutritionServed[calories] div (totalCost + (totalMealsServed - numPeople)*100); 

solve maximize objective;

output["\(batchesServed[i]) batches of \(batchSize) servings of \(mealsServed[i]) will be provided.\n" | i in 1..numOptions];  
output["A total of \(totalMealsServed) servings of food will be provided.\n"];
output["The total cost will be \(totalCost)p.\n"]; 
output["The total amount of \(nutrients[i]) served is \(totalNutritionServed[i]).\n" | i in nutrients]; 