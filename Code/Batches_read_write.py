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

# Strings to display as comments in data file.
peopleInfo = "% For this week, how many people will be here.\n"
physicalInfo = "% Physical workers need 50 to 100 % more nutrients per day.\n"
menInfo = "% Males need +25% more nutrients per day.\n"
refusalsInfo = "% Num people who do not eat categories. contains = {none, meat, milk, gluten, egg, nut, seed, sugars}\n"

# Maximum num elements in data arrays that can be used at once in Mzn.
maxMatrixSize = 3000

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
    if newStr[0] == "," or newStr[1] == ",":
        newStr = newStr.replace(",", "", 1)
    # Check for end whitespace too and remove it.
    if newStr[-2] == " ":
        newStr = newStr[:-2] + newStr[-1]
    # Remove series info.
    if "Freq" in newStr:
        newStr = newStr[:newStr.index("Freq")]
    whitespaces = ["   ", "  ", " "]
    afterDots = [",", "\n,", "]"]
    for space in whitespaces:
        newStr = newStr.replace(space, ",")
    for afterDot in afterDots:
        replacee = ".{}".format(afterDot)
        replacer = ".0{}".format(afterDot)
        newStr = newStr.replace(replacee, replacer)
    if newStr[-1] != "]":
        newStr = "[{}]".format(newStr)
    newStr = "{} = {};\n\n".format(strName, newStr)
    return newStr


def findListIndices(rowOrColList, startOrEnd, startIndex=1, endIndex=380):
    # Binary search for indices of row or col. Pass in the whole row or col as a 1d array.
    mid = round((endIndex + startIndex) / 2)
    print(mid)
    midValue = rowOrColList[mid]
    if (type(midValue) == int and startOrEnd == "end") or (type(midValue) != int and startOrEnd == "start"):
        startIndex = mid 
    else:
        endIndex = mid
    if endIndex - startIndex == 1:
        return mid
    return findListIndices(rowOrColList, startOrEnd, startIndex, endIndex) 


sheet = pd.read_excel(paxPath, na_filter = False)

field = sheet.iloc[386, :]
fieldStart, fieldEnd = findListIndices(field, "start"), findListIndices(field, "end")+1
fieldCampers = np.asarray(sheet.iloc[386, fieldStart:fieldEnd])

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
fieldCampers = sanitise(fieldCampers, invalidIndices)

firstDay = min(startDates)
lastDay = max(endDates)
calendar = pd.date_range(start=firstDay, end=lastDay).to_series()
dates = np.asarray(calendar)
months = np.asarray(calendar.dt.month)
daysOfWeek = np.asarray(calendar.dt.dayofweek)
numDays = (lastDay - firstDay).days # 370 days
totalPeople = len(posts) # 368 people

days = [",Monday", ",Tuesday", ",Wednesday", ",Thursday", ",Friday", ",Saturday", ",Sunday"]

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

# matrixSizes = [500, 1000, 1500, 2000, 2500, 3000, 3500]
continueLoop = True
dateIndex, matrixSize, batchNum = 0, 0, 0
while continueLoop:
    batchNum += 1
    matrixSize, batchNumDays = 0, 0
    batchStart = dateIndex
    while matrixSize < maxMatrixSize: 
        dateIndex += 1
        if dateIndex >= numDays:
            batchEnd = numDays
            continueLoop = False
            break
        batchNumDays += 1
        matrixSize += numPeople[dateIndex]      
    batchEnd = dateIndex
    batchFirstDay = min(startDates[batchStart:batchEnd])
    batchLastDay = max(endDates[batchStart:batchEnd])

    # Generate some random dietary requirements for the group
    # because there are no data available for this.
    refusalsString = "numRefusals = ["
    for i in range(batchStart, batchEnd):
        numGuests = numPeople[i]
        refusalsString += "| "
        if i==0 or numPeople[i] != numPeople[i-1]:
            refusals = np.random.normal(0, numGuests/20, 8)
            refusals[0] = 0
            stringSection = ""
            for i in range(8):
                refusal = refusals[i]
                val = int(round(refusal))
                if val < 0:
                    val = 0
                if i == 7:
                    separator = " "
                else:
                    separator = ","
                stringSection += str(val) + separator
        refusalsString += stringSection
    refusalsString += "|];\n\n" 

    datesString = ""
    for i in range(batchStart, batchEnd):
        date = dates[i]
        strSection = "'{}'".format(str(date)[:10])
        datesString += "," + strSection 

    daysString = ""
    batchDaysOfWeek = daysOfWeek[batchStart:batchEnd]
    for day in batchDaysOfWeek:
        daysString += (days[day])

    winter = "false"
    batchMonths = months[batchStart:batchEnd]
    for month in batchMonths:
        if month >= 5 and month <= 9:
            winter = "true"
    winterString = "winter = {};\n\n".format(winter)

    datesString = formatString("dates", datesString)
    datesString = datesString.replace("[", "{")
    datesString = datesString.replace("]", "}")
    daysString = formatString("daysOfWeek", daysString)
    peopleString = formatString("numPeople", numPeople[batchStart:batchEnd]) 
    physicalString = formatString("numPhysicalWorkers", numPhysicalWorkers[batchStart:batchEnd])
    menString = formatString("numMen", numMen[batchStart:batchEnd])
    strToWrite = (datesString + daysString + winterString + peopleInfo + peopleString + physicalInfo + physicalString + menInfo + menString + refusalsInfo + refusalsString)

    writeTxtPath = r"{}\batch{}.dzn".format(currentPath, batchNum)
    with open(writeTxtPath, 'w') as txtFile:
        txtFile.write(strToWrite)

    maxPeople = max(numPeople[batchStart:batchEnd])
    print("batch {} contains {} days and {} people.\n Matrix size is {}."
          .format(batchNum, batchNumDays, maxPeople, matrixSize))

