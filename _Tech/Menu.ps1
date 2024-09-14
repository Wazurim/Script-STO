<#
.SYNOPSIS
    Affiche un menu qui permet de sélectionner les actions à faire
.DESCRIPTION
    Directement téléchargé par le .exe il va permettre de poser les bases pour que tout fonctionne.
    vérifie donc qu'Internet soit présent, que le script soit en admin
    Créer les dossiers nécéssaires
    télécharge les modules et les importes (executionpolicy doit etre a unrestricted pour que ca importe)
    télécharge le script qui permet d'effacer/desisntaller le tout
    affiche un menu généré en WPF par un fichier XAML
    Permet d'installer winget et choco tout de suite au besoin
    Affiche les boutons qui ouvre les autres scripts
.NOTES
    est initialement downloadé par Stoolbox.exe depuis github
    Par la suite il ya un raccourci sur le bureau pour l'appeler
    Ou directement via le menu.bat dans c:\_tech
#>

#Load les assemblies nécéssaire au fonctionnement
Add-Type -AssemblyName PresentationFramework,System.Windows.Forms,System.speech,System.Drawing,presentationCore
########################Fonctions nécéssaire au déroulement########################

function Test-InternetConnection
{
    <#
    .SYNOPSIS
        Vérifie si il y a Internet de connecté
    .DESCRIPTION
        Envoi une seule requête PING vers 8.8.8.8 (google.com)
        Tant que la requête échoue ca affiche un message aux 5 secondes qui mentionne qu'il n'y a pas Internet
        Le message disparait après avoir cliquer OK si Internet est connecté.
    .PARAMETER PingAddress
        Adresse IP utilisé pour le ping. Defaut = 8.8.8.8 (Google.com)
    .PARAMETER CheckInterval
        Le nombre de délai avant de recommencer la reqête ping. Defaut = 5 secondes
    .EXAMPLE
        Test-InternetConnection
        Tests the internet connection using default parameters (pinging 8.8.8.8 every 5 seconds).
    .EXAMPLE
        Test-InternetConnection -PingAddress "1.1.1.1" -CheckInterval 10
        Tests the internet connection by pinging 1.1.1.1 and checking every 10 seconds.
    .Notes
        Ne prend pas la fonction deja inclus dans le module Verifiation car a ce moment la on a pas les modules de downloadé
    #>


    [CmdletBinding()]
    param
    (
        [string]$PingAddress = "8.8.8.8",

        [int]$CheckInterval = 5
    )


    while (!(test-connection $PingAddress -Count 1 -quiet))
    {
        $messageBoxText = "Veuillez vous connecter à Internet et cliquer sur OK"
        $messageBoxTitle = "Menu - Boite à outils du technicien"
        $failMessageBox = [System.Windows.MessageBox]::Show($messageBoxText,$messageBoxTitle,1,48)
        if($failMessageBox -eq 'Cancel')
        {
            exit
        }
        start-sleep $CheckInterval
    }
}

function Get-RequiredModules
{
    <#
    .SYNOPSIS
        Download les modules nécéssaires pour tous les scripts
    .DESCRIPTION
        Download depuis github vers c:\_tech\applications\source
        C'est un zip qui les contient tous qui va être dezippé sous le dossier module
    #>
    $modulesFolderPath = "$sourceFolderPath\Modules"
    $modulesFolderPathExist = test-path -Path $modulesFolderPath
    if($modulesFolderPathExist -eq $false)
    {
        $zipFileDownloadLink = 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/Modules.zip'
        $zipFile = "Modules.zip"
        Invoke-WebRequest -Uri $zipFileDownloadLink -OutFile $sourceFolderPath\$zipFile
        Expand-Archive -Path $sourceFolderPath\$zipFile -DestinationPath $sourceFolderPath -Force
        Remove-Item -Path $sourceFolderPath\$zipFile
    }
}

