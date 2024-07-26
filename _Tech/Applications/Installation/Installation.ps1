Add-Type -AssemblyName PresentationFramework,System.Windows.Forms,System.speech,System.Drawing,presentationCore,Microsoft.VisualBasic

function ImportModules
{
    $modulesFolder = "$env:SystemDrive\_Tech\Applications\Source\modules"
    foreach ($module in Get-Childitem $modulesFolder -Name -Filter "*.psm1")
    {
        Import-Module $modulesFolder\$module
    }
}

function PrepareDependencies
{
    set-location $pathInstallation
    ImportModules
    CreateFolder "_Tech\Applications\Installation\source"
    CheckInternetStatusLoop
    DownloadFile "InstallationApps.JSON" 'https://raw.githubusercontent.com/jeremyrenaud42/Installation/main/InstallationApps.JSON' "$pathInstallationSource"
    DownloadFile "MainWindow.xaml" 'https://raw.githubusercontent.com/jeremyrenaud42/Installation/main/MainWindow.xaml' "$pathInstallationSource"
    DownloadFile "MainWindow1.xaml" 'https://raw.githubusercontent.com/jeremyrenaud42/Installation/main/MainWindow1.xaml' "$pathInstallationSource"
}

function GetManufacturer
{
    $manufacturerBrand = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Manufacturer #Chercher la marque de l'ordinateur
    #Get-CimInstance -Class Win32_BaseBoard | Select-Object -Property Manufacturer # + rapide
    return $manufacturerBrand
}

$ErrorActionPreference = 'silentlycontinue'#Continuer même en cas d'erreur, cela évite que le script se ferme s'il rencontre une erreur
$pathInstallation = "$env:SystemDrive\_Tech\Applications\Installation"
$pathInstallationSource = "$env:SystemDrive\_Tech\Applications\Installation\source"
$windowsVersion = (Get-WmiObject -class Win32_OperatingSystem).Caption
PrepareDependencies

#WPF - appMenuChoice
$inputXML = importXamlFromFile "$pathInstallation\source\MainWindow.xaml"
$formatedXaml = FormatXamlFile $inputXML
$ObjectXaml = CreateXamlObject $formatedXaml
$window = LoadWPFWindowFromXaml $ObjectXaml
$formControlsMenuApp = GetWPFObjects $formatedXaml $window

#ajout des events, cases a cocher, etc.. pour le WPF:

#Logiciels à cocher automatiquement
$manufacturerBrand = GetManufacturer
if($manufacturerBrand -match 'LENOVO')
{
    $formControlsMenuApp.chkboxLenovoVantage.IsChecked = $true
    $formControlsMenuApp.chkboxLenovoSystemUpdate.IsChecked = $true
}
elseif($manufacturerBrand -match 'HP')
{        
    $formControlsMenuApp.chkboxHPSA.IsChecked = $true
}
elseif($manufacturerBrand -match 'DELL')
{
    $formControlsMenuApp.chkboxDellsa.IsChecked = $true
}
elseif($manufacturerBrand -like '*Micro-Star*')
{
    $formControlsMenuApp.chkboxMSICenter.IsChecked = $true
}
$VideoController = Get-WmiObject win32_VideoController | Select-Object -Property name
if($VideoController -match 'NVIDIA')
{
    $formControlsMenuApp.chkboxGeForce.IsChecked = $true
}
#Boutons
$formControlsMenuApp.btnGo.Add_Click({
$window.Close()
})
$formControlsMenuApp.btnReturn.Add_Click({
    start-process "$env:SystemDrive\\_Tech\\Menu.bat" -verb Runas
    $window.Close()
    Exit
})
$formControlsMenuApp.btnclose.Add_Click({
    $window.Close()
    Exit
})
$formControlsMenuApp.btnQuit.Add_Click({
    Task
    $window.Close()
    Exit
})

LaunchWPFAppDialog $window

