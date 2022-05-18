%%%%%%%%%%%%%%%%%%%%%%%%%% FIXED INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%

enum weekdays = {Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday}; 
enum mealtimes = {lunch, tea}; 
enum ingredients;
% A null ingredient is needed for static 2d array placeholders.
ingredients: notIngredient;

enum contains = {none, meat, milk, gluten, egg, nut, seed, sugars};
contains: nothing;

enum costSources = {purchase, transportCost, storageCost};
array[ingredients, costSources] of int: costs;

enum emissionsSources = {production, transportEmission, storageEmission};
array[ingredients, emissionsSources] of int: emissions;

int: maxIngredients;
int: maxContains;

%%%%%%%%%%%%%%%% MAIN MEALS INPUTS %%%%%%%%%%%%%%%%%%

enum meals;
array[meals] of int: mealCookingCosts;
array[meals, 1..maxIngredients] of ingredients: mealIngredients;
array[meals, 1..maxContains] of contains: mealContains;
% add amounts of igredient required per meal to calculate cost and how much ingredient required.
array[meals, 1..maxIngredients] of int: mealIngredientsAmounts;
int: numOptions; % Number of different meal options offered at this meal.

%%%%%%%%%%%%%%%% SIDES INPUTS %%%%%%%%%%%%%%%%%%

enum sides;
array[sides] of int: sideCookingCosts;
array[sides] of ingredients: sideIngredients;
int: numSidesOffered; 

%%%%%%%%%%%%%%%% DESSERTS INPUTS %%%%%%%%%%%%%%%%%%

enum desserts;
array[desserts] of int: dessertCookingCosts;
array[desserts, 1..maxIngredients] of ingredients: dessertIngredients;
array[desserts, 1..maxContains] of contains: dessertContains;
array[desserts, 1..maxIngredients] of int: dessertAmounts;
int: numDessertsOffered;

%%%%%%%%%%%%%%%%%%%% NUTRITION INPUTS %%%%%%%%%%%%%%%%%%%%%%

% Assumed that all meals contain enough vitamins and minerals apart from vitamin D which can be lacking in this environment. 
enum nutrients = {calories, carbohydrate, fat, fibre, protein};
% Amount of each nutrient in 100g of ingredient.
array[ingredients, nutrients] of int: nutrition;

int: numPeople;
% The minimum grams of nutrients people require per day.
array[nutrients] of int: minNutrients = [2000, 275, 60, 23, 45];
% It is higer in the winter because of the colder climate.
float: winterMultiplier = 0.25;
% physical workers need +100% more nutrients per day.
int: numPhysicalWorkers;
int: physicalMultiplier = 1;
% males need +25% more nutrients per day.
int: numMen; 
float: menMultiplier = 0.25;
% num people who do not eat categories.
array[contains] of int: numRefusals;

% Work out how much nutrition the group needs per day.
array[nutrients] of var float: dailyNutrientsRequired;
constraint forall(i in nutrients)
          (dailyNutrientsRequired[i] = 
          (minNutrients[i] * numPeople) 
          + (minNutrients[i] * numPhysicalWorkers * physicalMultiplier)
          + (minNutrients[i] * numMen * menMultiplier)); 
% Work out how much nutrition the group needs per week.
var float: weeklyCalsRequired;
constraint weeklyCalsRequired = dailyNutrientsRequired[calories] * 7;
 
%%%%%%%%%%%%%%%%%%%%%%%%% MAIN MEALS PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
include "alldifferent.mzn"; 
% All the options on each mealtime should be different, and each row of meals should be different, but the whole array doesn't need to be different. 
 
array[weekdays, 1..numOptions] of var meals: mealsServed; 
array[weekdays, 1..numOptions] of var int: numServed;

% A variety of meals must be offered.
constraint alldifferent(mealsServed);
constraint forall(day in weekdays, optionNum in 1..numOptions)
                 (numServed[day, optionNum] >= numPeople div 4);
%constraint forall(day in weekdays, optionNum in 1..numOptions)
%                 (numServed[day, optionNum] >= 0);
% The right number of meals must be offered.
constraint forall(day in weekdays)
                 (sum(optionNum in 1..numOptions)
                     (numServed[day, optionNum]) = numPeople);
                 
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(day in weekdays, 
                  foodType in contains)
                     (numRefusals[foodType] <= 
                      sum(optionNum in 1..numOptions)
                         (forall(itemNum in 1..maxContains)
                                (mealContains[mealsServed[day, optionNum], itemNum] != foodType) 
                                 * numServed[day, optionNum]));            
            
% Make sure there is a vegan option.            
constraint forall(day in weekdays)
                 (exists(optionNum in 1..numOptions)
                        (forall(itemNum in 1..maxContains)
                               (mealContains[mealsServed[day, optionNum], itemNum] != meat
                               /\ mealContains[mealsServed[day, optionNum], itemNum] != egg
                               /\ mealContains[mealsServed[day, optionNum], itemNum] != milk)));                 
                 
% Work out the nutrition on offer.
array[nutrients] of var int: mealsNutritionServed;
constraint forall(nutrient in nutrients)
           (mealsNutritionServed[nutrient] = 
            sum(day in weekdays, optionNum in 1..numOptions, item in 1..maxIngredients)
            (nutrition[mealIngredients[mealsServed[day, optionNum], item], nutrient]
             * mealIngredientsAmounts[mealsServed[day, optionNum], item]
             * numServed[day, optionNum]));                  
                 
var int: mealsCost = sum(day in weekdays, optionNum in 1..numOptions, ingredientNum in 1..maxIngredients)
                        (sum(costSource in costSources)
                             (costs[mealIngredients[mealsServed[day, optionNum], ingredientNum], costSource])
                          * mealIngredientsAmounts[mealsServed[day, optionNum], ingredientNum]
                          * numServed[day, optionNum]
                          + mealCookingCosts[mealsServed[day, optionNum]]);  

