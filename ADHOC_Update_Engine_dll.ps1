<###############################
Title: Update ClaimsXten Engine.dll
Author: TW
Original: 2022_04_12
Last Updated: 2022_04_12
	

Overview:
- Deploys new ClaimsXten Engine.dll for additional logging
- Vendor created DLL to provide more information around Invalid Transaction ID
- disclaimer: mcAfee will block the script from placing files on some servers.
###############################>

##############
# Functions  #
##############

#Make backup of existing DLL files
function Make-Backup_of-Existing-DDLS(){
    param(
        $ootbEngPath,
        $ootbLegEngPath,
        $origLegEngPath,
        $origEngPath,
        $dir,
        $tempDir
    )
    Write-Host "Making Backup of OOTB Engine.dll & McKesson.TPP.LegacyRuleEngine.dll on $server" -ForegroundColor Cyan

        #Check if xml file OOTB file exist
        if(!(Test-Path $ootbEngPath) -and !(Test-Path $ootbLegEngPath )){

            #Copy and rename Engine.dll
            try{
                Copy-Item -Path $origEngPath -Destination $ootbEngPath
            }catch{
                $ErrorMessage = $Error[0].Exception.Message
                Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Copy to $dir Failed - $ErrorMessage" -ForegroundColor Red
            }

            #Copy and rename McKesson.TPP.LegacyRuleEngine.dll
            try{
                Copy-Item -Path $origLegEngPath -Destination $ootbLegEngPath
            }catch{
                $ErrorMessage = $Error[0].Exception.Message
                Write-Host "Date: $((Get-Date).ToString()). Status: McKesson.TPP.LegacyRuleEngine.dll Copy to $dir Failed - $ErrorMessage" -ForegroundColor Red
            }
            

            #check if the file was backed up
            if(Test-Path -path $ootbEngPath)
            {
                Write-Host "Engine.dll has been Successfully Copied and Renamed on $server" -ForegroundColor Green
            }else{
                Write-Host "Copy of Engine.dll failed on $server, Please investigate and try again" -ForegroundColor Red
                exit;
            }

            #check if the file was backed up
            if(Test-Path -path $ootbLegEngPath)
            {
                Write-Host "McKesson.TPP.LegacyRuleEngine.dll has been Successfully Copied and Renamed on $server" -ForegroundColor Green
            }else{
                Write-Host "Copy of McKesson.TPP.LegacyRuleEngine.dll failed on $server, Please investigate and try again" -ForegroundColor Red
                exit;
            }
      } else {
          $response = $(Write-Host "Engine.dll.OOTB and McKesson.TPP.LegacyRuleEngine.dll.OOTB files already exist on $server. Would you like to proceed? " -NoNewline) + $(Write-Host "Type (Y) YES or (N) NO: " -ForegroundColor Yellow -NoNewline; Read-Host)
           switch ($response)
           {
            Y {Place-New-DLLS-To-Path -dir $dir -tempDir $tempDir}
            N {exit;}
            Default {$response}
         }
     }
            
}

#Copy new dll to D:\temp on server
function Copy-New-DLL-To-Temp{
    param (
        $dir,
        $tempDir
    )

    $tempEngineDLL = "$tempDir\Engine.dll"
    $tempLegRuleDLL = "$tempDir\McKesson.TPP.LegacyRuleEngine.dll"

    #copy staged Engine.dll file to temp directory
    try{
        Copy-Item $stagedEngFile  -Destination $tempDir -Force

        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Successfully copied to $tempDir" -ForegroundColor Green
        if(Test-Path $tempEngineDLL){
            try{
                #Ublock file
                Unblock-File $tempEngineDLL
            }catch{
                $ErrorMessage = $Error[0].Exception.Message
                Write-Host "Date: $((Get-Date).ToString()). Status: McKesson.Unblocking of Engine.dll Failed - $ErrorMessage" -ForegroundColor Red
            }
        }else{
            Write-Host "Engine DLL was not successfully placed in $tempDir" -ForegroundColor Red
        }


    } catch{
        $ErrorMessage = $Error[0].Exception.Message
        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Copy to $tempDir Failed - $ErrorMessage" -ForegroundColor Red
    }

    #copy staged file to temp directory
    try{
        Copy-Item $stagedLegacyEngFile  -Destination $tempDir -Force

         if(Test-Path $tempLegRuleDLL){
            try{
                #Ublock file
                Unblock-File $tempLegRuleDLL
            }catch{
                $ErrorMessage = $Error[0].Exception.Message
                Write-Host "Date: $((Get-Date).ToString()). Status: McKesson.Unblocking of TPP.LegacyRuleEngine.dll Failed - $ErrorMessage" -ForegroundColor Red
            }
        }else{
            Write-Host "McKesson.TPP.LegacyRuleEngine DLL was not successfully placed in $tempDir" -ForegroundColor Red
        }

        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Successfully copied to $tempDir" -ForegroundColor Green
    } catch{
        $ErrorMessage = $Error[0].Exception.Message
        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Copy to $tempDir Failed - $ErrorMessage" -ForegroundColor Red
    }
}

