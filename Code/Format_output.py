import pandas as pd

labels = [
'date',
'day',

'num people on base',

'breakfast option 1 and num servings offered',
'breakfast option 2 and num servings offered',
'breakfast option 3 and num servings offered',

'lunch main meal option 1 and num servings offered',
'lunch main meal option 2 and num servings offered',
'lunch main meal option 3 and num servings offered',

'lunch side option 1 and num servings offered',
'lunch side option 2 and num servings offered',

'lunch dessert option and num servings offered',

'tea main meal option 1 and num servings offered',
'tea main meal option 2 and num servings offered',
'tea main meal option 3 and num servings offered',

'tea side option 1 and num servings offered',
'tea side option 2 and num servings offered',

'tea dessert option and num servings offered',

'treat and num servings offered',
'treat drink and num servings offered',

'total calories required for group / cal',
'average calories required per person / cal',
'total calories served / cal',
'excess calories / cal',

'total carbohydrate required for group / g',
'average carbohydrate required per person / g',
'total carbohydrate served / g',
'excess carbohydrate / g',

'total fat required for group / g',
'average fat required per person / g',
'total fat served / g',
'excess fat / g',

'total fibre required for group / g',
'average fibre required per person / g',
'total fibre served / g',
'excess fibre / g',

'total protein required for group / g',
'average protein required per person / g',
'total protein served / g',
'excess protein / g',
]

numLabels = len(labels)

with open('Output.txt') as txtFile:
    contentLines = txtFile.readlines()
txtFile.close()

for lineI in range(len(contentLines)):
    line = contentLines[lineI]
    line = line.replace('\n', '')
    if (lineI - 2) % numLabels == 0:
        numPeople = int(line)
    elif line == '?':
        line = float(contentLines[lineI-1]) / numPeople
    elif line[0] == '0':
        line = 'none'
    contentLines[lineI] = line

menuDf = pd.DataFrame()

for i in range(numLabels):
    label = labels[i]
    menuDf[labels[i]] = contentLines[i::numLabels]

menuDf.to_excel('Ouptut_menu.xlsx')





