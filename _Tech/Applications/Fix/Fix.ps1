function Get-RequiredModules
{
    $modulesFolder = "$env:SystemDrive\_Tech\Applications\Source\modules"
    foreach ($module in Get-Childitem $modulesFolder -Name -Filter "*.psm1")
    {
        Import-Module $modulesFolder\$module
    }
}

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
write-host "[1] Fichiers corrompus [SFC/DISM/CHKDSK]" -ForegroundColor 'Cyan'
write-host "[2] Windows Tweak et Fix [Tweaking]" -ForegroundColor 'Green'
write-host "[3] Obtenir MDP et licenses [Sterjo]" -ForegroundColor 'darkcyan'
write-host "[4] Desinstaller les pilotes graphiques [DDU]" -ForegroundColor 'DarkGreen'
write-host "[5] Supprimer un dossier [WiseForceDeleter]" -ForegroundColor 'magenta'
write-host "[6] Verifier taille des dossiers [WinDirStat]" -ForegroundColor 'red'
write-host "[7] Gerer les partitions [Partition Wizard]" -ForegroundColor 'green'
write-host "[8] Reparer Internet [Internet repair]" -ForegroundColor 'DarkRed'
write-host ""
write-host "[0] Quitter" -ForegroundColor 'red'
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
write-host "[1] Sfc /scannow"
write-host "[2] DISM"
write-host "[3] CHKDSK"
write-host "[4] Creer session admin"
write-host ""
Write-host "[0] Retour au menu precedent" -ForegroundColor 'red'
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
write-host "[1] Browser"
write-host "[2] Chrome"
write-host "[3] Firefox"
write-host "[4] Keys"
write-host "[5] Mail"
write-host "[6] Wireless"
write-host ""
Write-host "[0] Retour au menu precedent" -ForegroundColor 'red'
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
write-host "[1] Fix w10"
write-host "[2] Fix w11"
write-host "[3] Ultimate Windows Tweaker W10"
write-host "[4] Ultimate Windows Tweaker W11"
write-host "[5] Tweaking Windows Repair"
write-host ""
Write-host "[0] Retour au menu precedent" -ForegroundColor 'red'
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