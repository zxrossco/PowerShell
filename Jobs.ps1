
$initScript = {
    . 'D:\Ross\dev\PowerShell\Convert-Unicode.ps1'
    . 'D:\Ross\Dev\PowerShell\ODBC.ps1' 
}
$csvJob = {
    Param ($TableName)
 
    . 'D:\Ross\Dev\PowerShell\ODBC.ps1'
    
    Get-ODBCDataTable -DSN "DSN=PSTesting" -SQL "SELECT TOP 100000 * FROM [$TableName.csv]" | 
    Format-CSVRow > "D:\Ross\Dev\PowerShell\Output\Sample of $TableName.csv"
} 

$csvJob = {
    Param ($TableName)
 
    . 'D:\Ross\Dev\PowerShell\ODBC.ps1'
    
    @('100000 BT Records') |   Get-ODBCDataTable -DSN "DSN=PSTesting" -SQL "SELECT TOP 100000 * FROM [$_.csv]" | 
    Format-CSVRow > "D:\Ross\Dev\PowerShell\Output\Sample of $_.csv"
} 

@('100000 BT Records', '1000000 BT Records', '5000000 BT Records', 'US_Accidents_Dec21_updated') | 
ForEach-Object { Start-Job -ScriptBlock $csvJob -ArgumentList $_ -Name $TableName }

Get-Job

@('100000 BT Records', '1000000 BT Records', '5000000 BT Records', 'US_Accidents_Dec21_updated') | 
ForEach-Object { 
    Start-Job  -ScriptBlock { 
        Get-ODBCDataTable -DSN "DSN=PSTesting" -SQL "SELECT TOP 100000 * FROM [$($args[0]).csv]" | 
        Format-CSVRow > "D:\Ross\Dev\PowerShell\Output\Sample of $($args[0]).csv" 
    } 
    -InitializationScript { 
        . 'D:\Ross\Dev\PowerShell\ODBC.ps1' 
    } 
    -Name $_ 
    -ArgumentList $_
}

get-job | Select-Object id | receive-job

#---------------------------------------------------
$UniJob = { 
    Param ([parameter(Position=0)]$FileName)
    Start-Sleep 3 # wait
    Get-ChildItem -Path $FileName | Convert-Unicode -OutPath D:\Ross\dev\PowerShell\Output\ -Replace 0x2a
}

Get-ChildItem -Path .\TestData\*.csv | 
ForEach-Object {
    Start-Job  -ScriptBlock $UniJob -InitializationScript $initScript -Name $_ -ArgumentList $_
} 

#---------------------------------------
$initScript = {
    . 'D:\Ross\dev\PowerShell\Convert-Unicode.ps1'
}

$BigJob = { 
    Param ([parameter(Position=0)]$FileName)
    Start-Sleep 3 # wait
    Get-ChildItem -Path $FileName | Convert-Unicode -OutPath D:\Ross\dev\PowerShell\Output\Big\ -Replace 0x2a
}

Get-ChildItem -Path .\Output\*.csv | 
ForEach-Object {
    Start-Job  -ScriptBlock $BigJob -InitializationScript $initScript -Name $_ -ArgumentList $_
} 

   