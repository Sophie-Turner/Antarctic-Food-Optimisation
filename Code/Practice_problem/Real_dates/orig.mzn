%%%%%%%%%%%%%%%%%%%%%%%% DATE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%

enum weekdays = {Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday};
enum mealtimes = {breakfast, lunch, tea}; 
enum dates; % The calendar of dates for this period.
array[dates] of weekdays: daysOfWeek;

%%%%%%%%%%%%%%%%%%%%%%% PERSONNEL INPUTS %%%%%%%%%%%%%%%%%%%%%%%

array[dates] of int: numPeople;
% physical workers need +50 to 100 % more nutrients per day.
array[dates] of float: numPhysicalWorkers;
% males need +25% more nutrients per day.
array[dates] of int: numMen; 
% num people who do not eat categories.
array[dates, contains] of int: numRefusals;

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
array[dates] of var int: minServings;
constraint forall(date in dates)(minServings[date] = numPeople[date] div 6);

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
% The minimum grams of nutrients people require per day.
array[nutrients] of int: minNutrients = [2000, 225, 44, 21, 45];
% It is higer in the winter because of the colder climate.
float: winterMultiplier = 0.25;
int: physicalMultiplier = 1;
float: menMultiplier = 0.25;
% Work out how much nutrition the group needs per day.
array[dates, nutrients] of var float: dailyNutrientsRequired;
constraint forall(date in dates, nutrient in nutrients)
          (dailyNutrientsRequired[date, nutrient] = 
          (minNutrients[nutrient] * numPeople[date]) 
          + (minNutrients[nutrient] * numPhysicalWorkers[date] * physicalMultiplier)
          + (minNutrients[nutrient] * numMen[date] * menMultiplier)); 
 
%%%%%%%%%%%%%%%%%%%%%%%%% MAIN MEALS PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
% All the options on each mealtime should be different, and each row of meals should be different, but the whole array doesn't need to be different.  
%include "alldifferent.mzn"; 

%array[weekdays, 1..numMealsOffered] of var meals: mealsServed; 
array[dates, 1..numMealsOffered] of var meals: mealsServed;
array[dates, 1..numMealsOffered] of var int: numMealsServed;

% A variety of meals must be offered.
%constraint alldifferent(mealsServed);
constraint forall(date in dates, mealNum in numMealsServed)
                 %(mealNum >= minServings[date]);
                  (mealNum >= 0);
        
% The right number of meals must be offered.
constraint forall(date in dates)
                 (sum(optionNum in 1..numMealsOffered)
                     (numMealsServed[date, optionNum]) = numPeople[date]);
                 
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(date in dates, 
                  foodType in contains)
                     (numRefusals[date, foodType] <= 
                      sum(optionNum in 1..numMealsOffered)
                         (forall(itemNum in 1..maxContains)
                                (mealContains[mealsServed[date, optionNum], itemNum] != foodType) 
                                 * numMealsServed[date, optionNum]));            
            
% Make sure there is a vegan option.            
constraint forall(date in dates)
                 (exists(optionNum in 1..numMealsOffered)
                        (forall(itemNum in 1..maxContains)
                               (mealContains[mealsServed[date, optionNum], itemNum] != meat
                               /\ mealContains[mealsServed[date, optionNum], itemNum] != egg
                               /\ mealContains[mealsServed[date, optionNum], itemNum] != milk)));                 
                 
% Work out the nutrition on offer.
% Change this so it makes an array for every date.
%array[nutrients] of var int: mealsNutritionServed;
%constraint forall(nutrient in nutrients)
%           (mealsNutritionServed[nutrient] = 
%            sum(date in dates, optionNum in 1..numMealsOffered, item in 1..maxIngredients)
%            (nutrition[mealIngredients[mealsServed[date, optionNum], item], nutrient]
%             * mealAmounts[mealsServed[date, optionNum], item]
%             * numMealsServed[date, optionNum]));  
             
% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: mealIngredientsOrder;
constraint forall(ingredient in ingredients)
                 (mealIngredientsOrder[ingredient] = 
                  sum(date in dates, optionNum in 1..numMealsOffered, item in 1..maxIngredients)
                     (if mealIngredients[mealsServed[date, optionNum], item] = ingredient
                      then mealAmounts[mealsServed[date, optionNum], item]
                           * numMealsServed[date, optionNum]
                      else 0
                      endif));                                             
                 