#Move new dll to D:\temp on server
function Place-New-DLLS-To-Path{
    param (
        $dir,
        $tempDir
    )
    try{
        $new_engine_dll = "$tempDir\Engine.dll"

        #copy file from temp to final directory
        Copy-Item $new_engine_dll -Destination $dir -Force
        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Successfully copied $new_engine_dll to $dir" -ForegroundColor Green

    }catch{
        $ErrorMessage = $Error[0].Exception.Message
        Write-Host "Date: $((Get-Date).ToString()). Status: Engine.dll Copy $new_engine_dll to $dir Failed - $ErrorMessage" -ForegroundColor Red
    }

    try{
        $new_leg_engine_dll = "$tempDir\McKesson.TPP.LegacyRuleEngine.dll"

        #copy file from temp to final directory
        Copy-Item $new_leg_engine_dll -Destination $dir -Force

        Write-Host "Date: $((Get-Date).ToString()). Status: McKesson.TPP.LegacyRuleEngine.dll Successfully copied $new_leg_engine_dll to $dir" -ForegroundColor Green
    } catch{
        $ErrorMessage = $Error[0].Exception.Message
        Write-Host "Date: $((Get-Date).ToString()). Status: McKesson.TPP.LegacyRuleEngine.dll Copy $new_leg_engine_dll to $dir Failed - $ErrorMessage" -ForegroundColor Red
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




##############
#  MAIN CODE #
##############

#Selecting a server list file for contents to be read
$serverList = Read-OpenFileDialog -WindowTitle "Select your Server List" -InitialDirectory 'c:\temp' -Filter "Text files (*.txt)|*.txt"
if (![string]::IsNullOrEmpty($serverList)) 
{ 
    Write-Host "You selected the file: $serverList" -ForegroundColor Yellow
}
else
{ 
    Write-Host "You did not select a file." -ForegroundColor Red
    ;break 
}


#reading servers in server lis
$servers = @(Get-content $serverList)

foreach($server in $servers){
    #User Variables 
    $origEngPath = "\\$server\D$\CXT\totalpayment\NTHost\Engine.dll"
    $ootbEngPath = "\\$server\D$\CXT\totalpayment\NTHost\Engine.dll.OOTB"
    $origLegEngPath = "\\$server\D$\CXT\totalpayment\NTHost\McKesson.TPP.LegacyRuleEngine.dll"
    $ootbLegEngPath = "\\$server\D$\CXT\totalpayment\NTHost\McKesson.TPP.LegacyRuleEngine.dll.OOTB"
    $dir = "\\$server\D$\CXT\totalpayment\NTHost"
    $stagedEngFile = "\\apps\Local\EMT\COTS\McKesson\ClaimsXten\v6.3\Current_Releases\DLL_Hot_Fixes\Engine.dll Extra Logging\Engine.dll"
    $stagedLegacyEngFile = "\\apps\Local\EMT\COTS\McKesson\ClaimsXten\v6.3\Current_Releases\DLL_Hot_Fixes\Engine.dll Extra Logging\McKesson.TPP.LegacyRuleEngine.dll"
    $tempDir = "\\$server\D$\temp"

    if(Test-Path $dir){
        #Calling function to take backups of existing DLLS
        Write-Host "Taking Backup of OOTB Engine &  McKesson.TPP.LegacyRuleEngine DLL files" -ForegroundColor Cyan
        Make-Backup_of-Existing-DDLS -ootbEngPath $ootbEngPath -ootbLegEngPath $ootbLegEngPath -origLegEngPath $origLegEngPath -origEngPath $origEngPath -dir $dir -tempDir $tempDir

        #Calling function to copy the latest staged DLL files to D:\temp on server NOTE: Files can become blocked so if services do not start this could be the reason.
        Write-Host "Taking Backup of OOTB Engine &  McKesson.TPP.LegacyRuleEngine DLL files" -ForegroundColor Cyan
        Copy-New-DLL-To-Temp -dir $dir -tempDir $tempDir

        #Calling function to place new Engine.dll
        Write-Host "Placing new Engine &  McKesson.TPP.LegacyRuleEngine DLL files" -ForegroundColor Cyan
        Place-New-DLLS-To-Path -dir $dir -tempDir $tempDir
    }
}


