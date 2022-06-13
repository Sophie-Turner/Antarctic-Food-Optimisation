%%%%%%%%%%%%%%%%%%%%%%%% DATE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%

enum weekdays = {Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday};
enum mealtimes = {breakfast, lunch, tea}; 
enum dates; % The calendar of dates for this period.
int: numDays = length(dates);
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
constraint forall(date in dates)(minServings[date] = numPeople[date] div 5);

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

%%%%%%%%%%%%%%%%%%% TREAT INPUTS %%%%%%%%%%%%%%%%%%%%

enum treatDrinks;
array[treatDrinks] of ingredients: treatIngredients;
array[treatDrinks] of int: treatAmounts;
int: treatFrequency; % Number of days between serving treats. 

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
% Work out how much nutrition the group needs per day.
array[dates, nutrients] of var float: dailyNutrientsRequired;
constraint forall(date in dates, nutrient in nutrients)
          (dailyNutrientsRequired[date, nutrient] = 
          (minNutrients[nutrient] * numPeople[date]) 
          + (minNutrients[nutrient] * numPhysicalWorkers[date] * physicalMultiplier)
          + (minNutrients[nutrient] * numMen[date] * menMultiplier)); 

%%%%%%%%%%%%%%%%%%% BREAKFASTS PROCESSING %%%%%%%%%%%%%%%%%%

array[weekdays, 1..numBreakfastsOffered] of var breakfasts: breakfastsServed;

% The breakfast options on each day must not be the same but options can be repeated throughout the week.
constraint forall(day in weekdays, optionNumI in 2..numBreakfastsOffered)
                 (forall(optionNumJ in 1..optionNumI-1)
                        (breakfastsServed[day, optionNumI] != breakfastsServed[day, optionNumJ]));

% Breakfast is an essential meal so enure that everyone can eat it.
array[dates, 1..numBreakfastsOffered] of var int: numBreakfastsServed;

% There must be a variety of breakfasts on offer.
constraint forall(date in dates, optionNum in 2..numBreakfastsOffered)
                 (numBreakfastsServed[date, optionNum] >= 0);                             
                 
% The right number of breakfasts must be offered.
constraint forall(date in dates)
                 (sum(optionNum in 1..numBreakfastsOffered)
                     (numBreakfastsServed[date, optionNum]) = numPeople[date]);
                     
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(date in dates, 
                  foodType in contains)
                     (numRefusals[date, foodType] <= 
                      sum(optionNum in 1..numBreakfastsOffered)
                         (forall(itemNum in 1..maxContains)
                                (breakfastContains[breakfastsServed[daysOfWeek[date], optionNum], itemNum] != foodType) 
                                 * numBreakfastsServed[date, optionNum]));   
                                 
% Work out the nutrition on offer.
array[dates, nutrients] of var int: breakfastsNutrition;
constraint forall(date in dates, nutrient in nutrients)
           (breakfastsNutrition[date, nutrient] = 
            sum(optionNum in 1..numBreakfastsOffered, item in 1..maxIngredients)
            (nutrition[breakfastIngredients[breakfastsServed[daysOfWeek[date], optionNum], item], nutrient]
             * breakfastAmounts[breakfastsServed[daysOfWeek[date], optionNum], item]
             * numBreakfastsServed[date, optionNum]));

% Build up a shopping list of what needs to be ordered.         
array[ingredients] of var int: breakfastsOrder;
constraint forall(ingredient in ingredients)
                 (breakfastsOrder[ingredient] = 
                  sum(date in dates, optionNum in 1..numBreakfastsOffered, item in 1..maxIngredients
                      where breakfastIngredients[breakfastsServed[daysOfWeek[date], optionNum], item] = ingredient)
                      (breakfastAmounts[breakfastsServed[daysOfWeek[date], optionNum], item]
                           * numBreakfastsServed[date, optionNum])); 

var int: breakfastsCost = sum(date in dates, optionNum in 1..numBreakfastsOffered, ingredientNum in 1..maxIngredients)
                           (sum(costSource in costSources)
                               (costs[breakfastIngredients[breakfastsServed[daysOfWeek[date], optionNum], ingredientNum], costSource])
                            * numBreakfastsServed[date, optionNum]
                            * breakfastAmounts[breakfastsServed[daysOfWeek[date], optionNum], ingredientNum]
                            + breakfastCookingCosts[breakfastsServed[daysOfWeek[date], optionNum]]);
                                
