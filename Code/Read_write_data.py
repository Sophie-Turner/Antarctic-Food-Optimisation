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
    newStr = "{} = {};\n\n".format(strName, newStr)
    return newStr


sheet = pd.read_excel(paxPath, na_filter = False)
posts = np.asarray(sheet.iloc[2:373, 8])
types = np.asarray(sheet.iloc[2:373, 9])
startDates = np.asarray(sheet.iloc[2:373, 1])
endDates = np.asarray(sheet.iloc[2:373, 3])
genders = np.asarray(sheet.iloc[2:373, 6])

invalidIndices = findInvalidIndices(startDates)

posts = sanitise(posts, invalidIndices)
types = sanitise(types, invalidIndices)
startDates = sanitise(startDates, invalidIndices)
endDates = sanitise(endDates, invalidIndices)
genders = sanitise(genders, invalidIndices)

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

# Calculate how much extra food will be required per day by job demands.
# Count number of men and women for dietary reasons.
numPhysicalWorkers = np.zeros(numDays) 
numMen = np.zeros(numDays, dtype=np.uint8)
for i in range(numDays):
    for j in range(totalPeople):
        start = numDays - (lastDay - startDates[j]).days
        end = numDays - (lastDay - endDates[j]).days
        if i >= start and i <= end:
            numPhysicalWorkers[i] += jobsIntensity[j]
            if genders[j] != "F":
                numMen[i] += 1

# Generate some random dietary requirements for the group
# because there are no data available for this.
"""
refusalsString = "numRefusals = ["
for i in range(numDays):
    numGuests = numPeople[i]
    refusalsString += "| "
    for j in range(8):
        refusal = np.random.normal(0, numGuests/10, 1)[0]
        refusal = int(round(abs(refusal)))
        if j < 7:
            separator = ","
        else:
            separator = " "
        refusalsString += str(refusal) + separator
refusalsString += "|];\n\n"
"""

refusalsString = "numRefusals = ["
for i in range(numDays):
    numGuests = numPeople[i]
    refusalsString += "| "
    if i==0 or (i>0 and numPeople[i] != numPeople[i-1]):
        refusals = np.random.normal(0, numGuests/10, 8)
        stringSection = ""
        for i in range(8):
            refusal = refusals[i]
            val = int(round(abs(refusal)))
            if i == 7:
                separator = " "
            else:
                separator = ","
            stringSection += str(val) + separator
    refusalsString += stringSection
refusalsString += "|];\n\n"

peopleString = formatString("numPeople", numPeople) 
physicalString = formatString("numPhysicalWorkers", numPhysicalWorkers)
menString = formatString("numMen", numMen)
strToWrite = (peopleString + physicalString + menString + refusalsString)

with open(writeTxtPath, 'w') as txtFile:
    txtFile.write(strToWrite)

