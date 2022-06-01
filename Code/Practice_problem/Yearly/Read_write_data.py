import pandas as pd
import numpy as np

# Moderate increase in food required for these people. + 50%
highIntensityJobs = ["scien", "boat", "chef", "tech", "mech", "elec", "plumb", "weld"] 
# Large increase in food required for these people. + 100%
vHighIntensityJobs = ["carpenter", "builder", "joiner", "construction", "field", "dive", "ga", "marine biologist", "erector", "pilot", "air", "traverse", "cladder", "mooring", "hut install"]

# File path of master pax sheet.
paxPath = r"C:\Users\sophi\Antarctic-Food-Optimisation\Data\MasterPAX.xlsx"
sheet = pd.read_excel(paxPath)

posts = np.asarray(sheet.iloc[2:373, 8])
types = np.asarray(sheet.iloc[2:373, 9])
jobsIntensity = np.zeros(len(posts))

for i in range(len(posts)):
    post = posts[i]
    # If it contains a value it will be a string.
    if type(post) == float:
        post = types[i]
    if type(post) == str:
        post = post.lower()
        for job in highIntensityJobs:
            if job in post:
                print(job)
                jobsIntensity[i] = 0.5
        for job in vHighIntensityJobs:
            if job in post:
                print(job)
                jobsIntensity[i] = 1

print(jobsIntensity)