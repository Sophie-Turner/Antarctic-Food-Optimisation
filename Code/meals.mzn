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
array[meals] of int: mealCookingCosts;
int: numMeals = length(meals);
int: numOptions; % Number of different meal options offered at this meal.
int: maxIngredients;
int: maxContains;

array[meals, 1..maxIngredients] of ingredients: mealIngredients;
array[meals, 1..maxContains] of contains: mealContains;
% add amounts of igredient required per meal to calculate cost and how much ingredient required.
array[meals, 1..maxIngredients] of int: mealIngredientsAmounts;

enum sides;
array[sides] of int: sideCookingCosts;
array[sides] of ingredients: sideIngredients;
int: numSidesOffered; 

enum desserts;
array[desserts] of int: dessertCookingCosts;
array[desserts, 1..maxIngredients] of ingredients: dessertIngredients;
array[desserts, 1..maxContains] of contains: dessertContains;
array[desserts, 1..maxIngredients] of int: dessertAmounts;
int: numDessertsOffered;

int: numPeople;
 
enum weekdays = {Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday}; 
enum mealtimes = {lunch, tea}; 
 
include "alldifferent.mzn"; 
% All the options on each mealtime should be different, and each row of meals should be different, but the whole array doesn't need to be different. 
 
array[weekdays, 1..numOptions] of var meals: mealsServed; 
array[weekdays, 1..numOptions] of var int: numServed;
constraint alldifferent(mealsServed);
% A variety of meals must be offered.
constraint forall(day in weekdays, optionNum in 1..numOptions)
                 (numServed[day, optionNum] > 0);
% The right number of meals must be offered.
constraint forall(day in weekdays)
                 (sum(optionNum in 1..numOptions)
                     (numServed[day, optionNum]) = numPeople);
                 
% multiply by 2 because each meal is served twice a day.
var int: mealsCost = 2 * sum(day in weekdays)
                             (sum(optionNum in 1..numOptions, ingredientNum in 1..maxIngredients)
                                 ((sum(costSource in costSources)
                                     (costs[mealIngredients[mealsServed[day, optionNum], ingredientNum], costSource])
                                  * mealIngredientsAmounts[mealsServed[day, optionNum], ingredientNum]
                                  * numServed[day, optionNum])
                                  + mealCookingCosts[mealsServed[day, optionNum]]));  

% Each side is offfered at least once.
array[weekdays, 1..numSidesOffered] of var sides: sidesServed;
constraint forall(option in sides)(exists (day in weekdays, j in 1..numSidesOffered)(sidesServed[day, j] = sides[option]));
array[weekdays, 1..numSidesOffered] of var int: numSidesServed;
constraint forall(day in weekdays, optionNum in 1..numSidesOffered)
                 (numSidesServed[day, optionNum] = numPeople);
                 
% multiply by 2 because each meal is served twice a day.
var int: sidesCost = 2 * sum(day in weekdays)
                             (sum(optionNum in 1..numSidesOffered)
                                 ((sum(costSource in costSources)
                                     (costs[sideIngredients[sidesServed[day, optionNum]], costSource])
                                  * numSidesServed[day, optionNum])
                                  + sideCookingCosts[sidesServed[day, optionNum]]));                 


array[weekdays, 1..numDessertsOffered] of var desserts: dessertsServed;
constraint alldifferent(dessertsServed);
array[weekdays, 1..numDessertsOffered] of var int: numDessertsServed;
constraint forall(day in weekdays, optionNum in 1..numDessertsOffered)
                 (numDessertsServed[day, optionNum] = numPeople);

% multiply by 2 because each meal is served twice a day.
var int: dessertsCost = 2 * sum(day in weekdays)
                               (sum(optionNum in 1..numDessertsOffered, ingredientNum in 1..maxIngredients)
                                   ((sum(costSource in costSources)
                                        (costs[dessertIngredients[dessertsServed[day, optionNum], ingredientNum], costSource])
                                     * dessertAmounts[dessertsServed[day, optionNum], ingredientNum]
                                     * numDessertsServed[day, optionNum])
                                     + dessertCookingCosts[dessertsServed[day, optionNum]]));

var int: totalCost = mealsCost + sidesCost;

solve satisfy;

%output["\(mealsOffered)\n\(mealsServed)"];
output["On \(day), for \(time), \(numServed[day, 1]) servings of \(mealsServed[day, 1]), \(numServed[day, 2]) servings of \(mealsServed[day, 2]) and \(numServed[day, 3]) servings of \(mealsServed[day, 3])\nwill be provided with \(numSidesServed[day, 1]) optional extra servings of \(sidesServed[day, 1]) and \(numDessertsServed[day, 1]) servings of \(desserts[day]) for dessert.\n" | day in weekdays, time in mealtimes];
output["The total cost per week will be \(totalCost)p including purchase, transport, storage and cooking."];