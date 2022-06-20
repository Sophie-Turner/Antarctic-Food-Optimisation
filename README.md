[<img align="right" src=Images/BAS_logo_colour.jpg width=350px>](https://bas.ac.uk/ai)
[<img align="left" src=Images/Cambridge_university.svg width=300px>](https://ai4er-cdt.esc.cam.ac.uk/)
<br/><br/><br/>

# Antarctic-Food-Optimisation

<h1>Optimising remote field station food supplies for the British Antarctic Survey</h1>

Optimising logistics operations has a crucial impact on the overall carbon emissions entailed when 
planning a science campaign in Antarctica. One important problem is the planning of the food 
supply to feed a science team based at one of the remote Antarctic field stations over a season. 
The objective is to minimise waste, financial cost and the carbon 
emissions associated with the foods. This is done in the context of 
a variety of constraints. The daily menu meets nutritional requirements, is satisfying 
and enjoyable and satisfies individual dietary restrictions. These requirements are expressed as constraints with an objective 
to be optimised.  

The aim of this project is to construct a constraint program to solve this problem. The program 
scales to instances of about 160 people over 20 days, or 25 people over 4 months, and batches of data can be combined to allow planning for longer periods of time. The example provided in the program files is for 370 days of a real Rothera schedule. The food purchasing strategy is chosen according to availability of fresh foods brought by air.

<h2>File structure</h2>

Antarctic-Food-Optimisation
├── Code
│   ├── Plots
│   │   └── <i>Plots generated from benchmark tests</i> .py
│   ├── Test
│   │   ├── Test_data.dzn 
│   │   ├── MiniZinc schedule datafile 
│   │   └── without dietary restrictions
│   ├── Batches generated from data .dzn
│   ├── Batches_read_write.py
│   ├── Script to generate .dzn batches 
│   ├── from .xlsx schedule data
│   ├── Food_data_no_ruminents.dzn
│   ├── Beef and lamb swapped out for 
│   ├── pork, mycoprotein and chicken
│   ├── Food_data.dzn
│   ├── MiniZinc datafile for food
│   ├── Format_output.py
│   ├── Script to generate .xlsx menu
│   ├── from plain text output
│   ├── Meals.mzn
│   ├── MiniZinc model to run on datafiles
│   ├── Output.txt
│   └── Plain text output menu
├── Data
│   ├── 2017_electricity_usage.xls
│   ├── BAS data
│   ├── Emissions.xlsx
│   ├── Table of emissions from 
│   ├── food production
│   ├── Jobs_physical_intensity.txt
│   ├── List of BAS job roles requiring
│   ├── extra nutrition
│   ├── MasterPAX.csv
│   ├── MasterPAX.xlsx
│   ├── Original schedule data
│   ├── Results_charts.xlsx
│   ├── Table of emissions from
│   └── Edmund's report
├── Documentation
│   ├── Meetings
│   │   └── Project Meeting minutes .docx
│   ├── References
│   │   ├── Edmund_report.docx
│   │   ├── Edmund's previous work on 
│   │   ├── this topic
│   │   ├── References.txt
│   │   ├── All sources of information
│   │   ├── used for this project
│   │   └── Other information sources .pdf
│   ├── Calculations_assumptions.txt
│   └── Fuel and transport calculations
├── Images
│   └── Logos and plots
├── Output
│   ├── Test
│   │   ├── Benchmarks.xlsx
│   │   ├── Results of tests throughout 
│   │   ├── the project
│   │   ├── Month_menu.xlsx
│   │   ├── Output_menu_test.xlsx
│   │   ├── Output_order_test.xlsx
│   │   └── Outputs from earlier tests
│   ├── Output_menu.xlsx
│   ├── Output_order.xlsx
│   └── Final result from program
├── LICENSE
└── README.md