function Test-ScriptsAreRunning 
{
    # Loop through each script identifier and check if it's running
    foreach ($identifier in $Global:scriptIdentifiers) {
        Get-Process powershell -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Id -ne $PID) # Exclude current script's process
            {
                # Get the command line arguments of the process
                $processArguments = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine

                # Check if the process is running one of the scripts by checking the identifier
                if ($processArguments -like "*$identifier*") 
                {
                    $messageBoxText = "$identifier est en cours d'execution"
                    $messageBoxTitle = "Menu - Boite à outils du technicien"
                    $MessageBox = [System.Windows.MessageBox]::Show($messageBoxText,$messageBoxTitle,0,48)
                    return $true
                }
            }
        }
    }

    return $false
}

function Initialize-Application($appName,$githubPs1Link,$githubBatLink)
{
    <#
    .SYNOPSIS
        Configure et lance les scripts
    .DESCRIPTION
        Est utilisé lorsque qu'un bouton est cliqué
        Créer un dossier au nom de l'application
        Download le .ps1 et le .bat
        Execute le script
    .NOTES
        N'est pas dans un module, car c'est spécific au menu seulement
    #>
    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
    Get-RemoteFile "$appName.ps1" $githubPs1Link $applicationPath\$appName
    Invoke-App "RunAs$appName.bat" $githubBatLink $applicationPath\$appName
}

########################Déroulement########################
Test-InternetConnection
$Global:menuIdentifier = "Menu.ps1"
$Global:scriptIdentifiers = @(
    "Installation.ps1",
    "Diagnostique.ps1",
    "Optimisation_Nettoyage.ps1",
    "Desinfection.ps1",
    "Fix.ps1"
)
$applicationPath = "$env:SystemDrive\_Tech\Applications"
$sourceFolderPath = "$applicationPath\source"
New-Item -Path $sourceFolderPath -ItemType 'Directory' -Force
Get-RequiredModules
Import-Module "$sourceFolderPath\Modules\Verification.psm1"
Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"

$dateFile = "$sourceFolderPath\installedDate.txt"
$menuLockFile = "$sourceFolderPath\Menu.lock"

if (-not (Test-Path $dateFile)) 
{
    (Get-Date).ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::CreateSpecificCulture("fr-FR")) | Out-File -FilePath $dateFile
}

$adminStatus = Get-AdminStatus
if($adminStatus -eq $false)
{
    Restart-Elevated -Path "$env:SystemDrive\_Tech\Menu.ps1"
}

Test-ScriptInstance $menuLockFile $Global:menuIdentifier

# Check if any script is already running
if (Test-ScriptsAreRunning) 
{
    $messageBoxText = "Voulez-vous poursuivre avec l'ouverture du Menu ?"
    $messageBoxTitle = "Menu - Boite à outils du technicien"
    $messageBox = [System.Windows.MessageBox]::Show($messageBoxText,$messageBoxTitle,4,48)
    if($messageBox -eq 'no')
    {
        Remove-Item -Path $menuLockFile -Force -ErrorAction SilentlyContinue
        exit
    }
}

Import-Module "$sourceFolderPath\Modules\Runspaces.psm1"
$global:sync['flag'] = $true 

#runspaces pour le GUI
#Définitions des ScriptBlocks
    $downloadXamlFile = {
    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
    Get-RemoteFile "MainWindow.xaml" 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/MainWindow.xaml' $sourceFolderPath
    }

    $downloadBackgroundFile = {
    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
    Get-RemoteFile "Icone.ico" 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/Icone.ico' "$sourceFolderPath\Images"
    }

    $downloadIconeFile = {
    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
    Get-RemoteFile "fondpluiesize.png" 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/fondpluiesize.png' "$sourceFolderPath\Images"
    }

#Définitions des variables
$xamlPathExist = Test-Path $sourceFolderPath\MainWindow.xaml
$guiPathExist = Test-Path $sourceFolderPath\Images

$downloadXamlFileKey = "downloadXamlFile"
$downloadBackgroundFileKey = "downloadBackgroundFile"
$downloadIconeFileKey = "downloadIconeFile"

