<#
.Synopsis
   Takes file[] as InFilePath, copies the entire file to OutFilePath replacing bytes with the 
   high bit 0x80 set with the Replacement byte [byte][char]'*' by default.
.DESCRIPTION
   Takes a UTF-8 Input file (haven't tried multi-byte character sets YMMV)
   Copies the entire file to the -OutPath folder looking for High bit set Bytes and 
   replacing them with -Replacement (default 42 0x2A [byte][char]'*').  

   It uses .NET Binary Streams to buffer the file into memory for manipulation, search & replace. 
   Tries to be memory efficent using a 4K buffer, PowerShell seems to be CPU limited with my approach here
.EXAMPLE
   Get-ChildItem -Path .\DataDir\Some.csv | Convert-Unicode -OutPath ".\Output\" 
.EXAMPLE
   Get-Content -Path .\ListOfFiles.txt | Convert-Unicode -OutPath ".\Output\" 
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Convert-Unicode () {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [ValidateScript({
                if (-Not ($_ | Test-Path) ) {
                    throw "File or folder does not exist"
                }
                if (-Not ($_ | Test-Path -PathType Leaf) ) {
                    throw "The Path argument must be a file. Folder paths are not allowed."
                }
                if ($_ -notmatch "(\.csv|\.tab)") {
                    throw "The file specified in the path argument must be either of type csv or tab"
                }
                return $true
            })]
        [Parameter(Mandatory, 
                    Position = 0, 
                    ValueFromPipeLine, 
                    ValueFromPipelineByPropertyName, 
                    HelpMessage = "The path to the input file to Convert Unicode")]
        [System.IO.FileInfo]$InFilePath,
        [Parameter(Mandatory, 
                    Position = 1, 
                    HelpMessage = "The path to the output directory the input file will be copied into")]
        [System.IO.DirectoryInfo]$OutPath,
        [Parameter(HelpMessage = "The value to replace any byte in the file with the high bit set 0x80")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0,127)]
        [Byte]$Replacement = [byte][char]'*'
    )
    begin {
    
    }
    Process {
        
        try { 
            $outFilename = $OutPath.FullName + $InFilePath.Name
            $start = Get-Date
            $ChangeCount = 0
    
            $srcFile = [System.IO.File]::Open($_, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
            $bytesToProcess = $srcFile.Length
            $reader = New-Object System.IO.BinaryReader($srcFile)

            $fileStream = New-Object IO.FileStream  $outFilename, 'Create', 'Write', 'ReadWrite'
            $writer = New-Object System.IO.BinaryWriter $fileStream; 
    
            # Range to interrogate the buffer in steps of 8
            $range = 0..4095 | Where-Object { $_ % 8 -eq 0 }
            # buffer for the byte stream 
            $buffer = new-object byte[] 4096 # 4K buffer 512 x 8 Bytes aka 64 bit long

            # load it
            $receivedBytes = $reader.Read( $buffer, 0, 4096 )

            While ($receivedBytes) { 

                foreach ($baseOffset in $range) {

                    # do it 8 bytes at a time checking if any high bits 0x80 are set of each byte in the word
                    $maskResult = [System.BitConverter]::ToInt64($buffer, $baseOffset) -band 0x8080808080808080

                    #-------
                    $n = 0
                    while ($maskResult -and ($n -lt 8)) {
                        if ($maskResult -band 0x80) {
                            # make it an astix
                            $buffer[$baseOffset + $n] = $Replacement 
                            $ChangeCount++
                        }
                        # update the mask
                        $maskResult = $maskResult -shr 8
                        $n++
                    }
                }
                # Output
                $writer.Write($buffer, 0, $receivedBytes)
                $writer.Flush()
                # More input? 
                $receivedBytes = $reader.Read($buffer, 0, 4096)
            } 

            # Tidy up we're done
            @($writer, $srcFile, $reader) | ForEach-Object('Close')
        } 
        catch { 
            Write-Output ($_.Exception.Message) 
        } 
        finally { 
            @($writer, $srcFile, $reader) | ForEach-Object('Dispose')

         
       
    
        }
        ,[PSCustomObject]@{
            InputFile       = [System.IO.FileInfo]$_ 
            OutputFile      = [System.IO.FileInfo]$outFilename
            Bytes           = [Long]$bytesToProcess
            BytesChanged    = [Long]$ChangeCount
            Started         = [System.DateTime]$start
            Completed       = [System.DateTime](Get-Date)
            TotalSeconds    = (New-TimeSpan -Start $start -End (Get-Date)).TotalSeconds
        }
 
    }
    end {
    
    }
}

<#

# Load the module
. .\Convert-Unicode.ps1

# Working Folder
$rootFolder = 'D:\Ross\dev\PowerShell'

# files to process, or you could Get-ChildItem on a Folder ;)
$files = @(
    "$rootFolder\TestData\100000 BT Records.csv",
    "$rootFolder\TestData\1000000 BT Records.csv"
)

# Do the work and keep the results to report on later
$results = $files | Convert-Unicode -OutPath "$rootFolder\Output\" -Replace ([Byte][Char]' ')

# Simplest Answer, Total Duration
$totalDuration = ($results | Measure-Object -Sum TotalSeconds).Sum

# do a lil more math on the results from above
$byteStats = $results | Measure-Object -Sum -Average Bytes, BytesChanged 
$timeStats = $results | Measure-Object -Min -Max Started, Completed 
$durationStats = $results | Measure-Object -Sum -Average TotalSeconds    

$Report = "
=============================================
Report
=============================================
The Converstion began at {0}, 
            completed at {1}., 
            A total of {2:0.00} seconds.

In that time we processed {4} files for a total of {3:0.000} MBytes." -f
            ($timeStats | Where-Object { $_.Property -eq 'Completed' }).Minimum.ToString(),
            ($timeStats | Where-Object { $_.Property -eq 'Completed' }).Maximum.ToString(),
            ($durationStats | Where-Object { $_.Property -eq 'TotalSeconds' }).Sum,
            (($byteStats | Where-Object { $_.Property -eq 'Bytes' }).Sum / 1Mb),
            $results.Count

# Show it
$Results | Select OutputFile, Completed, Bytes, BytesChanged | Format-Table -AutoSize
$Report


#>
