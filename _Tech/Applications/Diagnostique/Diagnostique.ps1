Add-Type -AssemblyName PresentationFramework,System.speech,System.Drawing,presentationCore

function Get-RequiredModules
{
    $modulesFolder = "$env:SystemDrive\_Tech\Applications\Source\modules"
    foreach ($module in Get-Childitem $modulesFolder -Name -Filter "*.psm1")
    {
        Import-Module $modulesFolder\$module
    }
}

#$desktop = [Environment]::GetFolderPath("Desktop")
$pathDiagnostique = "$env:SystemDrive\_Tech\Applications\Diagnostique"
$pathDiagnostiqueSource = "$env:SystemDrive\_Tech\Applications\Diagnostique\source"
set-location $pathDiagnostique
$applicationPath = "$env:SystemDrive\_Tech\Applications"
$sourceFolderPath = "$applicationPath\source"
$diagLockFile = "$sourceFolderPath\Diagnostique.lock"
Get-RequiredModules
$logFileName = Initialize-LogFile $pathDiagnostiqueSource
Get-RemoteFile "fondDiag.jpg" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/fondDiag.jpg' "$pathDiagnostiqueSource" 
Get-RemoteFile "MainWindow.xaml" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/MainWindow.xaml' "$pathDiagnostiqueSource"
Get-RemoteFile "DiagApps.JSON" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/DiagApps.JSON' "$pathDiagnostiqueSource"  
$adminStatus = Get-AdminStatus
if($adminStatus -eq $false)
{
    Restart-Elevated -Path $pathDiagnostique\Diagnostique.ps1
}
$Global:diagnostiqueIdentifier = "Diagnostique.ps1"
Test-ScriptInstance $diagLockFile $Global:diagnostiqueIdentifier

$xamlFile = "$pathDiagnostiqueSource\MainWindow.xaml"
$xamlContent = Read-XamlFileContent $xamlFile
$formatedXamlFile = Format-XamlFile $xamlContent
$xamlDoc = Convert-ToXmlDocument $formatedXamlFile
$XamlReader = New-XamlReader $xamlDoc
$window = New-WPFWindowFromXaml $XamlReader
$formControls = Get-WPFControlsFromXaml $xamlDoc $window

$formControls.BoutonMenu.Add_Click({
    start-process "$env:SystemDrive\\_Tech\\Menu.bat" -verb Runas
    $window.Close()
    Exit
})

$formControls.BoutonQuit.Add_Click({
    winget uninstall -e --id XPDNXG5333CSVK
    Invoke-Task -TaskName 'delete _tech' -ExecutedScript 'C:\Temp\Remove.bat'
    $window.Close()
})

$formControls.Boutonbat.Add_Click({
    $formControls.BoutonBattinfo.Visibility="Visible"
    $formControls.BoutonDontsleep.Visibility="Visible"
    $formControls.BoutonBattMonitor.Visibility="Visible"
    $formControls.Boutonbat.Visibility="Collapsed"
    Get-RemoteFile "Batterie.zip" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/Batterie.zip" "$pathDiagnostiqueSource"
})
$formControls.BoutonCPU.Add_Click({
    $formControls.BoutonAida.Visibility="Visible"
    $formControls.BoutonCoretemp.Visibility="Visible"
    $formControls.BoutonPrime95.Visibility="Visible"
    $formControls.BoutonHeavyLoad.Visibility="Visible"
    $formControls.BoutonThrottleStop.Visibility="Visible"
    $formControls.BoutonCPU.Visibility="Collapsed"
    New-Folder "$pathDiagnostiqueSource\CPU"
})
$formControls.BoutonHDD.Add_Click({
    $formControls.BoutonHDSentinnel.Visibility="Visible"
    $formControls.BoutonHDTune.Visibility="Visible"
    $formControls.BoutonASSD.Visibility="Visible"
    $formControls.BoutonDiskmark.Visibility="Visible"
    $formControls.BoutonHDD.Visibility="Collapsed"
    Get-RemoteFile "HDD.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/HDD.zip' "$pathDiagnostiqueSource"
})
$formControls.BoutonGPU.Add_Click({
    $formControls.BoutonFurmark.Visibility="Visible"
    $formControls.BoutonFurmarkV2.Visibility="Visible"
    $formControls.BoutonUnigine.Visibility="Visible"
    $formControls.BoutonGPU.Visibility="Collapsed"
    Get-RemoteFile "GPU.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/GPU.zip' "$pathDiagnostiqueSource"
})
$formControls.BoutonRAM.Add_Click({
    mdsched.exe
    Add-Log $logFileName "Memtest effectué"
})

