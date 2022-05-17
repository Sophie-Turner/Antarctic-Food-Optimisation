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
int: numOptions; % Number of different meal options offered at this meal.
int: maxIngredients;
int: maxContains;

array[meals, 1..maxIngredients] of ingredients: mealIngredients;
array[meals, 1..maxContains] of contains: mealContains;
% add amounts of igredient required per meal to calculate cost and how much ingredient required.
array[meals, 1..maxIngredients] of int: mealIngredientsAmounts;
int: numPeople;
 
enum weekdays = {Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday}; 
enum mealtimes = {dinner, tea}; 
 
array[weekdays, mealtimes] of var meals: mealsOffered;
include "alldifferent.mzn";
% All the options on each mealtime should be different, and each row of meals should be different, but the whole array doesn't need to be different.
constraint alldifferent(mealsOffered);
array[weekdays, mealtimes, 1..numOptions] of var meals: mealsServed;
constraint forall(i in 1..length(weekdays), time in mealtimes, k in 1..numOptions)
                 (mealsServed[weekdays[i], time, k] = 
                  mealsOffered[weekdays[((i+k) mod 7)+1], time]);

solve satisfy;

%output["\(mealsOffered)\n\(mealsServed)"];
output["The meals served for \(day) \(time) are \(mealsServed[day, time, 1]), \(mealsServed[day, time, 2]) and \(mealsServed[day, time, 3]).\n" | day in weekdays, time in mealtimes];