var int: breakfastsEmissions = sum(date in dates, optionNum in 1..numBreakfastsOffered, ingredientNum in 1..maxIngredients)
                                (sum(emissionSource in emissionsSources)
                                    (emissions[breakfastIngredients[breakfastsServed[daysOfWeek[date], optionNum], 
                                     ingredientNum], emissionSource])
                                 * numBreakfastsServed[date, optionNum]
                                 * breakfastAmounts[breakfastsServed[daysOfWeek[date], optionNum], ingredientNum]);                                                                                                                                         

%%%%%%%%%%%%%%%%%%%%%%%%% MAIN MEALS PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
array[weekdays, 1..numMealsOffered] of var meals: mealsServed;
array[dates, 1..numMealsOffered] of var int: numMealsServed;

% A variety of meals must be offered.
% All the meal options at each meal time must be different.
include "alldifferent.mzn";
constraint alldifferent(mealsServed);
                 
% The right number of meals must be offered.
constraint forall(date in dates, optionNum in 1..numMealsOffered)
                 (numMealsServed[date, optionNum] >= minServings[date]);
constraint forall(date in dates)
                 (sum(optionNum in 1..numMealsOffered)
                     (numMealsServed[date, optionNum]) = numPeople[date]);                 
         
% Make sure everyone can eat something and there are enough servings for each diet type.            
constraint forall(date in dates, 
                  foodType in contains)
                     (numRefusals[date, foodType] <= 
                      sum(optionNum in 1..numMealsOffered)
                         (forall(itemNum in 1..maxContains)
                                (mealContains[mealsServed[daysOfWeek[date], optionNum], itemNum] != foodType) 
                                 * numMealsServed[date, optionNum]));
                                                                                 
% Work out the nutrition on offer.
array[dates, nutrients] of var int: mealsNutrition;
constraint forall(date in dates, nutrient in nutrients)
           (mealsNutrition[date, nutrient] = 
            sum(optionNum in 1..numMealsOffered, item in 1..maxIngredients)
            (nutrition[mealIngredients[mealsServed[daysOfWeek[date], optionNum], item], nutrient]
             * mealAmounts[mealsServed[daysOfWeek[date], optionNum], item]
             * numMealsServed[date, optionNum]));     
             
% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: mealsOrder;
constraint forall(ingredient in ingredients)
                 (mealsOrder[ingredient] = 
                  sum(date in dates, optionNum in 1..numMealsOffered, item in 1..maxIngredients
                      where mealIngredients[mealsServed[daysOfWeek[date], optionNum], item] = ingredient)
                      (mealAmounts[mealsServed[daysOfWeek[date], optionNum], item]
                       * numMealsServed[date, optionNum])); 
                      
var int: mealsCost = sum(date in dates, optionNum in 1..numMealsOffered, ingredientNum in 1..maxIngredients)
                        (sum(costSource in costSources)
                             (costs[mealIngredients[mealsServed[daysOfWeek[date], optionNum], ingredientNum], costSource])
                          * mealAmounts[mealsServed[daysOfWeek[date], optionNum], ingredientNum]
                          * numMealsServed[date, optionNum]
                          + mealCookingCosts[mealsServed[daysOfWeek[date], optionNum]]);                                                                                                                                                       
                          
var int: mealsEmissions = sum(date in dates, optionNum in 1..numMealsOffered, ingredientNum in 1..maxIngredients)
                             (sum(emissionSource in emissionsSources)
                                 (emissions[mealIngredients[mealsServed[daysOfWeek[date], optionNum], ingredientNum], emissionSource])
                              * mealAmounts[mealsServed[daysOfWeek[date], optionNum], ingredientNum]
                              * numMealsServed[date, optionNum]);                          

%%%%%%%%%%%%%%%% SIDES PROCESSING %%%%%%%%%%%%%%%%%%%%%

array[weekdays, 1..numSidesOffered] of var sides: sidesServed;
array[dates, 1..numSidesOffered] of var int: numSidesServed;