var int: mealsCost = sum(date in dates, optionNum in 1..numMealsOffered, ingredientNum in 1..maxIngredients)
                        (sum(costSource in costSources)
                             (costs[mealIngredients[mealsServed[date, optionNum], ingredientNum], costSource])
                          * mealAmounts[mealsServed[date, optionNum], ingredientNum]
                          * numMealsServed[date, optionNum]
                          + mealCookingCosts[mealsServed[date, optionNum]]);  

var int: mealsEmissions = sum(date in dates, optionNum in 1..numMealsOffered, ingredientNum in 1..maxIngredients)
                             (sum(emissionSource in emissionsSources)
                                 (emissions[mealIngredients[mealsServed[date, optionNum], ingredientNum], emissionSource])
                              * mealAmounts[mealsServed[date, optionNum], ingredientNum]
                              * numMealsServed[date, optionNum]);

%%%%%%%%%%%%%%%% SIDES PROCESSING %%%%%%%%%%%%%%%%%%%%%

% Each side is offfered at least once.
array[dates, 1..numSidesOffered] of var sides: sidesServed;
array[dates, 1..numSidesOffered] of var int: numSidesServed;

% The right number of sides must be offered.
constraint forall(date in dates)
                 (forall(optionNum in 1..numSidesOffered)
                        (numSidesServed[date, optionNum] >= 0));

% The sides options on each day must not be the same but options can be repeated throughout the week.
constraint forall(date in dates)
                 (sidesServed[date, 1] != sidesServed[date, 2]);
                 
% Make sure everyone can eat something.
%constraint forall(date in dates, 
%                  foodType in contains)
%                     (numRefusals[date, foodType] <= 
%                      sum(optionNum in 1..numSidesOffered)
%                         (forall(itemNum in 1..maxContains)
%                                (sideContains[sidesServed[date, optionNum], itemNum] != foodType) 
%                                 * numSidesServed[date, optionNum]));                                 
                                                                    
