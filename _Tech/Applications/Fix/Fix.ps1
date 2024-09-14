function Get-RequiredModules
{
    $modulesFolder = "$env:SystemDrive\_Tech\Applications\Source\modules"
    foreach ($module in Get-Childitem $modulesFolder -Name -Filter "*.psm1")
    {
        Import-Module $modulesFolder\$module
    }
}


#Theme:
# 0 : STO
# 1 : Classic 
# 2 : Halloween
# 3 : Christmas
# 4 : Ocean

$theme = 1
#STO:
if($theme -eq 0){
    $backgroundColor = "Black"
    $colordefault = "DarkRed"
    $coloraccent = "White"
    $colorfolder = "yellow"
    $colorquit = "red"
}
#Classic:
elseif($theme -eq 1){
    $backgroundColor = "Black"
    $colordefault = "Cyan"
    $coloraccent = "magenta"
    $colorfolder = "green"
    $colorquit = "Darkred"
}
#Halloween:
elseif($theme -eq 2){
    $backgroundColor = "Black"
    $colordefault = "yellow"
    $coloraccent = "red"
    $colorfolder = "DarkGreen"
    $colorquit = "Darkred"
}
#Christmas:
elseif($theme -eq 3){
    $backgroundColor = "Black"
    $colordefault = "Darkred"
    $coloraccent = "White"
    $colorfolder = "Darkgreen"
    $colorquit = "Cyan"
}
#Ocean:
elseif($theme -eq 4){
    $backgroundColor = "DarkMagenta"
    $colordefault = "Gray"
    $coloraccent = "Cyan"
    $colorfolder = "Blue"
    $colorquit = "DarkCyan"
}
else{
    $backgroundColor = "Black"
    $colordefault = "white"
    $coloraccent = "white"
    $colorfolder = "white"
    $colorquit = "Darkred"
}
#change color
$Host.UI.RawUI.BackgroundColor = $backgroundColor
$Host.UI.RawUI.ForegroundColor = $colordefault


Get-RequiredModules
$desktop = [Environment]::GetFolderPath("Desktop")
$pathFix = "$env:SystemDrive\_Tech\Applications\fix"
set-location $pathFix
$pathFixSource = "$env:SystemDrive\_Tech\Applications\fix\source"
New-Folder $pathFixSource
$applicationPath = "$env:SystemDrive\_Tech\Applications"
$sourceFolderPath = "$applicationPath\source"
$logFileName = Initialize-LogFile $pathFixSource
$fixLockFile = "$sourceFolderPath\Fix.lock"
$adminStatus = Get-AdminStatus
if($adminStatus -eq $false)
{
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f "$pathFix\Fix.ps1") -Verb RunAs
    Exit
}
$Global:fixIdentifier = "Fix.ps1"
Test-ScriptInstance $fixLockFile $Global:fixIdentifier

function zipMinitool
{
    $minitoolpath = test-Path "$env:SystemDrive\Program Files\MiniTool Partition*\partitionwizard.exe"
    if($minitoolpath)
    {
        Start-Process "$env:SystemDrive\Program Files\MiniTool Partition*\partitionwizard.exe"
    }
    elseif($minitoolpath -eq $false)
    {
    Install-Winget  
    winget install -e --id  MiniTool.PartitionWizard.Free --accept-package-agreements --accept-source-agreements --silent | Out-Null
    $minitoolpath = test-Path "$env:SystemDrive\Program Files\MiniTool Partition*\partitionwizard.exe"
        if($minitoolpath -eq $false)
        {
            Install-Choco
            choco install partitionwizard -y | Out-Null
        }
    }
}

function Tweaking
{
    $path = Test-Path "$pathFixSource\Tweak\Tweaking.com - Windows Repair\Repair_Windows.exe"
    if($path -eq $false)
    {
        #choco install windowsrepair , il faudra revoir le start process aussi
        Invoke-WebRequest 'https://ftp.alexchato9.com/public/file/BRP1JxyMI0edKIft_yYt2g/tweaking.com%20-%20Windows%20Repair.zip' -OutFile "$pathFixSource\Tweak\tweaking.com - Windows Repair.zip"
        Expand-Archive "$pathFixSource\Tweak\tweaking.com - Windows Repair.zip" "$pathFixSource\Tweak"
        Remove-Item "$pathFixSource\Tweak\tweaking.com - Windows Repair.zip"
        Copy-Item "$pathFixSource\Tweak\Tweaking.com - Windows Repair" -Recurse -Destination "$desktop\Tweaking.com - Windows Repair"
        Start-Process "$desktop\Tweaking.com - Windows Repair\Repair_Windows.exe"
    }    
    elseif($path)
    {
        Start-Process "$desktop\Tweaking.com - Windows Repair\Repair_Windows.exe"
    }
}

