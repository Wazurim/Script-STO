#V1.5
Add-Type -AssemblyName PresentationFramework,System.Windows.Forms,System.speech,System.Drawing,presentationCore
[System.Windows.Forms.Application]::EnableVisualStyles()

function ImportModules
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
ImportModules
CreateFolder "_Tech\Applications\Diagnostique\source"
DownloadFile "fondDiag.jpg" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/fondDiag.jpg' "$pathDiagnostiqueSource" 
DownloadFile "MainWindow.xaml" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/MainWindow.xaml' "$pathDiagnostiqueSource"
DownloadFile "DiagApps.JSON" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/DiagApps.JSON' "$pathDiagnostiqueSource"  

$inputXML = importXamlFromFile "$pathDiagnostiqueSource\MainWindow.xaml"
$formatedXaml = FormatXamlFile $inputXML
$ObjectXaml = CreateXamlObject $formatedXaml
$window = LoadWPFWindowFromXaml $ObjectXaml
$formControls = GetWPFObjects $formatedXaml $window


$formControls.BoutonMenu.Add_Click({
    start-process "$env:SystemDrive\\_Tech\\Menu.bat" -verb Runas
    $window.Close()
    Exit
})

$formControls.BoutonQuit.Add_Click({
    winget uninstall -e --id XPDNXG5333CSVK
    Task
    $window.Close()
})

$formControls.Boutonbat.Add_Click({
    $formControls.BoutonBattinfo.Visibility="Visible"
    $formControls.BoutonDontsleep.Visibility="Visible"
    $formControls.Boutonbat.Visibility="Collapsed"
    UnzipApp "Batterie" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/Batterie.zip" "$pathDiagnostiqueSource"
})
$formControls.BoutonCPU.Add_Click({
    $formControls.BoutonAida.Visibility="Visible"
    $formControls.BoutonCoretemp.Visibility="Visible"
    $formControls.BoutonPrime95.Visibility="Visible"
    $formControls.BoutonHeavyLoad.Visibility="Visible"
    $formControls.BoutonThrottleStop.Visibility="Visible"
    $formControls.BoutonCPU.Visibility="Collapsed"
    new-item -ItemType Directory -path "$pathDiagnostiqueSource\CPU" | Out-Null
})
$formControls.BoutonHDD.Add_Click({
    $formControls.BoutonHDSentinnel.Visibility="Visible"
    $formControls.BoutonHDTune.Visibility="Visible"
    $formControls.BoutonASSD.Visibility="Visible"
    $formControls.BoutonDiskmark.Visibility="Visible"
    $formControls.BoutonHDD.Visibility="Collapsed"
    UnzipApp "HDD" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/HDD.zip' "$pathDiagnostiqueSource"
})
$formControls.BoutonGPU.Add_Click({
    $formControls.BoutonFurmark.Visibility="Visible"
    $formControls.BoutonUnigine.Visibility="Visible"
    $formControls.BoutonGPU.Visibility="Collapsed"
    UnzipApp "GPU" 'https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/GPU.zip' "$pathDiagnostiqueSource"
})
$formControls.BoutonRAM.Add_Click({
    mdsched.exe
    Addlog "diagnostiquelog.txt" "Memtest effectué"
})

