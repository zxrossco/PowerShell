function Replace-Unicode () {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
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
            [Parameter(Mandatory,Position=0,ValueFromPipeLine,ValueFromPipelineByPropertyName,HelpMessage="The path to the input files to Replace Unicode")]
        [System.IO.FileInfo]$InPath,
        [System.IO.DirectoryInfo]$OutPath,
        [Byte]$Replacement = '*'
    )
    begin {
    
    }
    Process {
#        try { 

            #[byte]$asciiMask = 0x80

  
            $ChangeCount = 0
    
            $srcFile = [System.IO.File]::Open($_, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
            $reader = New-Object System.IO.BinaryReader($srcFile)
            $outFilename = $OutPath.FullName + $InPath.Name
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
        # } 
        # catch { 
        #     Write-Output ($_.Exception.Message) 
        # } 
        # finally { 
            @($writer, $srcFile, $reader) | ForEach-Object('Dispose')

         
       
    
        # }
 
    }
    end {
        return [PSCustomObject]@{
            InputFile = [System.IO.FileInfo]$_ 
            OutputFile = [System.IO.FileInfo]$outFilename
            ChangeCount = $ChangeCount
        }
    }
}


# Measure-Command { 
# Get-ChildItem -Path '.\TestData\*.csv' | Replace-Unicode -OutPath ".\Output\" 

# }
#Get-ChildItem -Path .\TestData\US_Accidents_Dec21_updated.csv | Replace-Unicode -OutPath ".\Output\" -Replacement 0x2e | format-list 