Function menu
{
Clear-Host
write-host "=========================================================================================="
write-host "  + [#] +           Programme                 +              Description               +  "-ForegroundColor $coloraccent
write-host "  + --- + ----------------------------------- + -------------------------------------- +  " 
write-host "  + [1] + SFC/DISM/CHKDSK        [sous-menu]  + Fichiers corrompus                     +  " -ForegroundColor $colorfolder
write-host "  + [2] + Windows tweak          [sous-menu]  + Windows Tweak et Fix                   +  " -ForegroundColor $colorfolder
write-host "  + [3] + Sterjo MDP recovery    [sous-menu]  + Obtenir MDP et licences                +  " -ForegroundColor $colorfolder
write-host "  + [4] + DDU                                 + Desinstaller les pilotes graphiques    +  " 
write-host "  + [5] + WiseForceDeleter                    + Supprimer un dossier/fichier           +  " -ForegroundColor $coloraccent
write-host "  + [6] + WinDirStat                          + Verifier taille des dossiers           +  " 
write-host "  + [7] + Partition Wizard                    + Gerer les partitions                   +  " -ForegroundColor $coloraccent
write-host "  + [8] + Internet repair                     + Reparer Internet                       +  " 
write-host "  + --- + ----------------------------------- + -------------------------------------- +  " -ForegroundColor $coloraccent
write-host "  + [0] + Quitter                             + Fermer ou revenir au menu              +  " -ForegroundColor $colorquit
write-host "=========================================================================================="
$choix = read-host "Choisissez une option" 

switch ($choix)
{
0{sortie;break}
1{Get-RemoteFile "scripts.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/scripts.zip' "$pathFixSource"; submenuHDD;Break}
2{Get-RemoteFile "Tweak.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/Tweak.zip' "$pathFixSource"; submenuTweak;Break}
3{Get-RemoteFile "Sterjo.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/Sterjo.zip' "$pathFixSource"; submenuMDP;Break}
4{Invoke-App "Display Driver Uninstaller.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/Display Driver Uninstaller.zip' "$pathFixSource";Add-Log $logFileName "Désinstallation du pilote graphique avec DDU";Break}
5{Invoke-App "WiseForceDeleterPortable.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/WiseForceDeleterPortable.zip' "$pathFixSource";Break}
6{Invoke-App "WinDirStatPortable.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/WinDirStatPortable.zip' "$pathFixSource";Break}
7{zipMinitool;Break} 
8{Invoke-App "ComIntRep_X64.zip" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/ComIntRep_X64.zip' "$pathFixSource";Add-Log $logFileName "Réparer Internet";Break}
}
start-sleep 1
menu
}

function sortie
{
$sortie = read-host "Voulez-vous retourner au menu Principal? o/n [n = Suppression]"

    if($sortie -eq "o")
    {   
        Set-Location "$env:SystemDrive\_Tech"
        start-process "$env:SystemDrive\_Tech\Menu.bat" -verb Runas
        Remove-Item -Path $fixLockFile -Force -ErrorAction SilentlyContinue
        exit
    }
    elseif($sortie -eq "n")
    {
        Remove-Item -Path $fixLockFile -Force -ErrorAction SilentlyContinue
        Invoke-Task -TaskName 'delete _tech' -ExecutedScript 'C:\Temp\Remove.bat'
        exit
    }
    else 
    {
        sortie
    }
}

function submenuHDD
{
Clear-Host
write-host "================================================="
write-host "  + [#] +           SFC/DISM/CHKDSK           +  "-ForegroundColor $coloraccent
write-host "  + --- + ----------------------------------- +  " 
write-host "  + [1] + Sfc /scannow                        +  " -ForegroundColor $coloraccent
write-host "  + [2] + DISM                                +  " 
write-host "  + [3] + CHKDSK                              +  " -ForegroundColor $coloraccent
write-host "  + [4] + Creer session admin                 +  " 
write-host "  + --- + ----------------------------------- +  " -ForegroundColor $coloraccent
write-host "  + [0] + Retour au menu precedent            +  " -ForegroundColor $colorquit
write-host "================================================="
$choix = read-host "Choisissez une option"

switch ($choix)
{
0{menu}
1{Start-Process "$pathFixSource\Scripts\sfcScannow.bat";Add-Log $logFileName "Réparation des fichiers corrompus";Break}
2{Start-Process "$pathFixSource\Scripts\DISM.bat";Add-Log $logFileName "Réparation du Windows";Break}
3{Start-Process "$pathFixSource\Scripts\CHKDSK.BAT";Add-Log $logFileName "Réparation du HDD";Break}
4{Start-Process "$pathFixSource\Scripts\creer_session.txt";Add-Log $logFileName "Nouvelle session créé";Break}
}
start-sleep 1
submenuHDD
}

function submenuMDP
{

Clear-Host
write-host "================================================="
write-host "  + [#] +           Sterjo MDP recovery       +  "-ForegroundColor $coloraccent
write-host "  + --- + ----------------------------------- +  " 
write-host "  + [1] + Browser                             +  " -ForegroundColor $coloraccent
write-host "  + [2] + Chrome                              +  " 
write-host "  + [3] + Firefox                             +  " -ForegroundColor $coloraccent
write-host "  + [4] + Keys                                +  " 
write-host "  + [5] + Mail                                +  " -ForegroundColor $coloraccent
write-host "  + [6] + Wireless                            +  " 
write-host "  + --- + ----------------------------------- +  " -ForegroundColor $coloraccent
write-host "  + [0] + Retour au menu precedent            +  " -ForegroundColor $colorquit
write-host "================================================="
$choix = read-host "Choisissez une option"

switch ($choix)
{
0{menu}
1{Start-Process "$pathFixSource\Sterjo\SterJo_Browser_Passwords_sps\BrowserPasswords.exe";Break}
2{Start-Process "$pathFixSource\Sterjo\SterJo_Chrome_Passwords_sps\ChromePasswords.exe";Break}
3{Start-Process "$pathFixSource\Sterjo\Sterjo_Firefox\FirefoxPasswords.exe";Break}
4{Start-Process "$pathFixSource\Sterjo\Sterjo_Key\KeyFinder.exe";Break}
5{Start-Process "$pathFixSource\Sterjo\SterJo_Mail_Passwords_sps\MailPasswords.exe";Break}
6{Start-Process "$pathFixSource\Sterjo\Sterjo_Wireless\WiFiPasswords.exe";Break}
}
Start-Sleep 1
submenuMDP
}

function submenuTweak
{
Clear-Host
write-host "================================================="
write-host "  + [#] +           Windows Tweak et Fix      +  "-ForegroundColor $coloraccent
write-host "  + --- + ----------------------------------- +  " 
write-host "  + [1] + Fix w10                             +  " -ForegroundColor $coloraccent
write-host "  + [2] + Fix w11                             +  " 
write-host "  + [3] + Ultimate Windows Tweaker W10        +  " -ForegroundColor $coloraccent
write-host "  + [4] + Ultimate Windows Tweaker W11        +  " 
write-host "  + [5] + Tweaking Windows Repair             +  " -ForegroundColor $coloraccent
write-host "  + --- + ----------------------------------- +  " 
write-host "  + [0] + Retour au menu precedent            +  " -ForegroundColor $colorquit
write-host "================================================="
$choix = read-host "Choisissez une option"

switch ($choix)
{
0{menu}
1{Start-Process "$pathFixSource\Tweak\FixWin10\FixWin 10.2.2.exe";Break}
2{Start-Process "$pathFixSource\Tweak\FixWin11\FixWin 11.1.exe";break}
3{Start-Process "$pathFixSource\Tweak\Ultimate Windows Tweaker w10\Ultimate Windows Tweaker 4.8.exe";Break}
4{Start-Process "$pathFixSource\Tweak\Ultimate Windows Tweaker w11\Ultimate Windows Tweaker 5.1.exe";break}
5{Tweaking;Break} 
}
Start-Sleep 1
submenuTweak
}
menu