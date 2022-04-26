% Use this editor as a MiniZinc scratch book
enum ingredients = {rice, beans, tomatoes, peppers, cheese, beef, mushrooms, paprika, wine, basil, bread, eggs};

enum meals = {chilli, risotto, shakshuka, soup, omelette};

array[meals, ingredients] of bool: mealIngredients = [|
  true, true, true, false, false, true, false, true, true, false,       
   false, false
  |true, false, true, false, true, false, true, false, true, true,
   false, false
  |false, false, true, true, true, false, false, true, false, true,
   false, true
  |false, false, true, false, false, false, true, false, false, true,
   true, false
  |false, false, true, true, false, false, true, false, false, false,
   false, true   
  |]; 
  
enum people = {Sophie, HandsomeScientist, ToughHandyman, SturdyPilot, ManlyCook};

% Sophie is vegetarian and allergic to milk.
% HandsomeScientist is vegan.
% ToughHandyman doesn't like spicy food.
% SturdyPilot is teetotal and allergic to gluten.
% ManlyCook eats everything.     
array [people, ingredients] of bool: eats = [|
  true, true, true, true, false, false, true, true, true, true, true, 
  true
  |true, true, true, true, false, false, true, true, true, true,
   true, false
  |true, true, true, false, true, true, true, false, true, true,
   true, true
  |true, true, true, true, true, true, true, true, false, true,
   false, true
  |true, true, true, true, true, true, true, true, true, true,
   true, true|];



  