$formControls.BoutonBattinfo.Add_Click({
    Start-Process "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\Batterie\battinfoview\batteryinfoview.exe"
    Addlog "diagnostiquelog.txt" "Usure de la batterie vérifié"
    })
    
    $formControls.BoutonDontsleep.Add_Click({
    Start-Process "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\Batterie\DontSleep\DontSleep_x64_p.exe"
    Addlog "diagnostiquelog.txt" "Dontsleep a été utilisé pour tester la batterie"
    })
    
    $formControls.BoutonAida.Add_Click({
    UnzipAppLaunch "Aida64" "https://ftp.alexchato9.com/public/file/WPdP-yDdBE2pOpHVFKNC6g/Aida64.zip" "aida64.exe" "$pathDiagnostiqueSource\cpu"
    Addlog "diagnostiquelog.txt" "Test de stabilité du système effectué"
    })
    
    $formControls.BoutonCoretemp.Add_Click({
    UnzipAppLaunch "Core_Temp" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/Core_Temp.zip" "Core Temp.exe" "$pathDiagnostiqueSource\cpu"
    Addlog "diagnostiquelog.txt" "Température du CPU vérifié"
    })
    
    $formControls.BoutonPrime95.Add_Click({
    UnzipAppLaunch "Prime95" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/Prime95.zip" "Prime95.exe" "$pathDiagnostiqueSource\cpu"
    Addlog "diagnostiquelog.txt" "Stress test du CPU effectué"
    })
    
    $formControls.BoutonHeavyLoad.Add_Click({
    UnzipAppLaunch "HeavyLoad" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/HeavyLoad.zip" "HeavyLoad.exe" "$pathDiagnostiqueSource\cpu"
    Addlog "diagnostiquelog.txt" "Test de stabilité du système effectué"
    })
    $formControls.BoutonThrottleStop.Add_Click({
        UnzipAppLaunch "ThrottleStop" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/ThrottleStop.zip" "ThrottleStop.exe" "$pathDiagnostiqueSource\cpu"
        Addlog "diagnostiquelog.txt" "Stress test du CPU effectué"
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
        Addlog "diagnostiquelog.txt" "Vérifier la santé du disque dur"
        $apppath = VerifPresenceApp $pathHDS
        if($apppath)
        {
            StartExeFile "HDSentinel.exe" $pathHDS
        }
        elseif($apppath -eq $false)
        {
        Wingetinstall  
        winget install -e --id XPDNXG5333CSVK --accept-package-agreements --accept-source-agreements --silent | Out-Null
        $apppath = VerifPresenceApp $pathHDS
            if($apppath -eq $false)
            {
                Chocoinstall
                choco install hdsentinel -y | Out-Null
            }
            StartExeFile "HDSentinel.exe" $pathHDS
        }
    }
    HDSentinnel
    })
    
    $formControls.BoutonHDTune.Add_Click({
        Start-Process "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\HDD\HD_Tune\_HDTune.exe"
        Addlog "diagnostiquelog.txt" "Vérifier la Vitesse du disque dur"
    })
    
    $formControls.BoutonASSD.Add_Click({
    Start-Process "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\HDD\As_SSD\AS SSD Benchmark.exe"
    })
    
    $formControls.BoutonDiskmark.Add_Click({
    Start-Process -wait  "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\HDD\CrystalDiskInfoPortable\CrystalDiskInfoPortable.exe"  -ArgumentList "/copy"
    Addlog "diagnostiquelog.txt" "Vérifier la santé du disque dur"
    #diskmarkinfolog | Out-File $logfilepath -Append
    })
    
    $formControls.BoutonFurmark.Add_Click({
    Start-Process "$env:SystemDrive\_Tech\Applications\Diagnostique\Source\GPU\FurMark\FurMark.exe"
    Addlog "diagnostiquelog.txt" "Stress test du GPU"
    })
    
    
    $formControls.BoutonUnigine.Add_Click({
    Start-Process "https://benchmark.unigine.com/"
    Addlog "diagnostiquelog.txt" "Vérifier les performances du GPU"
    })
    
    $formControls.BoutonSpeccy.Add_Click({
    UnzipAppLaunch "Speccy" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/Speccy.zip" "Speccy.exe" "$pathDiagnostiqueSource"
    })
    
    $formControls.BoutonHWMonitor.Add_Click({
    UnzipAppLaunch "HWmonitor" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/HWMonitor.zip" "HWMonitor_x64.exe" "$pathDiagnostiqueSource"
    })
    
    $formControls.BoutonWhocrashed.Add_Click({
    UnzipAppLaunch "WhoCrashed" "https://raw.githubusercontent.com/jeremyrenaud42/Diagnostique/main/WhoCrashed.zip" "WhoCrashedEx.exe" "$pathDiagnostiqueSource"
    })
    
    $formControls.BoutonSysinfo.Add_Click({
    msinfo32
    })

LaunchWPFAppDialog $window


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