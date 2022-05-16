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

enum sides;
array[1..6] of ingredients: sideContains;
int: numSidesOffered; 

enum desserts;
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
constraint alldifferent(mealsServed);

% Each side is offfered at least once.
array[weekdays, 1..numSidesOffered] of var sides: sidesServed;
constraint forall(option in sides)(exists (day in weekdays, j in 1..numSidesOffered)(sidesServed[day, j] = sides[option]));

array[weekdays, 1..numDessertsOffered] of var desserts: dessertsServed;
constraint alldifferent(dessertsServed);

solve satisfy;

%output["\(mealsOffered)\n\(mealsServed)"];
output["The meals served for \(day) \(time) are \(mealsServed[day, 1]), \(mealsServed[day, 2]) and \(mealsServed[day, 3]) \nwith optional extra \(sidesServed[day, 1]), and the dessert is \(desserts[day]).\n" | day in weekdays, time in mealtimes];