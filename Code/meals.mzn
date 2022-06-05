%%%%%%%%%%%%%%%%%%%%%%%% DATE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%

enum weekdays = {Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday};

% When to start and end the plan.
weekdays: startWeekday; 
int: startDate;
int: startMonth;
int: endDate;
int: endMonth;
set of int: years;
array[1..12] of var int: monthDays = [31, _, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
array[years, 1..12] of var int: allDates;
constraint forall (year in years, month in 1..12)
                  (if month = 2
                   then if year mod 4 = 0
                        then allDates[year, month] = 29
                        else allDates[year, month] = 28
                        endif
                   else allDates[year, month] = monthDays[month]
                   endif);   

enum mealtimes = {breakfast, lunch, tea}; 

%%%%%%%%%%%%%%%%%%%%%%%%%% FIXED INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%

enum ingredients;
% A null ingredient is needed for static 2d array placeholders.
ingredients: notIngredient;

enum contains = {none, meat, milk, gluten, egg, nut, seed, sugars};
contains: nothing;

enum portionTypes;
array[ingredients] of portionTypes: ingredientPortions;

enum costSources = {purchase, transportCost, storageCost};
array[ingredients, costSources] of int: costs;

enum emissionsSources = {production, transportEmission, storageEmission};
array[ingredients, emissionsSources] of int: emissions;

int: maxIngredients;
int: maxContains;

% Minimum num servings of each meal option. 
% Has to be forced to prevent the program from outputting restrictive options.
array[weekdays] of var int: minServings;
constraint forall(day in weekdays)(minServings[day] = numPeople[day] div 6);

%%%%%%%%%%%%%%%% MAIN MEALS INPUTS %%%%%%%%%%%%%%%%%%

enum meals;
array[meals] of int: mealCookingCosts;
array[meals, 1..maxIngredients] of ingredients: mealIngredients;
array[meals, 1..maxContains] of contains: mealContains;
% add amounts of igredient required per meal to calculate cost and how much ingredient required.
array[meals, 1..maxIngredients] of int: mealAmounts;
int: numMealsOffered; % Number of different meal options offered at this meal.

%%%%%%%%%%%%%%%% SIDES INPUTS %%%%%%%%%%%%%%%%%%

enum sides;
array[sides] of int: sideCookingCosts;
array[sides, 1..maxIngredients] of ingredients: sideIngredients;
array[sides, 1..maxContains] of contains: sideContains;
array[sides, 1..maxIngredients] of int: sideAmounts;
int: numSidesOffered; 

%%%%%%%%%%%%%%%% DESSERTS INPUTS %%%%%%%%%%%%%%%%%%

enum desserts;
array[desserts] of int: dessertCookingCosts;
array[desserts, 1..maxIngredients] of ingredients: dessertIngredients;
array[desserts, 1..maxContains] of contains: dessertContains;
array[desserts, 1..maxIngredients] of int: dessertAmounts;
int: numDessertsOffered;

%%%%%%%%%%%%%%%%%%% BREAKFAST INPUTS %%%%%%%%%%%%%%%%%%%%%

enum breakfasts;
array[breakfasts] of int: breakfastCookingCosts;
array[breakfasts, 1..maxIngredients] of ingredients: breakfastIngredients;
array[breakfasts, 1..maxContains] of contains: breakfastContains;
array[breakfasts, 1..maxIngredients] of int: breakfastAmounts;
int: numBreakfastsOffered;

%%%%%%%%%%%%%%%%%%%% NUTRITION INPUTS %%%%%%%%%%%%%%%%%%%%%%

% Assumed that all meals contain enough vitamins and minerals apart from vitamin D which can be lacking in this environment. 
enum nutrients = {calories, carbohydrate, fat, fibre, protein};
% Amount of each nutrient in 100g of ingredient.
array[ingredients, nutrients] of int: nutrition;

array[weekdays] of int: numPeople;
% The minimum grams of nutrients people require per day.
array[nutrients] of int: minNutrients = [2000, 225, 44, 21, 45];
% It is higer in the winter because of the colder climate.
float: winterMultiplier = 0.25;
% physical workers need +100% more nutrients per day.
array[weekdays] of float: numPhysicalWorkers;
int: physicalMultiplier = 1;
% males need +25% more nutrients per day.
array[weekdays] of int: numMen; 
float: menMultiplier = 0.25;
% num people who do not eat categories.
array[weekdays, contains] of int: numRefusals;

% Work out how much nutrition the group needs per day.
array[weekdays, nutrients] of var float: dailyNutrientsRequired;
constraint forall(day in weekdays, nutrient in nutrients)
          (dailyNutrientsRequired[day, nutrient] = 
          (minNutrients[nutrient] * numPeople[day]) 
          + (minNutrients[nutrient] * numPhysicalWorkers[day] * physicalMultiplier)
          + (minNutrients[nutrient] * numMen[day] * menMultiplier)); 
 
%%%%%%%%%%%%%%%%%%%%%%%%% MAIN MEALS PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
% All the options on each mealtime should be different, and each row of meals should be different, but the whole array doesn't need to be different.  
include "alldifferent.mzn"; 
 
array[weekdays, 1..numMealsOffered] of var meals: mealsServed; 
array[weekdays, 1..numMealsOffered] of var int: numMealsServed;

% A variety of meals must be offered.
constraint alldifferent(mealsServed);
constraint forall(day in weekdays, mealNum in numMealsServed)
                 (mealNum >= minServings[day]);

% The right number of meals must be offered.
constraint forall(day in weekdays)
                 (sum(optionNum in 1..numMealsOffered)
                     (numMealsServed[day, optionNum]) = numPeople[day]);
                 
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(day in weekdays, 
                  foodType in contains)
                     (numRefusals[day, foodType] <= 
                      sum(optionNum in 1..numMealsOffered)
                         (forall(itemNum in 1..maxContains)
                                (mealContains[mealsServed[day, optionNum], itemNum] != foodType) 
                                 * numMealsServed[day, optionNum]));            
            
% Make sure there is a vegan option.            
constraint forall(day in weekdays)
                 (exists(optionNum in 1..numMealsOffered)
                        (forall(itemNum in 1..maxContains)
                               (mealContains[mealsServed[day, optionNum], itemNum] != meat
                               /\ mealContains[mealsServed[day, optionNum], itemNum] != egg
                               /\ mealContains[mealsServed[day, optionNum], itemNum] != milk)));                 
                 
% Work out the nutrition on offer.
array[nutrients] of var int: mealsNutritionServed;
constraint forall(nutrient in nutrients)
           (mealsNutritionServed[nutrient] = 
            sum(day in weekdays, optionNum in 1..numMealsOffered, item in 1..maxIngredients)
            (nutrition[mealIngredients[mealsServed[day, optionNum], item], nutrient]
             * mealAmounts[mealsServed[day, optionNum], item]
             * numMealsServed[day, optionNum]));  
             
% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: mealIngredientsOrder;
constraint forall(ingredient in ingredients)
                 (mealIngredientsOrder[ingredient] = 
                  sum(day in weekdays, optionNum in 1..numMealsOffered, item in 1..maxIngredients)
                     (if mealIngredients[mealsServed[day, optionNum], item] = ingredient
                      then mealAmounts[mealsServed[day, optionNum], item]
                           * numMealsServed[day, optionNum]
                      else 0
                      endif));                                             
                 
var int: mealsCost = sum(day in weekdays, optionNum in 1..numMealsOffered, ingredientNum in 1..maxIngredients)
                        (sum(costSource in costSources)
                             (costs[mealIngredients[mealsServed[day, optionNum], ingredientNum], costSource])
                          * mealAmounts[mealsServed[day, optionNum], ingredientNum]
                          * numMealsServed[day, optionNum]
                          + mealCookingCosts[mealsServed[day, optionNum]]);  

var int: mealsEmissions = sum(day in weekdays, optionNum in 1..numMealsOffered, ingredientNum in 1..maxIngredients)
                             (sum(emissionSource in emissionsSources)
                                 (emissions[mealIngredients[mealsServed[day, optionNum], ingredientNum], emissionSource])
                              * mealAmounts[mealsServed[day, optionNum], ingredientNum]
                              * numMealsServed[day, optionNum]);

%%%%%%%%%%%%%%%% SIDES PROCESSING %%%%%%%%%%%%%%%%%%%%%

% Each side is offfered at least once.
array[weekdays, 1..numSidesOffered] of var sides: sidesServed;
array[weekdays, 1..numSidesOffered] of var int: numSidesServed;

% The right number of sides must be offered.
constraint forall(day in weekdays)
                 (forall(optionNum in 1..numSidesOffered)
                        (numSidesServed[day, optionNum] >= 0));

% The sides options on each day must be the same but options can be repeated throughout the week.
constraint forall(day in weekdays)
                 (sidesServed[day, 1] != sidesServed[day, 2]);
                 
% Make sure everyone can eat something.
constraint forall(day in weekdays, 
                  foodType in contains)
                     (numRefusals[day, foodType] <= 
                      sum(optionNum in 1..numSidesOffered)
                         (forall(itemNum in 1..maxContains)
                                (sideContains[sidesServed[day, optionNum], itemNum] != foodType) 
                                 * numSidesServed[day, optionNum]));                                 
                                                                    
% Work out the nutrition on offer.
array[nutrients] of var int: sidesNutritionServed;
constraint forall(nutrient in nutrients)
           (sidesNutritionServed[nutrient] = 
            sum(day in weekdays, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
            (nutrition[sideIngredients[sidesServed[day, optionNum], ingredientNum], nutrient]
             * numPeople[day]
             * sideAmounts[sidesServed[day, optionNum], ingredientNum]));                 
                 
% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: sideIngredientsOrder;
constraint forall(ingredient in ingredients)
                 (sideIngredientsOrder[ingredient] = 
                  sum(day in weekdays, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
                     (if sideIngredients[sidesServed[day, optionNum], ingredientNum] = ingredient
                      then sideAmounts[sidesServed[day, optionNum], ingredientNum] 
                           * numSidesServed[day, optionNum]
                      else 0
                      endif));                  
                 
var int: sidesCost = sum(day in weekdays, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
                        (sum(costSource in costSources)
                            (costs[sideIngredients[sidesServed[day, optionNum], ingredientNum], costSource])
                         * numSidesServed[day, optionNum]
                         * sideAmounts[sidesServed[day, optionNum], ingredientNum]
                         + sideCookingCosts[sidesServed[day, optionNum]]);                          
                                  
var int: sidesEmissions = sum(day in weekdays, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
                             (sum(emissionSource in emissionsSources)
                                 (emissions[sideIngredients[sidesServed[day, optionNum], ingredientNum], emissionSource])
                              * numSidesServed[day, optionNum]
                              * sideAmounts[sidesServed[day, optionNum], ingredientNum]);               

%%%%%%%%%%%%%%%% DESSERTS PROCESSING %%%%%%%%%%%%%%%%%%%%%

array[weekdays, 1..numDessertsOffered] of var desserts: dessertsServed;
constraint alldifferent(dessertsServed);
array[weekdays, 1..numDessertsOffered] of var int: numDessertsServed;

% Don't offer more desserts than people can eat. Desserts are not important so don't bother much with diet types.
constraint forall(day in weekdays, 
                  optionNum in 1..numDessertsOffered)
                       (numDessertsServed[day, optionNum] = 
                        numPeople[day] - max(itemNum in 1..maxContains)
                           (numRefusals[day, dessertContains[dessertsServed[day, optionNum], itemNum]]));                     

% Work out the nutrition on offer.
array[nutrients] of var int: dessertsNutritionServed;
constraint forall(nutrient in nutrients)
           (dessertsNutritionServed[nutrient] = 
            sum(day in weekdays, optionNum in 1..numDessertsOffered, item in 1..maxIngredients)
            (nutrition[dessertIngredients[dessertsServed[day, optionNum], item], nutrient]
             * dessertAmounts[dessertsServed[day, optionNum], item]
             * numDessertsServed[day, optionNum]));

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: dessertIngredientsOrder;
constraint forall(ingredient in ingredients)
                 (dessertIngredientsOrder[ingredient] = 
                  sum(day in weekdays, optionNum in 1..numDessertsOffered, item in 1..maxIngredients)
                     (if dessertIngredients[dessertsServed[day, optionNum], item] = ingredient
                      then dessertAmounts[dessertsServed[day, optionNum], item]
                           * numDessertsServed[day, optionNum]
                      else 0
                      endif)); 

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
                                 
%%%%%%%%%%%%%%%%%%% BREAKFASTS PROCESSING %%%%%%%%%%%%%%%%%%

array[weekdays, 1..numBreakfastsOffered] of var breakfasts: breakfastsServed;

% The breakfast options on each day must be the same but options can be repeated throughout the week.
constraint forall(day in weekdays, optionNumI in 2..numBreakfastsOffered)
                 (forall(optionNumJ in 1..optionNumI-1)
                        (breakfastsServed[day, optionNumI] != breakfastsServed[day, optionNumJ]));

% Breakfast is an essential meal so enure that everyone can eat it.
array[weekdays, 1..numBreakfastsOffered] of var int: numBreakfastsServed;  

% There must be a variety of breakfasts on offer.
constraint forall(day in weekdays, breakfastNum in numBreakfastsServed)
                 (breakfastNum >= minServings[day]);                   
                                                         
% The right number of breakfasts must be offered.
constraint forall(day in weekdays)
                 (sum(optionNum in 1..numBreakfastsOffered)
                     (numBreakfastsServed[day, optionNum]) = numPeople[day]);
                 
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(day in weekdays, 
                  foodType in contains)
                     (numRefusals[day, foodType] <= 
                      sum(optionNum in 1..numBreakfastsOffered)
                         (forall(itemNum in 1..maxContains)
                                (breakfastContains[breakfastsServed[day, optionNum], itemNum] != foodType) 
                                 * numBreakfastsServed[day, optionNum]));

% Work out the nutrition on offer.
array[nutrients] of var int: breakfastsNutritionServed;
constraint forall(nutrient in nutrients)
           (breakfastsNutritionServed[nutrient] = 
            sum(day in weekdays, optionNum in 1..numBreakfastsOffered, item in 1..maxIngredients)
            (nutrition[breakfastIngredients[breakfastsServed[day, optionNum], item], nutrient]
             * breakfastAmounts[breakfastsServed[day, optionNum], item]
             * numBreakfastsServed[day, optionNum]));

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: breakfastIngredientsOrder;
constraint forall(ingredient in ingredients)
                 (breakfastIngredientsOrder[ingredient] = 
                  sum(day in weekdays, optionNum in 1..numBreakfastsOffered, item in 1..maxIngredients)
                     (if breakfastIngredients[breakfastsServed[day, optionNum], item] = ingredient
                      then breakfastAmounts[breakfastsServed[day, optionNum], item]
                           * numBreakfastsServed[day, optionNum]
                      else 0
                      endif)); 

var int: breakfastsCost = sum(day in weekdays, optionNum in 1..numBreakfastsOffered, ingredientNum in 1..maxIngredients)
                           (sum(costSource in costSources)
                               (costs[breakfastIngredients[breakfastsServed[day, optionNum], ingredientNum], costSource])
                            * numBreakfastsServed[day, optionNum]
                            * breakfastAmounts[breakfastsServed[day, optionNum], ingredientNum]
                            + breakfastCookingCosts[breakfastsServed[day, optionNum]]);
                                
var int: breakfastsEmissions = sum(day in weekdays, optionNum in 1..numBreakfastsOffered, ingredientNum in 1..maxIngredients)
                                (sum(emissionSource in emissionsSources)
                                    (emissions[breakfastIngredients[breakfastsServed[day, optionNum], ingredientNum], emissionSource])
                                 * numBreakfastsServed[day, optionNum]
                                 * breakfastAmounts[breakfastsServed[day, optionNum], ingredientNum]);

%%%%%%%%%%%%%%%%%%%%%% GENERAL CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%

% Make sure everyone gets enough nutrition.
array[nutrients] of var int: weeklyNutrition;
constraint forall(nutrient in nutrients)
                 (weeklyNutrition[nutrient]
                 = (breakfastsNutritionServed[nutrient]
                 + ((mealsNutritionServed[nutrient] 
                    + sidesNutritionServed[nutrient] 
                    + dessertsNutritionServed[nutrient])
                    * 2)) % Muliply meals by 2 because there are lunch and tea.
                 div 100); % Per 100g, not per gram.
                                                         
constraint forall(day in weekdays, nutrient in nutrients)
                 (weeklyNutrition[nutrient] >= dailyNutrientsRequired[day, nutrient] * 7);

array[ingredients] of var int: weeklyOrder;
constraint forall(ingredient in ingredients)
                 (weeklyOrder[ingredient]  
                  = (breakfastIngredientsOrder[ingredient] 
                  + ((mealIngredientsOrder[ingredient] 
                     + sideIngredientsOrder[ingredient] 
                     + dessertIngredientsOrder[ingredient])
                     *2))); % Muliply meals by 2 because there are lunch and tea.

% A measure of how easy it will be for people to choose enough variety at mealtimes.
% Larger number -> fewer options for the majority of people.
var int: varietyLack = sum(day in weekdays)
                          (sum(bI in 1..numBreakfastsOffered-1)
                              (abs(numBreakfastsServed[day, bI] - numBreakfastsServed[day, bI+1]))
                           +
                           sum(mI in 1..numMealsOffered-1)
                              (abs(numMealsServed[day, mI] - numMealsServed[day, mI+1])));

%%%%%%%%%%%%%%%%%%%%%% OBJECTIVE %%%%%%%%%%%%%%%%%%%%%%%%%%

% Multiply by 2 because each meal is served twice a day.
var int: weeklyCost = breakfastsCost + ((mealsCost + sidesCost + dessertsCost) * 2); % divide output by 10000
var int: weeklyEmissions = breakfastsEmissions + ((mealsEmissions + sidesEmissions + dessertsEmissions) * 2); % divide output by 10000 
% Constrain cals to > minimum, then minimise to avoid food waste.
%solve minimize (varietyLack * 1000000) + weeklyEmissions + weeklyCost + (weeklyNutrition[calories] * 100);
solve satisfy;

%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT INFO %%%%%%%%%%%%%%%%%%%%%%%%%

output["On \(day), for breakfast, \(numBreakfastsServed[day, 1]) servings of \(breakfastsServed[day, 1]), \(numBreakfastsServed[day, 2]) servings of \(breakfastsServed[day, 2]), \(numBreakfastsServed[day, 3]) servings of \(breakfastsServed[day, 3])\nand \(numBreakfastsServed[day, 4]) servings of \(breakfastsServed[day, 4]) will be provided.\nOn \(day), for both lunch and tea, \(numMealsServed[day, 1]) servings of \(mealsServed[day, 1]), \(numMealsServed[day, 2]) servings of \(mealsServed[day, 2]) and \(numMealsServed[day, 3]) servings of \(mealsServed[day, 3])\nwill be provided with \(numSidesServed[day, 1]) optional extra servings of \(sidesServed[day, 1]), \(numSidesServed[day, 2]) optional extra servings of \(sidesServed[day, 2]) and \(numDessertsServed[day, 1]) servings of \(dessertsServed[day, 1]) for dessert.\n" | day in weekdays];
output["The total cost per week will be £\(weeklyCost div 10000) including purchase, transport, storage and cooking.\n"];
output["The total greenhouse gas emissions associated with this menu is around \(weeklyEmissions div 10000) kg per week.\n"];
%output["The weekly order will be:\n"];
%output["\(weeklyOrder[i]) \(ingredientPortions[i]) of \(i)\n" | i in ingredients];

% Check raw objective values.
%output["weeklyEmissions: \(weeklyEmissions)\nweeklyCost: \(weeklyCost)\nweekly calories: \(weeklyNutrition[calories])\nweekly fat: \%(weeklyNutrition[fat])"];
% Check solution values for tests.
%output["\(weeklyCost div 10000)\n\(weeklyEmissions div 10000)\n\(weeklyNutrition[calories] - (dailyNutrientsRequired[calories] * 7))\n\(weeklyNutrition[carbohydrate] - (dailyNutrientsRequired[carbohydrate] * 7))\n\(weeklyNutrition[fat] - (dailyNutrientsRequired[fat] * 7))\n\(weeklyNutrition[fibre] - (dailyNutrientsRequired[fibre] * 7))\n\(weeklyNutrition[protein] - (dailyNutrientsRequired[protein] * 7))\n"];

output["\(weeklyNutrition[calories])\n"];
output["\(weeklyCost)\n"];
output["\(weeklyEmissions)\n"];
output["\(varietyLack)\n"];
output["\(0.0000000000001 * weeklyNutrition[calories] * weeklyCost * weeklyEmissions * varietyLack)\n"];
output["\(weeklyNutrition[calories] + weeklyCost + weeklyEmissions + varietyLack)\n"];

output["\(allDates)\n"];