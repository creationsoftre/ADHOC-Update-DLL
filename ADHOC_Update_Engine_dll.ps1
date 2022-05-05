<###############################
Title: Update ClaimsXten Engine.dll
Author: TW
Original: 2022_04_12
Last Updated: 2022_04_12
	

Overview:
- Deploys new ClaimsXten Engine.dll for additional logging
- Vendor created DLL to provide more information around Invalid Transaction ID
###############################>

#Copy new dll function
function Copy-New-DLL{
    param (
        $dir,
        $server
    )

    $stagedFile = "PATH\Engine.dll"
    $tempDir = "\\$server\D$\temp"

    try{
        #copy staged file to temp directory
        Copy-Item $stagedFile  -Destination $tempDir -Force

        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Successfully copied to $tempDir"
    } catch{
        $ErrorMessage = $Error[0].Exception.Message
        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Copy to $tempDir Failed - $ErrorMessage"
    }

    try{
        #copy file from temp to final directory
        Copy-Item $tempDir -Destination $dir -Force

        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Successfully copied to $dir"
    } catch{
        $ErrorMessage = $Error[0].Exception.Message
        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Copy to $dir Failed - $ErrorMessage"
    }
}

# Show an Open File Dialog and return the file selected by the user.
function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{  
    Add-Type -AssemblyName System.Windows.Forms

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog

    $openFileDialog.Title = $WindowTitle

    if ($InitialDirectory) 
    { 
        $openFileDialog.InitialDirectory = $InitialDirectory 
    }

    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) 
    { 
        $openFileDialog.MultiSelect = $true 
    }

    $openFileDialog.ShowHelp = $true 
    $null = $openFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))

    if ($AllowMultiSelect) 
    { 
        return $openFileDialog.Filenames 
    } 
    else 
    { 
        return $openFileDialog.Filename 
    }
}

#Selecting a server list file for contents to be read
$serverList = Read-OpenFileDialog -WindowTitle "Select your Server List" -InitialDirectory 'c:\temp' -Filter "Text files (*.txt)|*.txt"
if (![string]::IsNullOrEmpty($serverList)) 
{ 
    Write-Host "You selected the file: $serverList" 
}
else
{ 
    "You did not select a file.";break 
}


#reading servers in server lis
$servers = @(Get-content $serverList)

foreach($server in $servers){
    #User Variables 
    $origPath = "\\$server\D$\CXT\totalpayment\NTHost\Engine.dll"
    $ootbPath = "\\$server\D$\CXT\totalpayment\NTHost\Engine.dll_OOTB"
    $dir = "\\$server\D$\CXT\totalpayment\NTHost"

    if(Test-Path $dir){
        
        Write-Host "Making Copy of OOTB Engine.dll on $server" -ForegroundColor Cyan

        #Check if xml file OOTB file exist
        if(!(Test-Path $ootbPath)){

            Copy-Item -Path $origPath -Destination $ootbPath

            #check if the file was backed up
            if(Test-Path -path $ootbPath)
            {
                Write-Host "Engine.dll has been Successfully Copied and Renamed on $server" -ForegroundColor Green
            }else{
                Write-Host "Copy of Engine.dll failed on $server, Please investigate and try again" -ForegroundColor Red
                exit;
            }

            #Calling function to place new Engine.dll
            Write-Host "Placing new Engine.dll file" -ForegroundColor Cyan
            Copy-New-DLL -dir $dir -server $server

        } else {
           $response = $(Write-Host "Engine.dll.OOTB already exist on $server. Would you like to proceed? " -NoNewline) + $(Write-Host "Type (Y) YES or (N) NO: " -ForegroundColor Yellow -NoNewline; Read-Host)
           switch ($response)
           {
            Y {Copy-New-DLL -dir $dir -server $server}
            N {exit;}
            Default {$response}
           }
        }
        }else{
              Write-Host "$dir could not be found on $server. Please investigate and retry."
    }
}