% The right number of sides must be offered.
constraint forall(date in dates)
                 (forall(optionNum in 1..numSidesOffered)
                        (numSidesServed[date, optionNum] >= 0
                        /\ numSidesServed[date, optionNum] <= numPeople[date]));
                        
% The sides options on each day must not be the same but options can be repeated throughout the week.
constraint forall(day in 1..6)
                 (sidesServed[weekdays[day], 1] != sidesServed[weekdays[day], 2]
                 /\ sidesServed[weekdays[day], 1] != sidesServed[weekdays[day+1], 1]
                 /\ sidesServed[weekdays[day], 1] != sidesServed[weekdays[day+1], 2]); 
constraint sidesServed[Sunday, 1] != sidesServed[Sunday, 2]; % Longer but faster code.
                                  
% Make sure everyone can eat something.
constraint forall(date in dates, 
                  foodType in contains)
                     (numRefusals[date, foodType] <= 
                      sum(optionNum in 1..numSidesOffered)
                         (forall(itemNum in 1..maxContains)
                                (sideContains[sidesServed[daysOfWeek[date], optionNum], itemNum] != foodType) 
                                 * numSidesServed[date, optionNum])); 
                                 
% Work out the nutrition on offer.
array[dates, nutrients] of var int: sidesNutrition;
constraint forall(date in dates, nutrient in nutrients)
           (sidesNutrition[date, nutrient] = 
            sum(optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
            (nutrition[sideIngredients[sidesServed[daysOfWeek[date], optionNum], ingredientNum], nutrient]
             * numSidesServed[date, optionNum]
             * sideAmounts[sidesServed[daysOfWeek[date], optionNum], ingredientNum]));  
             
% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: sidesOrder;
constraint forall(ingredient in ingredients)
                 (sidesOrder[ingredient] = 
                  sum(date in dates, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients
                      where sideIngredients[sidesServed[daysOfWeek[date], optionNum], ingredientNum] = ingredient)
                      (sideAmounts[sidesServed[daysOfWeek[date], optionNum], ingredientNum] 
                       * numSidesServed[date, optionNum]));                                                                                                                                     
                      
var int: sidesCost = sum(date in dates, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
                        (sum(costSource in costSources)
                            (costs[sideIngredients[sidesServed[daysOfWeek[date], optionNum], ingredientNum], costSource])
                         * numSidesServed[date, optionNum]
                         * sideAmounts[sidesServed[daysOfWeek[date], optionNum], ingredientNum]
                         + sideCookingCosts[sidesServed[daysOfWeek[date], optionNum]]);                          
                                  
var int: sidesEmissions = sum(date in dates, optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
                             (sum(emissionSource in emissionsSources)
                                 (emissions[sideIngredients[sidesServed[daysOfWeek[date], optionNum], ingredientNum], emissionSource])
                              * numSidesServed[date, optionNum]
                              * sideAmounts[sidesServed[daysOfWeek[date], optionNum], ingredientNum]);                       

%%%%%%%%%%%%%%%% DESSERTS PROCESSING %%%%%%%%%%%%%%%%%%%%%

array[weekdays, 1..numDessertsOffered] of var desserts: dessertsServed;
array[dates, 1..numDessertsOffered] of var int: numDessertsServed;

% Don't serve the null dessert.
constraint forall(dessert in dessertsServed)
                 (dessert != desserts[1]); 

% Don't serve the same dessert again for a week after it's served.
constraint alldifferent(dessertsServed);                 
                  
% Don't offer more desserts than people can eat. Desserts are not important so don't bother much with diet types.
constraint forall(date in dates, 
                  optionNum in 1..numDessertsOffered)
                       (numDessertsServed[date, optionNum] = 
                        numPeople[date] - max(itemNum in 1..maxContains)
                           (numRefusals[date, dessertContains[dessertsServed[daysOfWeek[date], optionNum], itemNum]]));                              
                          
% Work out the nutrition on offer.
array[dates, nutrients] of var int: dessertsNutrition;
constraint forall(date in dates, nutrient in nutrients)
           (dessertsNutrition[date, nutrient] = 
            sum(optionNum in 1..numDessertsOffered, item in 1..maxIngredients)
            (nutrition[dessertIngredients[dessertsServed[daysOfWeek[date], optionNum], item], nutrient]
             * dessertAmounts[dessertsServed[daysOfWeek[date], optionNum], item]
             * numDessertsServed[date, optionNum]));

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: dessertsOrder;
constraint forall(ingredient in ingredients)
                 (dessertsOrder[ingredient] = 
                  sum(date in dates, optionNum in 1..numDessertsOffered, item in 1..maxIngredients
                      where dessertIngredients[dessertsServed[daysOfWeek[date], optionNum], item] = ingredient)
                      (dessertAmounts[dessertsServed[daysOfWeek[date], optionNum], item]
                       * numDessertsServed[date, optionNum])); 

var int: dessertsCost = sum(date in dates, optionNum in 1..numDessertsOffered, ingredientNum in 1..maxIngredients)
                           (sum(costSource in costSources)
                               (costs[dessertIngredients[dessertsServed[daysOfWeek[date], optionNum], ingredientNum], costSource])
                            * numDessertsServed[date, optionNum]
                            * dessertAmounts[dessertsServed[daysOfWeek[date], optionNum], ingredientNum]
                            + dessertCookingCosts[dessertsServed[daysOfWeek[date], optionNum]]);
                                
var int: dessertsEmissions = sum(date in dates, optionNum in 1..numDessertsOffered, ingredientNum in 1..maxIngredients)
                                (sum(emissionSource in emissionsSources)
                                    (emissions[dessertIngredients[dessertsServed[daysOfWeek[date], optionNum], ingredientNum], emissionSource])
                                 * numDessertsServed[date, optionNum]
                                 * dessertAmounts[dessertsServed[daysOfWeek[date], optionNum], ingredientNum]);                           

%%%%%%%%%%%%%%%%%%% OCCASIONAL TREATS %%%%%%%%%%%%%%%%%%%%%%
                                                                                                                                                                                                                                               
int: numTreats = numDays div treatFrequency;                                                                                                                                                                                                                                               array[1..numTreats] of var desserts: treatFoodsServed;
array[1..numTreats] of var int: numTreatFoodsServed;
array[1..numTreats] of var treatDrinks: treatDrinksServed;

% Don't serve the same treats twice in a row.
constraint if numTreats > 1
           then
            forall(treatNum in 1..numTreats-1)
                 (treatFoodsServed[treatNum] != treatFoodsServed[treatNum+1]
                  /\
                  treatDrinksServed[treatNum] != treatDrinksServed[treatNum+1])
           endif;

% The right number of treats should be offered.
constraint forall(treatNum in 1..numTreats)
                 (numTreatFoodsServed[treatNum] 
                  = numPeople[dates[numTreats*treatFrequency]] 
                  - max(itemNum in 1..maxContains)
                       (numRefusals[dates[numTreats*treatFrequency], dessertContains[treatFoodsServed[treatNum], itemNum]])); 

% Occasional treats do not contribute to daily nutrition.

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: treatFoodsOrder;
constraint forall(ingredient in ingredients)
                 (treatFoodsOrder[ingredient] = 
                  sum(treatNum in 1..numTreats, item in 1..maxIngredients
                      where dessertIngredients[treatFoodsServed[treatNum], item] = ingredient)
                      (dessertAmounts[treatFoodsServed[treatNum], item]
                       * numTreatFoodsServed[treatNum]));
array[ingredients] of var int: treatDrinksOrder;
constraint forall(ingredient in ingredients)
                 (treatDrinksOrder[ingredient] = 
                  sum(treatNum in 1..numTreats
                      where treatIngredients[treatDrinksServed[treatNum]] = ingredient)
                      (treatAmounts[treatDrinksServed[treatNum]] 
                       * numPeople[dates[treatNum * treatFrequency]]));

var int: treatFoodsCost = sum(treatNum in 1..numTreats, ingredientNum in 1..maxIngredients)
                         (sum(costSource in costSources)
                             (costs[dessertIngredients[treatFoodsServed[treatNum], ingredientNum], costSource])
                            * numTreatFoodsServed[treatNum]
                            * dessertAmounts[treatFoodsServed[treatNum], ingredientNum]
                            + dessertCookingCosts[treatFoodsServed[treatNum]]);                     
var int: treatDrinksCost = sum(treatNum in 1..numTreats)
                         (sum(costSource in costSources)
                             (costs[treatIngredients[treatDrinksServed[treatNum]], costSource])
                            * numPeople[dates[treatNum * treatFrequency]]
                            * treatAmounts[treatDrinksServed[treatNum]]);
                                
var int: treatFoodsEmissions = sum(treatNum in 1..numTreats, ingredientNum in 1..maxIngredients)
                              (sum(emissionSource in emissionsSources)
                                  (emissions[dessertIngredients[treatFoodsServed[treatNum], ingredientNum], emissionSource])
                                 * numTreatFoodsServed[treatNum]
                                 * dessertAmounts[treatFoodsServed[treatNum], ingredientNum]);
var int: treatDrinksEmissions = sum(treatNum in 1..numTreats)
                               (sum(emissionSource in emissionsSources)
                                   (emissions[treatIngredients[treatDrinksServed[treatNum]], emissionSource])
                                   * numPeople[dates[treatNum * treatFrequency]]
                                   * treatAmounts[treatDrinksServed[treatNum]]);
                                                                                                                                                                                                                                                                                                         
%%%%%%%%%%%%%%%%%%%% MEASUREMENTS %%%%%%%%%%%%%%%%%%%%%%%

% Make sure everyone gets enough nutrition.
array[dates, nutrients] of var int: dailyNutrition;
constraint forall(date in dates, nutrient in nutrients)
                 (dailyNutrition[date, nutrient]
                 = (breakfastsNutrition[date, nutrient]
                 + ((mealsNutrition[date, nutrient] 
                    + sidesNutrition[date, nutrient]
                    + dessertsNutrition[date, nutrient])
                    * 2)) % Muliply meals by 2 because there are lunch and tea.
                 div 100); % Per 100g, not per gram.
                                                   
constraint forall(date in dates, nutrient in nutrients)
                 (dailyNutrition[date, nutrient] >= dailyNutrientsRequired[date, nutrient]);

array[ingredients] of var int: order;
constraint forall(ingredient in ingredients)
                 (order[ingredient]  
                  = (breakfastsOrder[ingredient] 
                  + treatFoodsOrder[ingredient]
                  + treatDrinksOrder[ingredient]
                  + ((mealsOrder[ingredient] 
                     + sidesOrder[ingredient]
                     + dessertsOrder[ingredient])
                     *2))); % Muliply meals by 2 because there are lunch and tea.

%%%%%%%%%%%%%%%%%%%%%% OBJECTIVE %%%%%%%%%%%%%%%%%%%%%%%%%%

% Multiply by 2 because each meal is served twice a day.
var int: totalCost = breakfastsCost + treatFoodsCost + treatDrinksCost + ((mealsCost + sidesCost + dessertsCost) * 2); % divide output by 10000 to get £.
var int: totalEmissions = breakfastsEmissions + treatFoodsEmissions + treatDrinksEmissions + ((mealsEmissions + sidesEmissions + dessertsEmissions) * 2); % divide output by 10000 to get kg.
var int: totalCalsServed = sum(date in dates)
                        (dailyNutrition[date, calories]); 
var float: totalCalsRequired = sum(date in dates)
                        (dailyNutrientsRequired[date, calories]);

% Constrain cals to > minimum, then minimise to avoid food waste.
solve minimize sum(dailyNutrition) + totalCost + totalEmissions;

%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT INFO %%%%%%%%%%%%%%%%%%%%%%%%%

var int: zero = 0;

% Menu.
output["\(dates[dateNum])\n\(daysOfWeek[dates[dateNum]])\n\n\(numPeople[dates[dateNum]])\n\n\(numBreakfastsServed[dates[dateNum], 1]) \(breakfastsServed[daysOfWeek[dates[dateNum]], 1])\n\(numBreakfastsServed[dates[dateNum], 2]) \(breakfastsServed[daysOfWeek[dates[dateNum]], 2])\n\(numBreakfastsServed[dates[dateNum], 3]) \(breakfastsServed[daysOfWeek[dates[dateNum]], 3])\n\(numBreakfastsServed[dates[dateNum], 4]) \(breakfastsServed[daysOfWeek[dates[dateNum]], 4])\n\n\(numMealsServed[dates[dateNum], 1]) \(mealsServed[daysOfWeek[dates[dateNum]], 1])\n\(numMealsServed[dates[dateNum], 2]) \(mealsServed[daysOfWeek[dates[dateNum]], 2])\n\(numMealsServed[dates[dateNum], 3]) \(mealsServed[daysOfWeek[dates[dateNum]], 3])\n\n\(numSidesServed[dates[dateNum], 1]) \(sidesServed[daysOfWeek[dates[dateNum]], 1])\n\(numSidesServed[dates[dateNum], 2]) \(sidesServed[daysOfWeek[dates[dateNum]], 2])\n\n\(numDessertsServed[dates[dateNum], 1]) \(dessertsServed[daysOfWeek[dates[dateNum]], 1])\n\n\(numMealsServed[dates[dateNum], 1]) \(mealsServed[daysOfWeek[dates[dateNum]], 1])\n\(numMealsServed[dates[dateNum], 2]) \(mealsServed[daysOfWeek[dates[dateNum]], 2])\n\(numMealsServed[dates[dateNum], 3]) \(mealsServed[daysOfWeek[dates[dateNum]], 3])\n\n\(numSidesServed[dates[dateNum], 1]) \(sidesServed[daysOfWeek[dates[dateNum]], 1])\n\(numSidesServed[dates[dateNum], 2]) \(sidesServed[daysOfWeek[dates[dateNum]], 2])\n\n\(numDessertsServed[dates[dateNum], 1]) \(dessertsServed[daysOfWeek[dates[dateNum]], 1])\n\n\(if dateNum mod treatFrequency = 0 then numTreatFoodsServed[dateNum div treatFrequency] else zero endif) \(if dateNum < treatFrequency then treatFoodsServed[1] else treatFoodsServed[dateNum div treatFrequency] endif)\n\(if dateNum mod treatFrequency = 0 then numPeople[dates[dateNum]] else zero endif) \(if dateNum < treatFrequency then treatDrinksServed[1] else treatDrinksServed[dates[dateNum div treatFrequency]] endif)\n\n\(dailyNutrientsRequired[dates[dateNum], calories])\n\n\(dailyNutrition[dates[dateNum], calories])\n\(dailyNutrition[dates[dateNum], calories] - dailyNutrientsRequired[dates[dateNum], calories])\n\n\(dailyNutrientsRequired[dates[dateNum], carbohydrate])\n\n\(dailyNutrition[dates[dateNum], carbohydrate])\n\(dailyNutrition[dates[dateNum], carbohydrate] - dailyNutrientsRequired[dates[dateNum], carbohydrate])\n\n\(dailyNutrientsRequired[dates[dateNum], fat])\n\n\(dailyNutrition[dates[dateNum], fat])\n\(dailyNutrition[dates[dateNum], fat] - dailyNutrientsRequired[dates[dateNum], fat])\n\n\(dailyNutrientsRequired[dates[dateNum], fibre])\n\n\(dailyNutrition[dates[dateNum], fibre])\n\(dailyNutrition[dates[dateNum], fibre] - dailyNutrientsRequired[dates[dateNum], fibre])\n\n\(dailyNutrientsRequired[dates[dateNum], protein])\n\n\(dailyNutrition[dates[dateNum], protein])\n\(dailyNutrition[dates[dateNum], protein] - dailyNutrientsRequired[dates[dateNum], protein])\n\n" | dateNum in 1..numDays]; 

% Shopping list.
%output["\(numDays)\n\(totalCost div 10000)\n\(totalEmissions div 10000)\n\(totalCalsServed - totalCalsRequired)\n\n"];
%output["\(ingredient)\n" | ingredient in ingredients];
%output["\n"];
output["\(order[ingredient])\n" | ingredient in ingredients];
%output["\n"];
%output["\(ingredientPortions[ingredient])\n" | ingredient in ingredients];

output["\n\n\n\(numDays)\n\(totalCost div 10000)\n\(totalEmissions div 10000)\n\(totalCalsServed - totalCalsRequired)\n\n"];

% Make a weekly menu and after the first week just vary numServings, not recipes.