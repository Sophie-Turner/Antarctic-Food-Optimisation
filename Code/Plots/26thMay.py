import matplotlib.pyplot as plt

savePath = r"C:\Users\sophi\Antarctic-Food-Optimisation\Documentation\Benchmark_26th_May.png"

minutes = (0, 1, 2, 5, 10)
measures = ("cost", "emissions", "extra cals")

# Minimise emissions
emi_cost = (1279, 1250,	1250, 1250,	1250)
emi_emi =  (1129, 1082,	1082, 1082, 1082)
emi_cals = (16347/10, 14197/10, 14197/10, 14197/10, 14197/10)

# Minimise emissions + cost + extra cals * 10 + extra fat * 100
emiCostCals_cost = (1279, 1279, 1279, 1279, 1279)
emiCostCals_emi = (1129, 1129, 1129, 1129, 1129)
emiCostCals_cals = (16347/10, 16347/10, 16347/10, 16347/10, 16347/10)

emi = (emi_cost, emi_emi, emi_cals)
emiCostCals = (emiCostCals_cost, emiCostCals_emi, emiCostCals_cals)

allObjs = (emi, emiCostCals) 

colours = ("r-", "b-", "g-", "y-")
shapes = ("o", "^", "P")
objNames = ("emissions", "emissions + cost + cals + fat")
 
plt.figure(figsize=(10,5))
for i in range(2):
    colour = colours[i]
    obj = allObjs[i]
    for j in range(3):        
        plt.plot(minutes, obj[j], colours[i], marker=shapes[j], label="{}, {}".format(objNames[i], measures[j]))
plt.legend(bbox_to_anchor =(0.75, 0.55))
plt.savefig(savePath)