#WPF - Main GUI
$inputXML = importXamlFromFile "$pathInstallation\source\MainWindow1.xaml"
$formatedXaml = FormatXamlFile $inputXML
$ObjectXaml = CreateXamlObject $formatedXaml
$window = LoadWPFWindowFromXaml $ObjectXaml
$formControlsMain = GetWPFObjects $formatedXaml $window

$formControlsMain.richTxtBxOutput.add_textchanged({
    [System.Windows.Forms.Application]::DoEvents() #Refresh le text
    $formControlsMain.richTxtBxOutput.ScrollToEnd() #scroll en bas
})

LaunchWPFApp $window

function Debut
{
    $actualDate = (Get-Date).ToString()
    Addlog "installationlog.txt" "Installation de $windowsVersion le $actualDate"
    $formControlsMain.lblProgress.content = "Préparation"   
    $formControlsMain.richTxtBxOutput.AppendText("Lancement de la configuration du Windows`r`n")  
    #MusicDebut "$pathInstallation\Source\Intro.mp3" 
    $formControlsMain.richTxtBxOutput.AppendText("Installation de NuGet`r`n")
    Nugetinstall
    $formControlsMain.richTxtBxOutput.AppendText("Installation de Chocolatey`r`n")    
    Chocoinstall
    $formControlsMain.richTxtBxOutput.AppendText("Installation de Winget`r`n")    
    Wingetinstall
}

function PrepareWindowsUpdate
{
    Install-Module PSWindowsUpdate -Force | Out-Null #install le module pour les Update de Windows
    $pathPSWindowsUpdateExist = test-path "$env:SystemDrive\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate" 
    if($pathPSWindowsUpdateExist -eq $false) #si le module n'est pas là (Plan B)
    {
        choco install pswindowsupdate -y | out-null
    }
    Import-Module PSWindowsUpdate | out-null 
}

function GetWindowsUpdate
{
    $formControlsMain.lblProgress.Content = "Mises à jour de Windows"
    $formControlsMain.richTxtBxOutput.AppendText("Vérification des mises à jour de Windows") 
    PrepareWindowsUpdate 
    $updates = Get-WUList -MaxSize 250mb
    $firstUpdate = $updates[0]
    $totalUpdates = $updates.Count
        if($totalUpdates -eq 0)
        {
            $formControlsMain.richTxtBxOutput.AppendText(" -Toutes les mises à jour sont deja installées`r`n")     
        }
        elseif($totalUpdates -gt 0)
        {
            if ([string]::IsNullOrEmpty($firstUpdate.Title)) 
            {
                $formControlsMain.richTxtBxOutput.AppendText(" -Échec de la vérification des mise a jours de Windows`r`n")        
            }
            else
            {
                $formControlsMain.richTxtBxOutput.AppendText(" -$totalUpdates mises à jour de disponibles`r`n") 
                $currentUpdate = 0
                    foreach($update in $updates)
                    { 
                        $currentUpdate++ 
                        $kb = $update.KB
                        $formControlsMain.richTxtBxOutput.AppendText("Mise à jour $($currentUpdate) sur $($totalUpdates): $($update.Title)`r`n")                    
                        Get-WindowsUpdate -KBArticleID $kb -MaxSize 250mb -Install -AcceptAll -IgnoreReboot     
                    }
            }
        }  
        else
        {
            $formControlsMain.richTxtBxOutput.AppendText(" -Échec de la vérification des mise a jours de Windows`r`n") 
        } 
    Addlog "installationlog.txt" "Mises à jour de Windows effectuées"
}

Function RenameSystemDrive
{
    $formControlsMain.lblProgress.Content = "Renommage du disque"    
    Set-Volume -DriveLetter 'C' -NewFileSystemLabel "OS"
    $formControlsMain.richTxtBxOutput.AppendText("`r`nLe disque C: a été renommé OS`r`n")    
    Addlog "installationlog.txt" "Le disque C: a été renommé OS"
}

