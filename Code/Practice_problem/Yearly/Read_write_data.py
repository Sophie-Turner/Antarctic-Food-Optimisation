import pandas as pd
import numpy as np
import os

# Moderate increase in food required for these people. + 50%
highIntensityJobs = ["scien", "boat", "chef", "tech", "mech", "elec", "plumb", "weld"] 
# Large increase in food required for these people. + 100%
vHighIntensityJobs = ["carpenter", "builder", "joiner", "construction", "field", "dive", "ga", "marine biologist", "erector", "pilot", "air", "traverse", "cladder", "mooring", "hut install"]
# File path of master pax sheet.
paxPath = r"C:\Users\sophi\Antarctic-Food-Optimisation\Data\MasterPAX.xlsx"
currentPath = os.getcwd()
writeTxtPath = r"{}\People_data.txt".format(currentPath)


def findInvalidIndices(dates):
    # Detect string dates. They are things like year 20211. 
    invalidIndices = []
    for i in range(len(dates)):
        date = dates[i]
        if type(date) == str:
            invalidIndices.append(i)
    return invalidIndices


def sanitise(dataArray, invalidIndices):
    # Also remove records for this person as it is all TBC.
    i = 0
    for index in invalidIndices:
        dataArray = np.delete(dataArray, index-i)
        i += 1
    return dataArray   


def formatString(strName, dataArray):
    newStr = str(dataArray) 
    # Remove the first whitespace so others can be turned into commas.
    if newStr[1] == " ":
        newStr = newStr.replace(" ", "", 1)
    # Check for end whitespace too and remove it.
    if newStr[-2] == " ":
        newStr = newStr[:-2] + newStr[-1]
    newStr = newStr.replace("  ", ",") 
    newStr = newStr.replace(" ", ",")
    newStr = "{} = {}\n".format(strName, newStr)
    return newStr


sheet = pd.read_excel(paxPath, na_filter = False)
posts = np.asarray(sheet.iloc[2:373, 8])
types = np.asarray(sheet.iloc[2:373, 9])
startDates = np.asarray(sheet.iloc[2:373, 1])
endDates = np.asarray(sheet.iloc[2:373, 3])

invalidIndices = findInvalidIndices(startDates)

posts = sanitise(posts, invalidIndices)
types = sanitise(types, invalidIndices)
startDates = sanitise(startDates, invalidIndices)
endDates = sanitise(endDates, invalidIndices)

totalPeople = len(posts) # 368 people
jobsIntensity = np.zeros(totalPeople)

for i in range(totalPeople):
    post = posts[i]
    # If it contains a value it will be a string.
    if type(post) == float:
        post = types[i]
    if type(post) == str:
        post = post.lower()
        for job in highIntensityJobs:
            if job in post:
                jobsIntensity[i] = 0.5
        for job in vHighIntensityJobs:
            if job in post:
                jobsIntensity[i] = 1

firstDay = min(startDates) 
lastDay = max(endDates)
numDays = (lastDay - firstDay).days # 370 days

# Count how many people will be present on each day.
numPeople = np.zeros(numDays, dtype=np.uint8)
for i in range(totalPeople):
    start = numDays - (lastDay - startDates[i]).days
    end = numDays - (lastDay - endDates[i]).days 
    currentDay = start 
    while currentDay < end:
        numPeople[currentDay] += 1
        currentDay += 1   

# Calculate how much extra food will be required per day.
numPhysicalWorkers = np.zeros(numDays) 
for i in range(numDays):
    for j in range(totalPeople):
        start = numDays - (lastDay - startDates[j]).days
        end = numDays - (lastDay - endDates[j]).days
        if i >= start and i <= end:
            numPhysicalWorkers[i] += jobsIntensity[j] 


peopleString = formatString("numPeople", numPeople) 
physicalString = formatString("numPhysicalWorkers", numPhysicalWorkers)
strToWrite = (peopleString + physicalString)

with open(writeTxtPath, 'w') as txtFile:
    txtFile.write(strToWrite)

