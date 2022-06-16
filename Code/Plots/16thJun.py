import matplotlib.pyplot as plt

savePath = r"C:\Users\sophi\Antarctic-Food-Optimisation\Images\Benchmark2_16th_Jun.png"

matrixSizes = (104,	204, 511,	1037,	1568,	2149,	2657,	3075,	3505)
xLabel = ("Matrix size")
measures = ("Cost GBP per person per day", "Emissions kg per person per day", "Extra nutrients per person per day scaled to relative numbers")

costs = (8.1826,	8.92647, 9.03522,	8.72131,	8.9974,	8.8371,	8.86563,	9.07154,	8.94950)
emissions = (8.3173,	8.06862, 8.71621,	8.32594,	7.78826,	8.27454,	8.07263,	8.39154,	8.25506)
extraFood = (5.6393,	3.8981, 3.56275,	3.87193,	3.93642,	3.55360,	4.15860,	3.37923,	4.25204)

allY = (costs, emissions, extraFood) 

colours = ("r", "b", "g")
shape = "o"
 
plt.figure(figsize=(10,5))
for i in range(3):
    colour = colours[i]
    y = allY[i]        
    plt.plot(matrixSizes, y, colour, marker=shape, label=measures[i])
plt.legend(bbox_to_anchor =(0.75, 0.55))
plt.savefig(savePath)