#Lancement des runspaces
if($xamlPathExist -eq $false)
{
    $global:sync['downloadXamlFileResult'] =  Start-Runspace -RunspaceKey $downloadXamlFileKey -ScriptBlock $downloadXamlFile
    Write-Host "downloadXamlFileResult"
    Get-RunspaceState $global:sync['downloadXamlFileResult']
}

if($guiPathExist -eq $false)
{
    $global:sync['downloadBackgroundFileResult'] = Start-Runspace -RunspaceKey $downloadBackgroundFileKey -ScriptBlock $downloadBackgroundFile
    Write-Host "downloadBackgroundFileResult"
    Get-RunspaceState $global:sync['downloadBackgroundFileResult']
    
    $global:sync['downloadIconeFileResult'] =  Start-Runspace -RunspaceKey $downloadIconeFileKey -ScriptBlock $downloadIconeFile
    Write-Host "downloadIconeFileResult"
    Get-RunspaceState $global:sync['downloadIconeFileResult']
}

#nettoyage des runspaces
if ($global:runspaceStates.ContainsKey('downloadXamlFile') -and $global:runspaceStates['downloadXamlFile'] -eq 'Opened') 
{
    Write-Host "downloadXamlFileResult"
    Complete-AsyncOperation -RunspaceResult $global:sync['downloadXamlFileResult']
    Close-Runspace -RunspaceResult $global:sync['downloadXamlFileResult'] -RunspaceKey $downloadXamlFileKey
    Get-RunspaceState $global:sync['downloadXamlFileResult']
}


if ($global:runspaceStates.ContainsKey('downloadBackgroundFile') -and $global:runspaceStates['downloadBackgroundFile'] -eq 'Opened') 
{
    Write-Host "downloadBackgroundFile"
    Complete-AsyncOperation -RunspaceResult $global:sync['downloadBackgroundFileResult']
    Close-Runspace -RunspaceResult $global:sync['downloadBackgroundFileResult'] -RunspaceKey $downloadBackgroundFileKey
    Get-RunspaceState $global:sync['downloadBackgroundFileResult']
}

if ($global:runspaceStates.ContainsKey('downloadIconeFile') -and $global:runspaceStates['downloadIconeFile'] -eq 'Opened') 
{
    Write-Host "downloadIconeFile"
    Complete-AsyncOperation -RunspaceResult $global:sync['downloadIconeFileResult']
    Close-Runspace -RunspaceResult $global:sync['downloadIconeFileResult'] -RunspaceKey $downloadIconeFileKey
    Get-RunspaceState $global:sync['downloadIconeFileResult']
}

########################GUI########################
Import-Module "$sourceFolderPath\Modules\WPF.psm1"
$xamlFile = "$sourceFolderPath\MainWindow.xaml"
$xamlContent = Read-XamlFileContent $xamlFile
$formatedXamlFile = Format-XamlFile $xamlContent
$xamlDoc = Convert-ToXmlDocument $formatedXamlFile
$XamlReader = New-XamlReader $xamlDoc
$window = New-WPFWindowFromXaml $XamlReader
$formControls = Get-WPFControlsFromXaml $xamlDoc $window $global:sync

#Fonctions pour runspaces
$menuChoco = {
    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\Verification.psm1"
    Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"

    function Set-MenuChoco 
    {
        $currentChocoStatus = Get-ChocoStatus

        if ($currentChocoStatus -ne $previousChocoStatus) 
        {
            $previousChocoStatus = $currentChocoStatus

            if ($currentChocoStatus -eq $true) 
            {
                $Text = "Installé"
                $ForeColor = "Green"
                $buttonVisibility = "Collapsed"
            } 
            elseif ($currentChocoStatus -eq $false) 
            {
                $Text = "Non installé"
                $ForeColor = "Red"
                $buttonVisibility = "Visible"
                $buttonContent = "Installer"
            } 
            else 
            {
                $Text = "Erreur"
                $ForeColor = "Black"
                $buttonVisibility = "Visible"
            }

            # Update the GUI with the new status details
            $global:sync["txtBlkChocoVersion"].Dispatcher.Invoke([action]{
                $global:sync["txtBlkChocoVersion"].Foreground = $ForeColor
                $global:sync["txtBlkChocoVersion"].Text = $Text
                $global:sync["btnChoco"].Visibility = $buttonVisibility
                $global:sync["btnChoco"].Content = $buttonContent
            })
        }
        return $previousChocoStatus
    }

    $previousChocoStatus = $null
    while ($global:sync['flag'] -eq $true) 
    {
        $previousChocoStatus =  Set-MenuChoco $previousChocoStatus
        Start-Sleep -s 5
    }
    return
}