var int: mealsEmissions = sum(day in weekdays, optionNum in 1..numOptions, ingredientNum in 1..maxIngredients)
                             (sum(emissionSource in emissionsSources)
                                 (emissions[mealIngredients[mealsServed[day, optionNum], ingredientNum], emissionSource])
                              * mealIngredientsAmounts[mealsServed[day, optionNum], ingredientNum]
                              * numServed[day, optionNum]);

%%%%%%%%%%%%%%%% SIDES PROCESSING %%%%%%%%%%%%%%%%%%%%%

% Each side is offfered at least once.
array[weekdays, 1..numSidesOffered] of var sides: sidesServed;
constraint forall(option in sides)(exists (day in weekdays, j in 1..numSidesOffered)(sidesServed[day, j] = sides[option]));
array[weekdays, 1..numSidesOffered] of var int: numSidesServed;
constraint forall(day in weekdays, optionNum in 1..numSidesOffered)
                 (numSidesServed[day, optionNum] = numPeople);
                 
% Work out the nutrition on offer.
array[nutrients] of var int: sidesNutritionServed;
constraint forall(nutrient in nutrients)
           (sidesNutritionServed[nutrient] = 
            sum(day in weekdays, optionNum in 1..numSidesOffered)
            (nutrition[sideIngredients[sidesServed[day, optionNum]], nutrient]
             * numPeople));                 
                 
var int: sidesCost = sum(day in weekdays, optionNum in 1..numSidesOffered)
                        (sum(costSource in costSources)
                            (costs[sideIngredients[sidesServed[day, optionNum]], costSource])
                         * numSidesServed[day, optionNum]
                         + sideCookingCosts[sidesServed[day, optionNum]]);  
                                  
var int: sidesEmissions = sum(day in weekdays, optionNum in 1..numSidesOffered)
                             (sum(emissionSource in emissionsSources)
                                 (emissions[sideIngredients[sidesServed[day, optionNum]], emissionSource])
                              * numSidesServed[day, optionNum]);               

%%%%%%%%%%%%%%%% DESSERTS PROCESSING %%%%%%%%%%%%%%%%%%%%%

array[weekdays, 1..numDessertsOffered] of var desserts: dessertsServed;
constraint alldifferent(dessertsServed);
array[weekdays, 1..numDessertsOffered] of var int: numDessertsServed;

% Don't offer more desserts than people can eat. Desserts are not important so don't bother much with diet types.
constraint forall(day in weekdays, 
                  optionNum in 1..numDessertsOffered)
                       (numDessertsServed[day, optionNum] = 
                        numPeople - max(itemNum in 1..maxContains)
                           (numRefusals[dessertContains[dessertsServed[day, optionNum], itemNum]]));                     

% Work out the nutrition on offer.
array[nutrients] of var int: dessertsNutritionServed;
constraint forall(nutrient in nutrients)
           (dessertsNutritionServed[nutrient] = 
            sum(day in weekdays, optionNum in 1..numDessertsOffered, item in 1..maxIngredients)
            (nutrition[dessertIngredients[dessertsServed[day, optionNum], item], nutrient]
             * dessertAmounts[dessertsServed[day, optionNum], item]
             * numDessertsServed[day, optionNum]));

var int: dessertsCost = sum(day in weekdays, optionNum in 1..numDessertsOffered, ingredientNum in 1..maxIngredients)
                           (sum(costSource in costSources)
                               (costs[dessertIngredients[dessertsServed[day, optionNum], ingredientNum], costSource])
                            * numDessertsServed[day, optionNum]
                            * dessertAmounts[dessertsServed[day, optionNum], ingredientNum]
                            + dessertCookingCosts[dessertsServed[day, optionNum]]);
                                
var int: dessertsEmissions = sum(day in weekdays, optionNum in 1..numDessertsOffered, ingredientNum in 1..maxIngredients)
                                (sum(emissionSource in emissionsSources)
                                    (emissions[dessertIngredients[dessertsServed[day, optionNum], ingredientNum], emissionSource])
                                 * numDessertsServed[day, optionNum]
                                 * dessertAmounts[dessertsServed[day, optionNum], ingredientNum]);

%%%%%%%%%%%%%%%%%%%%%% GENERAL CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%

% Make sure everyone gets enough food energy.
var int: totalCalsServed = mealsNutritionServed[calories] + sidesNutritionServed[calories] + dessertsNutritionServed[calories] * 2;
constraint totalCalsServed >= weeklyCalsRequired;

%%%%%%%%%%%%%%%%%%%%%% OBJECTIVE %%%%%%%%%%%%%%%%%%%%%%%%%%

% Multiply by 2 because each meal is served twice a day.
var int: totalCost = (mealsCost + sidesCost + dessertsCost) * 2;
var int: totalEmissions = (mealsEmissions + sidesEmissions + dessertsEmissions) * 2;
solve minimize totalCost + totalEmissions; 

output["On \(day), for \(time), \(numServed[day, 1]) servings of \(mealsServed[day, 1]), \(numServed[day, 2]) servings of \(mealsServed[day, 2]) and \(numServed[day, 3]) servings of \(mealsServed[day, 3])\nwill be provided with \(numSidesServed[day, 1]) optional extra servings of \(sidesServed[day, 1]) and \(numDessertsServed[day, 1]) servings of \(dessertsServed[day, 1]) for dessert.\n" | day in weekdays, time in mealtimes];
output["The total cost per week will be \(totalCost)p including purchase, transport, storage and cooking.\n"];
output["The total greenhouse gas emissions associated with this menu is around \(totalEmissions div 100) kg per week."];