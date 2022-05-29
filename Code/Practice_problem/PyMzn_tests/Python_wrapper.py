import pymzn
import os

current_path = os.getcwd()
model_path = r'{}\Meals.mzn'.format(current_path)
data_path = r'{}\Meals_data.dzn'.format(current_path)
solution = pymzn.minizinc(model_path, data_path)
print(solution)