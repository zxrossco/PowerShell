# PowerShell
Ross's PowerShell Scripts (Version 5+) Dealing with Data Files and Databases

I work with Data Processing pipelines and in this day and age we still deal with a lot of CSV files.  Enterprise restrictions limit the tools available and PowerShell still allows us to get stuff done.

It's also a place to exercise some PS skills, the feedback could be brutal ;)

## Function

First Cab of the rank is Convert-Unicode:
Convert-Unicode -InPath <<path to your csvs UTF-8>> -Output <<where you want them>> -Replacement [[byte]]
Returns: [[PSCustomObject]] with the details of where it put the output, time and number of changes

e.g. 

PS >> Get-ChildItem -Path .\DataDir\Some.csv | Convert-Unicode -OutPath ".\Output\" | format-list

You can do a Folder

PS >> Get-ChildItem -Path .\DataDir\\*.csv | Convert-Unicode -OutPath ".\Output\" | format-list

