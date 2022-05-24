import matplotlib.pyplot as plt

savePath = r"C:\Users\sophi\Antarctic-Food-Optimisation\Documentation\Benchmark_plot.png"

minutes = (0, 1, 2, 5, 10)
measures = ("cost", "emissions", "extra cals")

baseline = ((249220), (1870), (347864))

# Minimise emissions
emi_cost = (249220, 225440,	225110,	225110,	221120)
emi_emi =  (1870*100, 1742*100, 1740*100, 1740*100, 1735*100)
emi_cals = (347864, 323144,	316594,	316594,	323614)

# Minimise emissions + cost
emiCost_cost = (249220, 223300,	223300,	223300,	223300)
emiCost_emi = (1870*100, 1787*100,	1787*100,	1787*100,	1787*100)
emiCost_cals = (347864, 322414, 322414,	322414,	322414)

# Minimise emissions + cost + extra cals
emiCostCals_cost = (249220, 229480,	229480,	229680,	226760)
emiCostCals_emi = (1870*100, 1803*100,	1803*100,	1786*100,	1794*100)
emiCostCals_cals = (347864, 316784,	316784,	315494,	310814)

# Minimise emissions * 100 + extra cals

emiCals_cost = (249220, 232530,	232530,	235470,	235470)
emiCals_emi = (1870*100, 1765*100,	1765*100,	1761*100,	1761*100)
emiCals_cals = (347864, 325264,	325264,	322434,	322434)

emi = (emi_cost, emi_emi, emi_cals)
emiCost = (emiCost_cost, emiCost_emi, emiCost_cals)
emiCostCals = (emiCostCals_cost, emiCostCals_emi, emiCostCals_cals)
emiCals = (emiCals_cost, emiCals_emi, emiCals_cals)

allObjs = (emi, emiCost, emiCostCals, emiCals) 

colours = ("r-", "b-", "g-", "y-")
shapes = ("o", "^", "P")
objNames = ("emissions", "emissions + cost", "emissions + cost + cals", "emissions + cals")
 
plt.figure(figsize=(10,5))
plt.axis([0, 15, 170000, 350000])
for i in range(4):
    colour = colours[i]
    obj = allObjs[i]
    for j in range(3):        
        plt.plot(minutes, obj[j], colours[i], marker=shapes[j], label="{}, {}".format(objNames[i], measures[j]))
plt.legend(bbox_to_anchor =(0.75, 0.55))
plt.savefig(savePath)