$formControls.BoutonBattinfo.Add_Click({
    Start-App "batteryinfoview.exe" "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\Batterie\battinfoview"
    Add-Log $logFileName "Usure de la batterie vérifié"
})
$formControls.BoutonBattMonitor.Add_Click({
    Start-App "BatteryMonx64.exe" "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\Batterie\BatteryMonx64"
    Add-Log $logFileName "Usure de la batterie vérifié"
})
    
$formControls.BoutonDontsleep.Add_Click({
    Start-App "DontSleep_x64_p.exe" "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\Batterie\DontSleep"
    Add-Log $logFileName "Dontsleep a été utilisé pour tester la batterie"
})
    
$formControls.BoutonAida.Add_Click({
   $scriptBlock = {
        $pathDiagnostiqueSource = "$env:SystemDrive\_Tech\Applications\Diagnostique\source"
        $modulesFolder = "$env:SystemDrive\_Tech\Applications\Source\modules"
        foreach ($module in Get-Childitem $modulesFolder -Name -Filter "*.psm1")
        {
            Import-Module $modulesFolder\$module
        }
    Invoke-App "Aida64.zip" "https://ftp.alexchato9.com/public/file/WPdP-yDdBE2pOpHVFKNC6g/Aida64.zip" "$pathDiagnostiqueSource\cpu" 
    Add-Log $logFileName "Test de stabilité du système effectué"
    } 
    if ($PSVersionTable.PSVersion.Major -lt 7 -and -not (Get-Command -Type Cmdlet Start-ThreadJob -ErrorAction SilentlyContinue)) 
    {
        Install-Nuget
        Install-Module -Scope CurrentUser ThreadJob -Force #ca prend nuget
    }
    Import-Module -Name ThreadJob     
    Start-ThreadJob -ScriptBlock $scriptBlock | Wait-Job | Remove-Job
})
    
$formControls.BoutonCoretemp.Add_Click({
Invoke-App "Core Temp.zip" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/Core Temp.zip" "$pathDiagnostiqueSource\cpu"
Add-Log $logFileName "Température du CPU vérifié"
})

$formControls.BoutonPrime95.Add_Click({
Invoke-App "Prime95.zip" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/Prime95.zip" "$pathDiagnostiqueSource\cpu"
Add-Log $logFileName "Stress test du CPU effectué"
})

$formControls.BoutonHeavyLoad.Add_Click({
Invoke-App "HeavyLoad.zip" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/HeavyLoad.zip" "$pathDiagnostiqueSource\cpu"
Add-Log $logFileName "Test de stabilité du système effectué"
})
$formControls.BoutonThrottleStop.Add_Click({
    Invoke-App "ThrottleStop.zip" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/ThrottleStop.zip" "$pathDiagnostiqueSource\cpu"
    Add-Log $logFileName "Stress test du CPU effectué"
    })

function diskmarkinfoLog
{
$logfile = "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\HDD\CrystalDiskInfoPortable\App\CrystalDiskInfo\diskinfo.txt"
$contentlogfile = Get-Content $logfile
$lignedisk = "" #initialise la variable vide
foreach ($ligne in $contentlogfile) #pour chaque ligne dans le fichier, car chaque ligne est un objet
{
    if($ligne -match "Model") #si une ligne match drive + un chiffre
    {
        $lignedisk = $ligne
    }
    elseif($lignedisk -and $ligne -match "Interface") 
    {       
        "$lignedisk `r`n $ligne`r`n"    
    }
    elseif($lignedisk -and $ligne -match " Health Status") 
    {
        "$ligne $ligneInterfaceused`r`n"
        $lignedisk = "" #flusher une fois la variable a la fin
    }
}
}