Function ConfigureExplorer
{
    $formControlsMain.lblProgress.Content = "Configuration des paramètres de l'explorateur de fichiers"
    set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name 'LaunchTo' -Type 'DWord' -Value '1'
    $formControlsMain.richTxtBxOutput.AppendText("L'accès rapide a été remplacé par Ce PC`r`n")   
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name 'ShowSyncProviderNotifications' -Type 'DWord' -Value '0'
    $formControlsMain.richTxtBxOutput.AppendText("Le fournisseur de synchronisation a été decoché`r`n")   
    Addlog "installationlog.txt" "Explorateur de fichiers configuré" 
}

 Function DisableBitlocker
{
    $formControlsMain.lblProgress.Content = "Désactivation du bitlocker"   
    $bitlockerStatus = Get-BitLockerVolume | Select-Object -expand VolumeStatus
        if ($bitlockerStatus -eq 'EncryptionInProgress')
        {
            $bitlockerVolume = Get-BitLockerVolume
            Disable-BitLocker -MountPoint $bitlockerVolume | Out-Null
            $formControlsMain.richTxtBxOutput.AppendText("Bitlocker a été désactivé`r`n")            
        }
    Addlog "installationlog.txt" "Bitlocker a été désactivé"
}

Function DisableFastBoot
{
    $formControlsMain.lblProgress.Content = "Desactivation du demarrage rapide"    
    set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name 'HiberbootEnabled' -Type 'DWord' -Value '0'
    #powercfg /h off
    $formControlsMain.richTxtBxOutput.AppendText("Le démarrage rapide a été désactivé`r`n")   
    Addlog "installationlog.txt" "Le démarrage rapide a été désactivé"
}

Function RemoveEngKeyboard
{
    $formControlsMain.lblProgress.Content = "Suppression du clavier Anglais"   
    $langList = Get-WinUserLanguageList #Gets the language list for the current user account
    $anglaisCanada = $langList | Where-Object LanguageTag -eq "en-CA" #sélectionne le clavier anglais canada de la liste
    $langList.Remove($anglaisCanada) | Out-Null #supprimer la clavier sélectionner
    Set-WinUserLanguageList $langList -Force -WarningAction SilentlyContinue | Out-Null #applique le changement
    $formControlsMain.richTxtBxOutput.AppendText("Le clavier Anglais a été supprimé`r`n")
    Addlog "installationlog.txt" "Le clavier Anglais a été supprimé"
}

Function ConfigurePrivacy
{
    $formControlsMain.lblProgress.Content = "Paramètres de confidentialité"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Type 'DWord' -Value 0 
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Type 'DWord' -Value 0 
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Type 'DWord' -Value 0 
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Type 'DWord' -Value 0 
    $formControlsMain.richTxtBxOutput.AppendText("Les options de confidentialité ont été configuré`r`n") 
    Addlog "installationlog.txt" "Les options de confidentialité ont été configuré"
      
}