$menuFTP = {
    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\Verification.psm1"

    function Set-MenuFTP 
    {
        $ftpStatus = Get-FtpStatus

        if ($ftpStatus -ne $previousFtpStatus) 
        {
            $previousFtpStatus = $ftpStatus

            if ($ftpStatus -eq $true) 
            {
                $Text = "Valide"
                $ForeColor = "Green"
            }
            else
            {
                $Text = "Injoignable"
                $ForeColor = "Red"
            }

            # Update the GUI with the new status details
            $global:sync["txtBlkFTPVersion"].Dispatcher.Invoke([action]{
                $global:sync["txtBlkFTPVersion"].Foreground = $ForeColor
                $global:sync["txtBlkFTPVersion"].Text = $Text
            })
        }
        return $previousFtpStatus
    }
    $previousFtpStatus = $null
    while ($global:sync['flag'] -eq $true) 
    {
        $previousFtpStatus = Set-MenuFTP $previousFtpStatus
        Start-Sleep -s 5
    }
    return
}

$menuGit = {
    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\Verification.psm1"

    function Set-MenuGit 
    {
        $gitStatus = Get-GitStatus

        if ($gitStatus -ne $previousGitStatus) 
        {
            $previousGitStatus = $gitStatus

            if ($gitStatus -eq $true) 
            {
                $Text = "Valide"
                $ForeColor = "Green"
            }
            else 
            {
                $Text = "Injoignable"
                $ForeColor = "Red"
            }

            # Update the GUI with the new status details
            $global:sync["txtBlkGitVersion"].Dispatcher.Invoke([action]{
                $global:sync["txtBlkGitVersion"].Foreground = $ForeColor
                $global:sync["txtBlkGitVersion"].Text = $Text
            })
        }
        return $previousGitStatus
    }
    $previousGitStatus = $null
    while ($global:sync['flag'] -eq $true) 
    {
        $previousGitStatus = Set-MenuGit $previousGitStatus
        Start-Sleep -s 5
    }
    return
}


$menuWinget = {
    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\Verification.psm1"

    function Set-MenuWinget 
    {
        $version = Get-WingetStatus

        if ($version -ne $previousWingetVersion) 
        {
            $previousWingetVersion = $version

            if ($version -eq $null) 
            {
                $Text = "Non installé"
                $ForeColor = "Red"
                $buttonVisibility = "Visible"
                $buttonContent = "Installer"
            } 
            elseif ($version -ge 1.8) 
            {
                $Text = $version
                $ForeColor = "Green"
                $buttonVisibility = "Collapsed"
                $buttonContent = $null
            } 
            elseif ($version -lt 1.8) 
            {
                $Text = $version
                $ForeColor = "Orange"
                $buttonVisibility = "Visible"
                $buttonContent = "Mettre à jour"
            }

            # Update the GUI with the new status details
            $global:sync["txtBlkWingetVersion"].Dispatcher.Invoke([action]{
                $global:sync["txtBlkWingetVersion"].Foreground = $ForeColor
                $global:sync["txtBlkWingetVersion"].Text = $Text
                $global:sync["btnWinget"].Visibility = $buttonVisibility
                $global:sync["btnWinget"].Content = $buttonContent
            })
        }
        return $previousWingetVersion
        }
    $previousWingetVersion = 0
    while ($global:sync['flag'] -eq $true) 
    {
        $previousWingetVersion = Set-MenuWinget $previousWingetVersion
        Start-Sleep -s 5 
    }
    return
}