$formControls.BoutonHDSentinnel.Add_Click({
function HDSentinnel
{
    $pathHDS = "C:\Program Files (x86)\Hard Disk Sentinel"
    Add-Log $logFileName "Vérifier la santé du disque dur"
    $apppath = Test-AppPresence $pathHDS
    if($apppath)
    {
        Start-App "HDSentinel.exe" $pathHDS
    }
    elseif($apppath -eq $false)
    {
    Install-Winget  
    winget install -e --id XPDNXG5333CSVK --accept-package-agreements --accept-source-agreements --silent | Out-Null
    $apppath = Test-AppPresence $pathHDS
        if($apppath -eq $false)
        {
            Chocoinstall
            choco install hdsentinel -y | Out-Null
        }
        Start-App "HDSentinel.exe" $pathHDS
    }
}
HDSentinnel
})

$formControls.BoutonHDTune.Add_Click({
    Start-App "_HDTune.exe" "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\HDD\_HDTune"
    Add-Log $logFileName "Vérifier la Vitesse du disque dur"
})

$formControls.BoutonASSD.Add_Click({
Start-App "AS SSD Benchmark.exe" "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\HDD\As_SSD"
Add-Log $logFileName "Vérifier la Vitesse du disque dur"
})

$formControls.BoutonDiskmark.Add_Click({
Start-Process -wait  "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\HDD\CrystalDiskInfoPortable\CrystalDiskInfoPortable.exe"  -ArgumentList "/copy"
Add-Log $logFileName "Vérifier la santé du disque dur"
#diskmarkinfolog | Out-File $logfilepath -Append
})

$formControls.BoutonFurmark.Add_Click({
Start-Process "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\GPU\FurMark\FurMark.exe"
Add-Log $logFileName "Stress test du GPU"
})
$formControls.BoutonFurmarkV2.Add_Click({
    Start-Process "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\GPU\FurMark_GUI\FurMark_GUI.exe"
    Add-Log $logFileName "Stress test du GPU"
    })
    


$formControls.BoutonUnigine.Add_Click({
Start-Process "https://benchmark.unigine.com/"
Add-Log $logFileName "Vérifier les performances du GPU"
})

$formControls.BoutonSpeccy.Add_Click({
Invoke-App "Speccy.zip" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/Speccy.zip" "$pathDiagnostiqueSource"
})

$formControls.BoutonHWMonitor.Add_Click({
Invoke-App "HWMonitor_x64.zip" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/HWMonitor_x64.zip" "$pathDiagnostiqueSource"
})

$formControls.BoutonWhocrashed.Add_Click({
Invoke-App "WhoCrashedEx.zip" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/WhoCrashedEx.zip" "$pathDiagnostiqueSource"
})

$formControls.BoutonSysinfo.Add_Click({
msinfo32
})

$window.add_Closed({
    Remove-Item -Path $diagLockFile -Force -ErrorAction SilentlyContinue
    exit
})

Start-WPFAppDialog $window

<#
$JSONFilePath = "$env:SystemDrive\_Tech\Applications\Diagnostique\source\DiagApps.JSON"
$jsonString = Get-Content -Raw $JSONFilePath
$appsInfo = ConvertFrom-Json $jsonString
$appNames = $appsInfo.psobject.Properties.Name
#Iterate over the applications in the JSON and interpolate the variables
$appNames | ForEach-Object {
    $appName = $_
    $appsInfo.$appName.path64 = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$appName.path64)
    $appsInfo.$appName.path32 = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$appName.path32)
    $appsInfo.$appName.pathAppData = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$appName.pathAppData)
    $appsInfo.$appName.NiniteName = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$appName.NiniteName)
    }
#>