Function DisplayDesktopIcon
{
    $formControlsMain.lblProgress.Content = "Installation des icones systèmes sur le bureau"   
    if (!(Test-Path -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"))
		{
			New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Force
		}
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Type 'DWord' -Value 0 
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Type 'DWord' -Value 0 
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Type 'DWord' -Value 0
    $formControlsMain.richTxtBxOutput.AppendText("Les icones systèmes ont été installés sur le bureau`r`n")
    $formControlsMain.richTxtBxOutput.AppendText(" `r`n") #Permet de créé un espace avant les logiciels
    Addlog "installationlog.txt" "Les icones systèmes ont été installés sur le bureau"  
}

function UpdateMsStore
{
    $formControlsMain.lblProgress.Content = "Mises à jour du Microsoft Store"
    $formControlsMain.richTxtBxOutput.AppendText("`r`nLancement des updates du Microsoft Store") 
    $namespaceName = "root\cimv2\mdm\dmmap"
    $className = "MDM_EnterpriseModernAppManagement_AppManagement01"
    $wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
    $wmiObj.UpdateScanMethod() | Out-Null
    $formControlsMain.richTxtBxOutput.AppendText(" -Mises à jour du Microsoft Store lancées`r`n")
    Addlog "installationlog.txt" "Mises à jour de Microsoft Store"
}

$JSONFilePath = "$env:SystemDrive\_Tech\Applications\Installation\Source\InstallationApps.JSON"
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

#Install les logiciels cochés
function GetCheckBoxStatus 
{
    $checkboxes = $formControlsMenuApp.GridApps.Children | Where-Object {$_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "chkbox*" -and $_.IsChecked -eq $true}
    foreach ($chkbox in $checkboxes) 
    {
        $appName = "$($chkbox.Content)"
        InstallSoftware $appsInfo.$appName
    }
}

 function CheckSoftwarePresence($appInfo)
{
   $SoftwareInstallationStatus= $false
   if (($appInfo.path64 -AND (Test-Path $appInfo.path64)) -OR 
   ($appInfo.path32 -AND (Test-Path $appInfo.path32)) -OR 
   ($appInfo.pathAppData -AND (Test-Path $appInfo.pathAppData)))
   {
     $SoftwareInstallationStatus = $true
   }
   return $SoftwareInstallationStatus
}

function InstallSoftware($appInfo)
{
    $formControlsMain.lblProgress.Content = "Installation de $appName"
    $formControlsMain.richTxtBxOutput.AppendText("Installation de $appName en cours")
    $SoftwareInstallationStatus = CheckSoftwarePresence $appInfo
        if($SoftwareInstallationStatus)
        {
            $formControlsMain.richTxtBxOutput.AppendText(" -$appName est déja installé`r`n")
        }
        elseif($SoftwareInstallationStatus -eq $false)
        {  
            InstallSoftwareWithWinget $appInfo
        }
    Addlog "installationlog.txt" "Installation de $appName" 
}

function InstallSoftwareWithWinget($appInfo)
{
    if($appInfo.WingetName)
    {
        winget install -e --id $appInfo.wingetname --accept-package-agreements --accept-source-agreements --silent | out-null
    } 
    $SoftwareInstallationStatus = CheckSoftwarePresence $appInfo
        if($SoftwareInstallationStatus)
        {
            $formControlsMain.richTxtBxOutput.AppendText(" -$appName installé avec succès`r`n") 
        } 
        else
        {
            InstallSoftwareWithChoco $appInfo
        }     
}

function InstallSoftwareWithChoco($apsInfo)
{
    if($appInfo.ChocoName)
    {
        choco install $appInfo.ChocoName -y | out-null
    }
    $SoftwareInstallationStatus = CheckSoftwarePresence $apsInfo
    if($SoftwareInstallationStatus)
    {   
        $formControlsMain.richTxtBxOutput.AppendText(" -$appName installé avec succès`r`n")  
    }
    else
    {
        $formControlsMain.richTxtBxOutput.AppendText(" -$appName a échoué`r`n")
        InstallSoftwareWithNinite $appInfo
    } 
}

function InstallSoftwareWithNinite($appInfo)
{
    if($appInfo.NiniteName)
    {
        Invoke-WebRequest $appInfo.NiniteGithubLink -OutFile $appInfo.NiniteName | Out-Null
        Start-Process $appInfo.NiniteName -Verb runAs
    }
}

function CheckActivationStatus
{
    $activated = Get-CIMInstance -query "select LicenseStatus from SoftwareLicensingProduct where LicenseStatus=1" | Select-Object -ExpandProperty LicenseStatus 
    $activated
    if($activated -eq "1")
    {
        $formControlsMain.richTxtBxOutput.AppendText("`r`n$windowsVersion est activé sur cet ordinateur`r`n")       
    }
    else 
    {
        [Microsoft.VisualBasic.Interaction]::MsgBox("Windows n'est pas activé",'OKOnly,SystemModal,Information', "Installation Windows") | Out-Null
        $formControlsMain.richTxtBxOutput.AppendText("`r`nWindows n'est pas activé`r`n")     
    }  
}

function SetDefaultBrowser
{
    $currentHttpAssocation = Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\Shell\Associations\URLAssociations\http\UserChoice | Select-Object -ExpandProperty ProgId
    $currentHttpsAssocation = Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\Shell\Associations\URLAssociations\https\UserChoice | Select-Object -ExpandProperty ProgId
    if(($currentHttpAssocation -notlike "ChromeHTML*") -and ($currentHttpsAssocation -notlike "ChromeHTML*"))
    {
        Start-Process ms-settings:defaultapps
        [Microsoft.VisualBasic.Interaction]::MsgBox("Mettre Google Chrome par défaut",'OKOnly,SystemModal,Information', "Installation Windows") | Out-Null   
    }
}
   
function SetDefaultPDFViewer
{
    $currentDefaultPdfViewer = Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice | Select-Object -ExpandProperty ProgId
    if($currentDefaultPdfViewer -notlike "*.Document.DC")
    {
        [Microsoft.VisualBasic.Interaction]::MsgBox("Mettre Adobe Reader par défaut",'OKOnly,SystemModal,Information', "Installation Windows") | Out-Null   
    }
}
    
function PinGoogleTaskbar
{
    $taskbardir = "$env:SystemDrive\Users\$env:username\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    $chromeTaskbarStatus= Test-Path "$taskbardir\*Google*Chrome*"
    if($chromeTaskbarStatus-eq $false)
    {
        [Microsoft.VisualBasic.Interaction]::MsgBox("Épingler Google Chrome dans la barre des tâches",'OKOnly,SystemModal,Information', "Installation Windows") | Out-Null   
    } 
}

function Fin
{
    Addlog "installationlog.txt" "Installation de Windows effectué avec Succès"
    CopyLog "installationlog.txt" "$env:SystemDrive\TEMP"  
    [Audio]::Volume = 0.25
    [console]::beep(1000,666)
    Start-Sleep -s 1
    [Audio]::Volume = 0.75
    Getvoice -Verb runAs
    Speak "Vous avez terminer la configuration du Windows."
    SetDefaultBrowser
    SetDefaultPDFViewer
    PinGoogleTaskbar
    Stop-Process -Name "ninite" -Force -erroraction ignore
    $rebootStatus = get-wurebootstatus -Silent #vérifie si ordi doit reboot à cause de windows update
    if($rebootStatus)
    {
        $formControlsMain.richTxtBxOutput.AppendText("`r`nL'ordinateur devra redémarrer pour finaliser l'installation des mises à jour")
        [Microsoft.VisualBasic.Interaction]::MsgBox("L'ordinateur devra redémarrer pour finaliser l'installation des mises à jour",'OKOnly,SystemModal,Information', "Installation Windows") | Out-Null
        shutdown /r /t 300
        Task #tâche planifié qui delete tout
    }
    else 
    {
        Task #tâche planifié qui delete tout  
    }     
}

function thread1{
    UpdateMsStore#
    GetWindowsUpdate#
}

function thread2{
    RenameSystemDrive ##
    ConfigureExplorer ##
    DisableBitlocker ##
    DisableFastBoot ##
    RemoveEngKeyboard ##
    ConfigurePrivacy ##
    DisplayDesktopIcon ##
}

function thread3{
    GetCheckBoxStatus  ###
}

function thread4{
    CheckActivationStatus ####
}

function Main
{
Debut

$jobs = @()
    $jobs += Start-Job -ScriptBlock { thread1 }
    $jobs += Start-Job -ScriptBlock { thread2 }
    $jobs += Start-Job -ScriptBlock { thread3 }
    $jobs += Start-Job -ScriptBlock { thread4 }

    # Wait for all jobs to complete
    $jobs | ForEach-Object { $_ | Wait-Job | Receive-Job }



Fin
}
Main