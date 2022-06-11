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
constraint forall(date in dates)(minServings[date] = numPeople[date] div 4);

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

array[dates, 1..numBreakfastsOffered] of var breakfasts: breakfastsServed;

% The breakfast options on each day must not be the same but options can be repeated throughout the week.
constraint forall(date in dates, optionNumI in 2..numBreakfastsOffered)
                 (forall(optionNumJ in 1..optionNumI-1)
                        (breakfastsServed[date, optionNumI] != breakfastsServed[date, optionNumJ]));

% Breakfast is an essential meal so enure that everyone can eat it.
array[dates, 1..numBreakfastsOffered] of var int: numBreakfastsServed;

% There must be a variety of breakfasts on offer.
constraint forall(date in dates, optionNum in 1..numBreakfastsOffered)
                 (numBreakfastsServed[date, optionNum] >= minServings[date]);
                 
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
                                (breakfastContains[breakfastsServed[date, optionNum], itemNum] != foodType) 
                                 * numBreakfastsServed[date, optionNum]));   
                                 
% Work out the nutrition on offer.
array[dates, nutrients] of var int: breakfastsNutrition;
constraint forall(date in dates, nutrient in nutrients)
           (breakfastsNutrition[date, nutrient] = 
            sum(optionNum in 1..numBreakfastsOffered, item in 1..maxIngredients)
            (nutrition[breakfastIngredients[breakfastsServed[date, optionNum], item], nutrient]
             * breakfastAmounts[breakfastsServed[date, optionNum], item]
             * numBreakfastsServed[date, optionNum]));

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: breakfastsOrder;
constraint forall(ingredient in ingredients)
                 (breakfastsOrder[ingredient] = 
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

%%%%%%%%%%%%%%%%%%%%%%%%% MAIN MEALS PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
array[dates, 1..numMealsOffered] of var meals: mealsServed;
array[dates, 1..numMealsOffered] of var int: numMealsServed;

% A variety of meals must be offered.
% All the meal options at each meal time must be different.
constraint forall(date in dates, optionNumI in 1..numMealsOffered-1, optionNumJ in optionNumI+1..numMealsOffered)
                 (mealsServed[date, optionNumI] != mealsServed[date, optionNumJ]);
% Don't serve the same dessert again for a week after it's served.
constraint forall(dateNumI in 1..numDays-1, optionNumI in 1..numMealsOffered)
                 (forall(dateNumJ in dateNumI+1..numDays, optionNumJ in 1..numMealsOffered
                         where dateNumJ <= dateNumI + 7)
                        (mealsServed[dates[dateNumI], optionNumI] != mealsServed[dates[dateNumJ], optionNumJ]));

constraint forall(date in dates, optionNum in 1..numMealsOffered)
                 (numMealsServed[date, optionNum] >= minServings[date]);
                 
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
array[dates, nutrients] of var int: mealsNutrition;
constraint forall(date in dates, nutrient in nutrients)
           (mealsNutrition[date, nutrient] = 
            sum(optionNum in 1..numMealsOffered, item in 1..maxIngredients)
            (nutrition[mealIngredients[mealsServed[date, optionNum], item], nutrient]
             * mealAmounts[mealsServed[date, optionNum], item]
             * numMealsServed[date, optionNum]));     
             
% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: mealsOrder;
constraint forall(ingredient in ingredients)
                 (mealsOrder[ingredient] = 
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
constraint forall(date in dates, 
                  foodType in contains)
                     (numRefusals[date, foodType] <= 
                      sum(optionNum in 1..numSidesOffered)
                         (forall(itemNum in 1..maxContains)
                                (sideContains[sidesServed[date, optionNum], itemNum] != foodType) 
                                 * numSidesServed[date, optionNum])); 
                                 
% Work out the nutrition on offer.
array[dates, nutrients] of var int: sidesNutrition;
constraint forall(date in dates, nutrient in nutrients)
           (sidesNutrition[date, nutrient] = 
            sum(optionNum in 1..numSidesOffered, ingredientNum in 1..maxIngredients)
            (nutrition[sideIngredients[sidesServed[date, optionNum], ingredientNum], nutrient]
             * numPeople[date]
             * sideAmounts[sidesServed[date, optionNum], ingredientNum]));  
             
% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: sidesOrder;
constraint forall(ingredient in ingredients)
                 (sidesOrder[ingredient] = 
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
array[dates, 1..numDessertsOffered] of var int: numDessertsServed;

% Don't serve the same dessert again for a week after it's served.
constraint forall(dateNumI in 1..numDays-1, optionNumI in 1..numDessertsOffered)
                 (forall(dateNumJ in dateNumI+1..numDays, optionNumJ in 1..numDessertsOffered
                         where dateNumJ <= dateNumI + 7)
                        (dessertsServed[dates[dateNumI], optionNumI] != dessertsServed[dates[dateNumJ], optionNumJ]));

% Don't offer more desserts than people can eat. Desserts are not important so don't bother much with diet types.
constraint forall(date in dates, 
                  optionNum in 1..numDessertsOffered)
                       (numDessertsServed[date, optionNum] = 
                        numPeople[date] - max(itemNum in 1..maxContains)
                           (numRefusals[date, dessertContains[dessertsServed[date, optionNum], itemNum]]));  
                           
% Work out the nutrition on offer.
array[dates, nutrients] of var int: dessertsNutrition;
constraint forall(date in dates, nutrient in nutrients)
           (dessertsNutrition[date, nutrient] = 
            sum(optionNum in 1..numDessertsOffered, item in 1..maxIngredients)
            (nutrition[dessertIngredients[dessertsServed[date, optionNum], item], nutrient]
             * dessertAmounts[dessertsServed[date, optionNum], item]
             * numDessertsServed[date, optionNum]));

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: dessertsOrder;
constraint forall(ingredient in ingredients)
                 (dessertsOrder[ingredient] = 
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

%%%%%%%%%%%%%%%%%%% OCCASIONAL TREATS %%%%%%%%%%%%%%%%%%%%%%
                                                                                                                                                                                                                                               array[dates] of var desserts: treatFoodsServed;
array[dates] of var int: numTreatFoodsServed;
array[dates] of var treatDrinks: treatDrinksServed;
array[dates] of var int: numTreatDrinksServed;

% Don't serve the same treats twice in a row.
constraint forall(dateNum in 1..numDays - treatFrequency)
                 (treatFoodsServed[dates[dateNum]] 
                  != treatFoodsServed[dates[dateNum + treatFrequency]]
                  /\
                  treatDrinksServed[dates[dateNum]] 
                  != treatDrinksServed[dates[dateNum + treatFrequency]]);  

% The right number of treats should be offered.
constraint forall(date in dates)
                 (numTreatFoodsServed[date] 
                  = numPeople[date] 
                  - max(itemNum in 1..maxContains)
                       (numRefusals[date, dessertContains[treatFoodsServed[date], itemNum]])); 
constraint forall(date in dates)
                 (numTreatDrinksServed[date] = numPeople[date]);

% Occasional treats do not contribute to daily nutrition.

% Build up a shopping list of what needs to be ordered.             
array[ingredients] of var int: treatsOrder;
constraint forall(ingredient in ingredients)
                 (treatsOrder[ingredient] = 
                  sum(dateNum in 1..numDays, item in 1..maxIngredients
                      where dateNum mod treatFrequency = 0)
                     (if dessertIngredients[treatFoodsServed[dates[dateNum]], item] = ingredient
                      then dessertAmounts[treatFoodsServed[dates[dateNum]], item]
                           * numTreatFoodsServed[dates[dateNum]]
                      else 0
                      endif)
                  +
                  sum(dateNum in 1..numDays
                      where dateNum mod treatFrequency = 0)
                     (if treatIngredients[treatDrinksServed[dates[dateNum]]] = ingredient
                      then treatAmounts[treatDrinksServed[dates[dateNum]]] 
                           * numTreatDrinksServed[dates[dateNum]]
                      else 0
                      endif));

var int: treatsCost = sum(dateNum in 1..numDays, ingredientNum in 1..maxIngredients
                          where dateNum mod treatFrequency = 0)
                         (sum(costSource in costSources)
                             (costs[dessertIngredients[treatFoodsServed[dates[dateNum]], ingredientNum], costSource])
                            * numTreatFoodsServed[dates[dateNum]]
                            * dessertAmounts[treatFoodsServed[dates[dateNum]], ingredientNum]
                            + dessertCookingCosts[treatFoodsServed[dates[dateNum]]])
                      +
                      sum(dateNum in 1..numDays
                          where dateNum mod treatFrequency = 0)
                         (sum(costSource in costSources)
                             (costs[treatIngredients[treatDrinksServed[dates[dateNum]]], costSource])
                            * numTreatDrinksServed[dates[dateNum]]
                            * treatAmounts[treatDrinksServed[dates[dateNum]]]);
                                
var int: treatsEmissions = sum(dateNum in 1..numDays, ingredientNum in 1..maxIngredients
                               where dateNum mod treatFrequency = 0)
                              (sum(emissionSource in emissionsSources)
                                  (emissions[dessertIngredients[treatFoodsServed[dates[dateNum]], ingredientNum], emissionSource])
                                 * numTreatFoodsServed[dates[dateNum]]
                                 * dessertAmounts[treatFoodsServed[dates[dateNum]], ingredientNum])
                           +
                           sum(dateNum in 1..numDays
                               where dateNum mod treatFrequency = 0)
                              (sum(emissionSource in emissionsSources)
                                  (emissions[treatIngredients[treatDrinksServed[dates[dateNum]]], emissionSource])
                                 * numTreatDrinksServed[dates[dateNum]]
                                 * treatAmounts[treatDrinksServed[dates[dateNum]]]);
                                                                                                                                                                                                                                                                                                         
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
                  + treatsOrder[ingredient]
                  + dessertsOrder[ingredient]
                  + ((mealsOrder[ingredient] 
                     + sidesOrder[ingredient])
                     *2))); % Muliply meals by 2 because there are lunch and tea.

%%%%%%%%%%%%%%%%%%%%%% OBJECTIVE %%%%%%%%%%%%%%%%%%%%%%%%%%

% Multiply by 2 because each meal is served twice a day.
var int: totalCost = breakfastsCost + dessertsCost + treatsCost + ((mealsCost + sidesCost) * 2); % divide output by 10000 to get £.
var int: totalEmissions = breakfastsEmissions + dessertsEmissions + treatsEmissions + ((mealsEmissions + sidesEmissions) * 2); % divide output by 10000 to get kg.
var int: totalCalsServed = sum(date in dates, nutrient in nutrients 
                         where nutrient = calories)
                        (dailyNutrition[date, nutrient]); 
var float: totalCalsRequired = sum(date in dates, nutrient in nutrients 
                         where nutrient = calories)
                        (dailyNutrientsRequired[date, nutrient]);

% Constrain cals to > minimum, then minimise to avoid food waste.
solve minimize totalEmissions + totalCost + totalCalsServed;

%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT INFO %%%%%%%%%%%%%%%%%%%%%%%%%

% Menu.
output["\(date)\n\(daysOfWeek[date])\n\n\(numPeople[date])\n\n\(numBreakfastsServed[date, 1]) \(breakfastsServed[date, 1])\n\(numBreakfastsServed[date, 2]) \(breakfastsServed[date, 2])\n\(numBreakfastsServed[date, 3]) \(breakfastsServed[date, 3])\n\(numBreakfastsServed[date, 4]) \(breakfastsServed[date, 4])\n\n\(numMealsServed[date, 1]) \(mealsServed[date, 1])\n\(numMealsServed[date, 2]) \(mealsServed[date, 2])\n\(numMealsServed[date, 3]) \(mealsServed[date, 3])\n\n\(numSidesServed[date, 1]) \(sidesServed[date, 1])\n\(numSidesServed[date, 2]) \(sidesServed[date, 2])\n\n\(numMealsServed[date, 1]) \(mealsServed[date, 1])\n\(numMealsServed[date, 2]) \(mealsServed[date, 2])\n\(numMealsServed[date, 3]) \(mealsServed[date, 3])\n\n\(numSidesServed[date, 1]) \(sidesServed[date, 1])\n\(numSidesServed[date, 2]) \(sidesServed[date, 2])\n\n\(numDessertsServed[date, 1]) \(dessertsServed[date, 1])\n\n\(numTreatFoodsServed[date]) \(treatFoodsServed[date])\n\(numTreatDrinksServed[date]) \(treatDrinksServed[date])\n\n\(dailyNutrientsRequired[date, calories])\n\n\(dailyNutrition[date, calories])\n\n\n\(dailyNutrientsRequired[date, carbohydrate])\n\n\(dailyNutrition[date, carbohydrate])\n\n\n\(dailyNutrientsRequired[date, fat])\n\n\(dailyNutrition[date, fat])\n\n\n\(dailyNutrientsRequired[date, fibre])\n\n\(dailyNutrition[date, fibre])\n\n\n\(dailyNutrientsRequired[date, protein])\n\n\(dailyNutrition[date, protein])\n\n\n" | date in dates];

% Shopping list.
output["\(numDays)\n\(totalCost div 10000)\n\(totalEmissions div 10000)\n\(totalCalsServed - totalCalsRequired)\n\n"];
%output["\(ingredient)\n" | ingredient in ingredients];
%output["\n"];
%output["\(order[ingredient])\n" | ingredient in ingredients];
%output["\n"];
%output["\(ingredientPortions[ingredient])\n" | ingredient in ingredients];