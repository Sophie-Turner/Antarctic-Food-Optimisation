import matplotlib.pyplot as plt

savePath = r"C:\Users\sophi\Documents\Personal\Travel\FlightsPlot.png"

seasons = ("Summer", "Autumn", "Winter", "Spring")
destinations = ("Turkey", "USA", "Venezuela", "Caribbean", "Singapore", "Vietnam", "New Guinea")

values = [[215,199,145,187], 
          [663,641,515,547], 
          [1589,1138,747,1539], 
          [800,590,702,621], 
          [1060,1069,590,620], 
          [1138,826,722,827], 
          [3532,1565,1916,1828]]

colours = ("red", "blue", "yellow", "black", "pink", "orange", "green")
 
plotPlaces = [3, 5]
plt.figure(figsize=(10,5))
for i in plotPlaces:
    colour = colours[i]
    series = values[i]        
    plt.plot(seasons, series, colour, marker="o", label=destinations[i])
plt.legend(bbox_to_anchor =(0.75, 0.55))
plt.savefig(savePath)