#variable pour runspaces
$menuChocoKey = "menuChoco"
$menuWingetKey = "menuWinget"
$menuFTPKey = "menuFTP"
$menuGitKey = "menuGit"
#Lancement des runspaces
$global:sync['menuChocoResult'] = Start-Runspace -ScriptBlock $menuChoco -RunspaceKey $menuChocoKey 
Write-Host "menuChocoResult"
Get-RunspaceState $global:sync['menuChocoResult']

$global:sync['menuWingetResult'] = Start-Runspace -RunspaceKey $menuWingetKey -ScriptBlock $menuWinget
Write-Host "menuWingetResult"
Get-RunspaceState $global:sync['menuWingetResult']

$global:sync['menuFTPResult'] = Start-Runspace -RunspaceKey $menuFTPKey -ScriptBlock $menuFTP
Write-Host "menuFTPResult"
Get-RunspaceState $global:sync['menuFTPResult']

$global:sync['menuGitResult'] = Start-Runspace -RunspaceKey $menuGitKey -ScriptBlock $menuGit
Write-Host "menuGitResult"
Get-RunspaceState $global:sync['menuGitResult']

########################GUI Events########################
$Window.add_Loaded({
    $formControls.btnInstall.Add_Click({
        $window.Close()
        Initialize-Application "Installation" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Installation.ps1' 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/bat/RunAsInstallation.bat' 
    })
    $formControls.btnOptiNett.Add_Click({
        $window.Close()
        Initialize-Application "Optimisation_Nettoyage" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Optimisation_Nettoyage.ps1' 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/bat/RunAsOptimisation_Nettoyage.bat'
    })
    $formControls.btnDiagnostic.Add_Click({
        $window.Close()
        Initialize-Application "Diagnostique" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Diagnostique.ps1' 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/bat/RunAsDiagnostique.bat'
    })
    $formControls.btnDesinfection.Add_Click({
        $window.Close()
        Initialize-Application "Desinfection" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Desinfection.ps1' 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/bat/RunAsDesinfection.bat'
    })
    $formControls.btnFix.Add_Click({
        $window.Close()
        Initialize-Application "Fix" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Fix.ps1' 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/bat/RunAsFix.bat'
    })
    $formControls.btnChangeLog.Add_Click({
        $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
        Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
        Get-RemoteFile "changelog.txt" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/changelog.txt' "$env:SystemDrive\_Tech\Applications\source"
        Start-Process "$env:SystemDrive\_Tech\Applications\source\changelog.txt"
    })
    $formControls.btnForceUpdate.Add_Click({
        $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
        Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
        Get-RemoteFileForce  "Installation.ps1" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Installation.ps1' "$env:SystemDrive\_Tech\Applications\Installation"
        Get-RemoteFileForce  "Optimisation_Nettoyage.ps1" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Optimisation_Nettoyage.ps1' "$env:SystemDrive\_Tech\Applications\Optimisation_Nettoyage"
        Get-RemoteFileForce  "Diagnostique.ps1" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Diagnostique.ps1' "$env:SystemDrive\_Tech\Applications\Diagnostique"
        Get-RemoteFileForce  "Desinfection.ps1" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Desinfection.ps1' "$env:SystemDrive\_Tech\Applications\Desinfection"
        Get-RemoteFileForce  "Fix.ps1" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Fix.ps1' "$env:SystemDrive\_Tech\Applications\Fix"
        Get-RemoteFileForce "Remove.ps1" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Remove.ps1' "$env:SystemDrive\Temp"
        Get-RemoteFileForce  "Menu.ps1" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Menu.ps1' "$env:SystemDrive\_Tech"
        Invoke-WebRequest 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/Modules.zip' -OutFile "$applicationPath\source\Modules.zip" | Out-Null
        Expand-Archive "$applicationPath\source\Modules.zip" "$applicationPath\source" -Force
        Remove-Item "$applicationPath\source\Modules.zip"
	    $window.Close()
        Restart-Elevated -Path "$env:SystemDrive\_Tech\Menu.ps1"
    })
    $formControls.btnQuit.Add_Click({
        $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
        Import-Module "$sourceFolderPath\Modules\Task.psm1"
        $window.Close() 
        Invoke-Task -TaskName 'delete _tech' -ExecutedScript 'C:\Temp\Remove.bat'
    })

    $formControls.btnWinget.Add_Click({
        $installWinget = {
        $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
        Import-Module "$sourceFolderPath\Modules\Verification.psm1"
        Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
        Install-Winget
        }
        $installWingetKey = "installWinget"
        $global:sync['installWingetResult'] =  Start-Runspace -RunspaceKey $installWingetKey -ScriptBlock $installWinget
        Write-Host "installWingetResult"
        Get-RunspaceState $global:sync['installWingetResult']
   })
   
   $formControls.btnChoco.Add_Click({
        $installChoco = {
        $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
        Import-Module "$sourceFolderPath\Modules\Verification.psm1"
        Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
        Install-Choco
        }
        $installChocoKey = "installChoco"
        $global:sync['installChocoResult'] =  Start-Runspace -RunspaceKey $installChocoKey -ScriptBlock $installChoco
        Write-Host "installChocoResult"
        Get-RunspaceState $global:sync['installChocoResult']
   })     
})

