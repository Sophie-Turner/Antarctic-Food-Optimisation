<h1>FAIR data statement</h1>

The project aims to satisfy the [FAIR data principles](https://www.go-fair.org/fair-principles/).

A copy of the personnel schedule data provided by the British Antarctic Survey is included in the program files, at [/Data/MasterPAX.xlsx](https://github.com/Sophie-Turner/Antarctic-Food-Optimisation/blob/main/Data/MasterPAX.xlsx),
but people's names have been removed to protect their identities and comply with [General Data Protection Regulations](https://www.gov.uk/government/publications/guide-to-the-general-data-protection-regulation).
For more information, contact Maria Fox at marfox@bas.ac.uk or Nopi Exizidou at pardou@bas.ac.uk.
Other information sources used for the development of the program are listed in the program files, at [/Documentation/References/References.txt](https://github.com/Sophie-Turner/Antarctic-Food-Optimisation/tree/main/Documentation/References)

[Python](https://www.python.org/downloads/) and [MiniZinc](https://www.minizinc.org/) were used for this project and are both open-source. 
Pandas, numpy and matplotlib were imported into the python code and are also open-source. They can be installed using [Pip](https://pypi.org/project/pip/) by typing into the terminal:<br/>
```pip install pandas```<br/>
```pip install numpy```<br/>
```pip install matplotlib```<br/>
[Gecode](https://www.gecode.org/) was used as the solver in MiniZinc. It is open-source.<br/>
No specialist computing infrastructure is required to run this code other than a typical personal computer with an up-to-date operating system.   

Random dietary requirements were generated for the batches of MiniZinc data. These data files have been included in the [code folder](https://github.com/Sophie-Turner/Antarctic-Food-Optimisation/tree/main/Code) so that the results shown can be exactly reproduced. Running the [batch generation script](https://github.com/Sophie-Turner/Antarctic-Food-Optimisation/blob/main/Code/Batches_read_write.py) will create a new random set of dietary restrictions. 