% Work out the nutrition on offer.
% Change this so it makes an array for every date.
%array[nutrients] of var int: sidesNutritionServed;
%constraint forall(nutrient in nutrients)
%           (sidesNutritionServed[nutrient] = 
%            sum(date in dates, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
%            (nutrition[sideIngredients[sidesServed[date, optionNum], ingredientNum], nutrient]
%             * numPeople[date]
%             * sideAmounts[sidesServed[date, optionNum], ingredientNum]));                 
                 
% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: sideIngredientsOrder;
constraint forall(ingredient in ingredients)
                 (sideIngredientsOrder[ingredient] = 
                  sum(date in dates, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
                     (if sideIngredients[sidesServed[date, optionNum], ingredientNum] = ingredient
                      then sideAmounts[sidesServed[date, optionNum], ingredientNum] 
                           * numSidesServed[date, optionNum]
                      else 0
                      endif));                  
                 
var int: sidesCost = sum(date in dates, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
                        (sum(costSource in costSources)
                            (costs[sideIngredients[sidesServed[date, optionNum], ingredientNum], costSource])
                         * numSidesServed[date, optionNum]
                         * sideAmounts[sidesServed[date, optionNum], ingredientNum]
                         + sideCookingCosts[sidesServed[date, optionNum]]);                          
                                  
var int: sidesEmissions = sum(date in dates, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
                             (sum(emissionSource in emissionsSources)
                                 (emissions[sideIngredients[sidesServed[date, optionNum], ingredientNum], emissionSource])
                              * numSidesServed[date, optionNum]
                              * sideAmounts[sidesServed[date, optionNum], ingredientNum]);               

%%%%%%%%%%%%%%%% DESSERTS PROCESSING %%%%%%%%%%%%%%%%%%%%%

array[dates, 1..numDessertsOffered] of var desserts: dessertsServed;
%constraint alldifferent(dessertsServed);
array[dates, 1..numDessertsOffered] of var int: numDessertsServed;

% Don't offer more desserts than people can eat. Desserts are not important so don't bother much with diet types.
constraint forall(date in dates, 
                  optionNum in 1..numDessertsOffered)
                       (numDessertsServed[date, optionNum] = 
                        numPeople[date] - max(itemNum in 1..maxContains)
                           (numRefusals[date, dessertContains[dessertsServed[date, optionNum], itemNum]]));                     

% Work out the nutrition on offer.
% Change this so it makes an array for every date.
%array[nutrients] of var int: dessertsNutritionServed;
%constraint forall(nutrient in nutrients)
%           (dessertsNutritionServed[nutrient] = 
%            sum(date in dates, optionNum in 1..numDessertsOffered, item in 1..maxIngredients)
%            (nutrition[dessertIngredients[dessertsServed[date, optionNum], item], nutrient]
%             * dessertAmounts[dessertsServed[date, optionNum], item]
%             * numDessertsServed[date, optionNum]));

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: dessertIngredientsOrder;
constraint forall(ingredient in ingredients)
                 (dessertIngredientsOrder[ingredient] = 
                  sum(date in dates, optionNum in 1..numDessertsOffered, item in 1..maxIngredients)
                     (if dessertIngredients[dessertsServed[date, optionNum], item] = ingredient
                      then dessertAmounts[dessertsServed[date, optionNum], item]
                           * numDessertsServed[date, optionNum]
                      else 0
                      endif)); 

var int: dessertsCost = sum(date in dates, optionNum in 1..numDessertsOffered, ingredientNum in 1..maxIngredients)
                           (sum(costSource in costSources)
                               (costs[dessertIngredients[dessertsServed[date, optionNum], ingredientNum], costSource])
                            * numDessertsServed[date, optionNum]
                            * dessertAmounts[dessertsServed[date, optionNum], ingredientNum]
                            + dessertCookingCosts[dessertsServed[date, optionNum]]);
                                
var int: dessertsEmissions = sum(date in dates, optionNum in 1..numDessertsOffered, ingredientNum in 1..maxIngredients)
                                (sum(emissionSource in emissionsSources)
                                    (emissions[dessertIngredients[dessertsServed[date, optionNum], ingredientNum], emissionSource])
                                 * numDessertsServed[date, optionNum]
                                 * dessertAmounts[dessertsServed[date, optionNum], ingredientNum]);
                                 
%%%%%%%%%%%%%%%%%%% BREAKFASTS PROCESSING %%%%%%%%%%%%%%%%%%

array[dates, 1..numBreakfastsOffered] of var breakfasts: breakfastsServed;

% The breakfast options on each day must be the same but options can be repeated throughout the week.
constraint forall(date in dates, optionNumI in 2..numBreakfastsOffered)
                 (forall(optionNumJ in 1..optionNumI-1)
                        (breakfastsServed[date, optionNumI] != breakfastsServed[date, optionNumJ]));

% Breakfast is an essential meal so enure that everyone can eat it.
array[dates, 1..numBreakfastsOffered] of var int: numBreakfastsServed;  

% There must be a variety of breakfasts on offer.
constraint forall(date in dates, breakfastNum in numBreakfastsServed)
                 %(breakfastNum >= minServings[date]);
                 (breakfastNum >= 0);                   
                                                         
% The right number of breakfasts must be offered.
constraint forall(date in dates)
                 (sum(optionNum in 1..numBreakfastsOffered)
                     (numBreakfastsServed[date, optionNum]) = numPeople[date]);
                 
% Make sure everyone can eat something and there are enough servings for each diet type.            
%constraint forall(date in dates, 
%                  foodType in contains)
%                     (numRefusals[date, foodType] <= 
%                      sum(optionNum in 1..numBreakfastsOffered)
%                         (forall(itemNum in 1..maxContains)
%                                (breakfastContains[breakfastsServed[date, optionNum], itemNum] != foodType) 
%                                 * numBreakfastsServed[date, optionNum]));

% Work out the nutrition on offer.
% Change this so it makes an array for every date.
%array[nutrients] of var int: breakfastsNutritionServed;
%constraint forall(nutrient in nutrients)
%           (breakfastsNutritionServed[nutrient] = 
%            sum(date in dates, optionNum in 1..numBreakfastsOffered, item in 1..maxIngredients)
%            (nutrition[breakfastIngredients[breakfastsServed[date, optionNum], item], nutrient]
%             * breakfastAmounts[breakfastsServed[date, optionNum], item]
%             * numBreakfastsServed[date, optionNum]));

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: breakfastIngredientsOrder;
constraint forall(ingredient in ingredients)
                 (breakfastIngredientsOrder[ingredient] = 
                  sum(date in dates, optionNum in 1..numBreakfastsOffered, item in 1..maxIngredients)
                     (if breakfastIngredients[breakfastsServed[date, optionNum], item] = ingredient
                      then breakfastAmounts[breakfastsServed[date, optionNum], item]
                           * numBreakfastsServed[date, optionNum]
                      else 0
                      endif)); 

var int: breakfastsCost = sum(date in dates, optionNum in 1..numBreakfastsOffered, ingredientNum in 1..maxIngredients)
                           (sum(costSource in costSources)
                               (costs[breakfastIngredients[breakfastsServed[date, optionNum], ingredientNum], costSource])
                            * numBreakfastsServed[date, optionNum]
                            * breakfastAmounts[breakfastsServed[date, optionNum], ingredientNum]
                            + breakfastCookingCosts[breakfastsServed[date, optionNum]]);
                                
var int: breakfastsEmissions = sum(date in dates, optionNum in 1..numBreakfastsOffered, ingredientNum in 1..maxIngredients)
                                (sum(emissionSource in emissionsSources)
                                    (emissions[breakfastIngredients[breakfastsServed[date, optionNum], ingredientNum], emissionSource])
                                 * numBreakfastsServed[date, optionNum]
                                 * breakfastAmounts[breakfastsServed[date, optionNum], ingredientNum]);

%%%%%%%%%%%%%%%%%%%%%% GENERAL CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%

% Make sure everyone gets enough nutrition.
% Change this so it makes an array for every date.
%array[nutrients] of var int: dailyNutrition;
%constraint forall(nutrient in nutrients)
%                 (dailyNutrition[nutrient]
%                 = (breakfastsNutritionServed[nutrient]
%                 + ((mealsNutritionServed[nutrient] 
%                    + sidesNutritionServed[nutrient] 
%                    + dessertsNutritionServed[nutrient])
%                    * 2)) % Muliply meals by 2 because there are lunch and tea.
%                 div 100); % Per 100g, not per gram.
% Change this so it constrains daily.                                                         
%constraint forall(day in weekdays, nutrient in nutrients)
%                 (weeklyNutrition[nutrient] >= dailyNutrientsRequired[day, nutrient] * 7);

array[ingredients] of var int: order;
constraint forall(ingredient in ingredients)
                 (order[ingredient]  
                  = (breakfastIngredientsOrder[ingredient] 
                  + ((mealIngredientsOrder[ingredient] 
                     + sideIngredientsOrder[ingredient] 
                     + dessertIngredientsOrder[ingredient])
                     *2))); % Muliply meals by 2 because there are lunch and tea.

% A measure of how easy it will be for people to choose enough variety at mealtimes.
% Larger number -> fewer options for the majority of people.
var int: varietyLack = sum(date in dates)
                          (sum(bI in 1..numBreakfastsOffered-1)
                              (abs(numBreakfastsServed[date, bI] - numBreakfastsServed[date, bI+1]))
                           +
                           sum(mI in 1..numMealsOffered-1)
                              (abs(numMealsServed[date, mI] - numMealsServed[date, mI+1])));

%%%%%%%%%%%%%%%%%%%%%% OBJECTIVE %%%%%%%%%%%%%%%%%%%%%%%%%%

% Multiply by 2 because each meal is served twice a day.
var int: totalCost = breakfastsCost + ((mealsCost + sidesCost + dessertsCost) * 2); % divide output by 10000
var int: totalEmissions = breakfastsEmissions + ((mealsEmissions + sidesEmissions + dessertsEmissions) * 2); % divide output by 10000 
% Constrain cals to > minimum, then minimise to avoid food waste.
%solve minimize (varietyLack * 1000000) + weeklyEmissions + weeklyCost + (weeklyNutrition[calories] * 100);
solve satisfy;

%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT INFO %%%%%%%%%%%%%%%%%%%%%%%%%

output["\n\(day):\nbreakfast options: \(breakfastsServed[day, 1]), \(breakfastsServed[day, 2]), \(breakfastsServed[day, 3]), \(breakfastsServed[day, 4]).\nlunch and tea options: \(mealsServed[day, 1]), \(mealsServed[day, 2]), \(mealsServed[day, 3]).\noptional extras: \(sidesServed[day, 1]), \(sidesServed[day, 2]).\ndessert: \(dessertsServed[day, 1]).\n" | day in dates];