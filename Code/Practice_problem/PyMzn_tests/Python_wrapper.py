#import pymzn
#import os

#current_path = os.getcwd()
#model_path = r'{}\Meals.mzn'.format(current_path)
#data_path = r'{}\Meals_data.dzn'.format(current_path)
#solution = pymzn.minizinc(model_path, data_path)
#print(solution)

import numpy as np

# Simple and lazy but a bit hacky:

# If you don't mind having equal intervals between numbers.
ordered = np.linspace(0, 73, 8000, endpoint=True)
shuffled = np.random.permutation(ordered).reshape(20, 400)

# Or you could increase the variety of intervals between numbers.
ordered = np.linspace(0, 73, 16000, endpoint=True)
shuffled = np.random.permutation(ordered)
shuffled = shuffled[0:8000].reshape(20, 400)

print(ordered)
print(ordered.shape)
print(shuffled)
print(shuffled.shape)