$window.add_Closing({
    #variable pour runspaces
    $global:sync['flag'] = $false #stop the loop
    $desktop = [Environment]::GetFolderPath("Desktop")

    $shortcutExist = test-path "$desktop\Menu.lnk"
    $removeBatExist = test-path "$env:SystemDrive\Temp\remove.bat"
    $removePs1Exist = test-path "$env:SystemDrive\Temp\remove.ps1"

    $createShortcutKey = "createShortcut"
    $downloadRemoveScriptKey = "downloadRemoveScript"

    #scriptsblocks pour runspaces   
    $createShortcut = {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
        Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
        Add-DesktopShortcut "$desktop\Menu.lnk" "$env:SystemDrive\_Tech\Menu.bat" "$sourceFolderPath\Images\Icone.ico"   
    }

    $downloadRemoveScript = {
        $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
        Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
        Get-RemoteFile "Remove.ps1" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/Remove.ps1' "$env:SystemDrive\Temp"
        Get-RemoteFile "Remove.bat" 'https://raw.githubusercontent.com/jeremyrenaud42/Bat/main/bat/Remove.bat' "$env:SystemDrive\Temp"
    } 
    #Lancement des runspaces
    if($shortcutExist -eq $false)
    {    
    $global:sync['createShortcutResult'] =  Start-Runspace -RunspaceKey $createShortcutKey -ScriptBlock $createShortcut
    Write-Host "createShortcutResult"
    Get-RunspaceState $global:sync['createShortcutResult']
    }

    if($removeBatExist -eq $false -or $removePs1Exist -eq $false)
    {
    $global:sync['downloadRemoveScriptResult'] =  Start-Runspace -RunspaceKey $downloadRemoveScriptKey -ScriptBlock $downloadRemoveScript
    Write-Host "downloadRemoveScriptResult"
    Get-RunspaceState $global:sync['downloadRemoveScriptResult']  
    }

    #Nettoyage des runspaces
    Write-Host "menuFTPResult"
    Close-Runspace -RunspaceResult $global:sync['menuFTPResult'] -RunspaceKey $menuFTPKey
    Get-RunspaceState $global:sync['menuFTPResult']

    Write-Host "menuGitResult"
    Close-Runspace -RunspaceResult $global:sync['menuGitResult'] -RunspaceKey $menuGitKey
    Get-RunspaceState $global:sync['menuGitResult']

    Write-Host "menuChocoResult"
    Close-Runspace -RunspaceResult $global:sync['menuChocoResult'] -RunspaceKey $menuChocoKey
    Get-RunspaceState $global:sync['menuChocoResult']

    Write-Host "menuWingetResult"
    Close-Runspace -RunspaceResult $global:sync['menuWingetResult'] -RunspaceKey $menuWingetKey
    Get-RunspaceState $global:sync['menuWingetResult']

    $sourceFolderPath = "$env:SystemDrive\_Tech\Applications\source"
    Import-Module "$sourceFolderPath\Modules\Verification.psm1"
    Import-Module "$sourceFolderPath\Modules\AppManagement.psm1"
    $chocostatus = Get-ChocoStatus

    if ($global:sync['installChocoResult'].Runspace.RunspaceStateInfo.State -eq 'Opened' -and $chocostatus -eq $false)
    {
        Write-Host "En attente de l'installation de Choco"
        $installChocoKey = "installChoco"
        $messageBoxText = "En attente de l'installation de Choco"
        $messageBoxTitle = "Menu - Boite à outils du technicien"
        $chocoMessageBox = [System.Windows.MessageBox]::Show($messageBoxText,$messageBoxTitle,0,64)
        Write-Host "installChocoResult"
        Complete-AsyncOperation -RunspaceResult $global:sync['installChocoResult']
        Close-Runspace -RunspaceResult $global:sync['installChocoResult'] -RunspaceKey $installChocoKey
        Get-RunspaceState $global:sync['installChocoResult']
    }
    elseif ($global:sync['installChocoResult'].Runspace.RunspaceStateInfo.State -eq 'Opened' -and $chocostatus -eq $true)
    {
        $installChocoKey = "installChoco"
        Write-Host "installChocoResult"
        Close-Runspace -RunspaceResult $global:sync['installChocoResult'] -RunspaceKey $installChocoKey
        Get-RunspaceState $global:sync['installChocoResult']
    }

    $wingetStatus = Get-WingetStatus
    if ($global:sync['installWingetResult'].Runspace.RunspaceStateInfo.State -eq 'Opened' -and
    ([string]::IsNullOrEmpty($wingetStatus) -or $wingetStatus -le '1.8'))
    {
        Write-Host "En attente de l'installation de Winget"
        $installWingetKey = "installWinget"
        $messageBoxText = "En attente de l'installation de Winget"
        $messageBoxTitle = "Menu - Boite à outils du technicien"
        $wingetMessageBox = [System.Windows.MessageBox]::Show($messageBoxText,$messageBoxTitle,0,64)
        Write-Host "installWingetResult"
        Complete-AsyncOperation -RunspaceResult $global:sync['installWingetResult']
        Close-Runspace -RunspaceResult $global:sync['installWingetResult'] -RunspaceKey $installWingetKey
        Get-RunspaceState $global:sync['installWingetResult']
    }
    elseif ($global:sync['installWingetResult'].Runspace.RunspaceStateInfo.State -eq 'Opened' -and $wingetStatus -ge '1.8')
    {
        $installWingetKey = "installWinget"
        Write-Host "installWingetResult"
        Close-Runspace -RunspaceResult $global:sync['installWingetResult'] -RunspaceKey $installWingetKey
        Get-RunspaceState $global:sync['installWingetResult']
    }

    if ($global:runspaceStates.ContainsKey('createShortcut') -and $global:runspaceStates['createShortcut'] -eq 'Opened') 
    {
        Write-Host "createShortcutResult"
        Complete-AsyncOperation -RunspaceResult $global:sync['createShortcutResult']
        Close-Runspace -RunspaceResult $global:sync['createShortcutResult'] -RunspaceKey $createShortcutKey
        Get-RunspaceState $global:sync['createShortcutResult']
    }

    if ($global:runspaceStates.ContainsKey('downloadRemoveScript') -and $global:runspaceStates['downloadRemoveScript'] -eq 'Opened') 
    {
        Write-Host "downloadRemoveScriptResult"
        Complete-AsyncOperation -RunspaceResult $global:sync['downloadRemoveScriptResult']
        Close-Runspace -RunspaceResult $global:sync['downloadRemoveScriptResult'] -RunspaceKey $createShortcutKey
        Get-RunspaceState $global:sync['downloadRemoveScriptResult']
    }
})


$Window.add_Closed({
    Remove-Item -Path $menuLockFile -Force -ErrorAction SilentlyContinue
})

Start-WPFAppDialog $window