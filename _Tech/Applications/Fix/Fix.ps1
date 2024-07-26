#V0.5
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

$desktop = [Environment]::GetFolderPath("Desktop")
$pathfix = "$env:SystemDrive\_Tech\Applications\fix"
$pathfixSource = "$env:SystemDrive\_Tech\Applications\fix\source"
set-location $pathfix
ImportModules
CreateFolder "_Tech\Applications\fix\source"

function zipMinitool
{
    $minitoolpath = test-Path "$env:SystemDrive\Program Files\MiniTool Partition*\partitionwizard.exe"
    if($minitoolpath)
    {
        Start-Process "$env:SystemDrive\Program Files\MiniTool Partition*\partitionwizard.exe"
    }
    elseif($minitoolpath -eq $false)
    {
    Wingetinstall  
    winget install -e --id  MiniTool.PartitionWizard.Free --accept-package-agreements --accept-source-agreements --silent | Out-Null
    $minitoolpath = test-Path "$env:SystemDrive\Program Files\MiniTool Partition*\partitionwizard.exe"
        if($minitoolpath -eq $false)
        {
            Chocoinstall
            choco install partitionwizard -y | Out-Null
        }
    }
}

function Tweaking
{
    $path = Test-Path "$env:SystemDrive\_Tech\Applications\fix\Source\Tweak\Tweaking.com - Windows Repair\Repair_Windows.exe"
    if($path -eq $false)
    {
        #choco install windowsrepair , il faudra revoir le start process aussi
        Invoke-WebRequest 'https://ftp.alexchato9.com/public/file/BRP1JxyMI0edKIft_yYt2g/tweaking.com%20-%20Windows%20Repair.zip' -OutFile "$env:SystemDrive\_Tech\Applications\fix\Source\Tweak\tweaking.com - Windows Repair.zip"
        Expand-Archive "$env:SystemDrive\_Tech\Applications\fix\Source\Tweak\tweaking.com - Windows Repair.zip" "$env:SystemDrive\_Tech\Applications\fix\Source\Tweak"
        Remove-Item "$env:SystemDrive\_Tech\Applications\fix\Source\Tweak\tweaking.com - Windows Repair.zip"
        Copy-Item "$env:SystemDrive\_Tech\Applications\fix\Source\Tweak\Tweaking.com - Windows Repair" -Recurse -Destination "$env:SystemDrive\Users\$env:UserName\Desktop\Tweaking.com - Windows Repair"
        Start-Process "$env:SystemDrive\Users\$env:UserName\Desktop\Tweaking.com - Windows Repair\Repair_Windows.exe"
    }    
    elseif($path)
    {
        Start-Process "$env:SystemDrive\Users\$env:UserName\Desktop\Tweaking.com - Windows Repair\Repair_Windows.exe"
    }
}

Function menu
{
Clear-Host
write-host "[1] Fichiers corrompues" -ForegroundColor 'Cyan'
write-host "[2] Windows Tweak et Fix" -ForegroundColor 'Green'
write-host "[3] Obtenir MDP et licenses" -ForegroundColor 'darkcyan'
write-host "[4] Desinstaller les pilotes graphiques (DDU)" -ForegroundColor 'DarkGreen'
write-host "[5] Supprimer un dossier [Temp Unavailable]" -ForegroundColor 'magenta'
write-host "[6] Verifier taille des dossiers" -ForegroundColor 'red'
write-host "[7] Gerer les partitions" -ForegroundColor 'green'
write-host "[8] Reparer Internet" -ForegroundColor 'DarkRed'
write-host "[9] Recuperer des donnees [Removed]" -ForegroundColor 'Yellow'
write-host ""
write-host "[0] Quitter" -ForegroundColor 'red'
$choix = read-host "Choisissez une option" 

switch ($choix)
{
0{sortie;break}
1{UnzipApp "scripts" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/scripts.zip' "$pathfixSource"; submenuHDD;Break}
2{UnzipApp "Tweak" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/Tweak.zip' "$pathfixSource"; submenuTweak;Break}
3{UnzipApp "Sterjo" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/Sterjo.zip' "$pathfixSource"; submenuMDP;Break}
4{UnzipAppLaunch "DDU" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/DDU.zip' "Display Driver Uninstaller.exe" "$pathfixSource";Addlog "Fixlog.txt" "Désinstallation du pilote graphique avec DDU";Break}
5{UnzipAppLaunch "WiseForceDeleter" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/WiseForceDeleter.zip' "WiseDeleter.exe" "$pathfixSource";Break}
6{UnzipAppLaunch "WinDirStat" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/WinDirStat.zip' "WinDirStatPortable.exe" "$pathfixSource";Break}
7{zipMinitool;Break} 
8{UnzipAppLaunch "ComIntRep" 'https://raw.githubusercontent.com/jeremyrenaud42/Fix/main/ComIntRep.zip' "ComIntRep_X64.exe" "$pathfixSource";Addlog "Fixlog.txt" "Réparer Internet";Break}
9{menu;Break}
}
start-sleep 1
menu
}

function sortie
{
$sortie = read-host "Voulez-vous retourner au menu Principal? o/n"

    if($sortie -eq "o")
    {   
        Set-Location "$env:SystemDrive\_Tech"
        start-process "$env:SystemDrive\_Tech\Menu.bat" -verb Runas
        exit
    }
    elseif($sortie -eq "n")
    {
        #Get-Process -Name AliyunWrapExe -ErrorAction SilentlyContinue | Out-Null   
        #stop-process -Name AliyunWrapExe -ErrorAction SilentlyContinue | Out-Null #gérer easeUS removal
        Task
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
1{Start-Process "$env:SystemDrive\_Tech\Applications\fix\Source\Scripts\sfcScannow.bat";Addlog "Fixlog.txt" "Réparation des fichiers corrompus";Break}
2{Start-Process "$env:SystemDrive\_Tech\Applications\fix\Source\Scripts\DISM.bat";Addlog "Fixlog.txt" "Réparation du Windows";Break}
3{Start-Process "$env:SystemDrive\_Tech\Applications\fix\Source\Scripts\CHKDSK.BAT";Addlog "Fixlog.txt" "Réparation du HDD";Break}
4{Start-Process "$env:SystemDrive\_Tech\Applications\fix\Source\Scripts\creer_session.txt";Addlog "Fixlog.txt" "Nouvelle session créé";Break}
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
1{Start-Process "$PSScriptRoot\Source\Sterjo\SterJo_Browser_Passwords_sps\BrowserPasswords.exe";Break}
2{Start-Process "$PSScriptRoot\Source\Sterjo\SterJo_Chrome_Passwords_sps\ChromePasswords.exe";Break}
3{Start-Process "$PSScriptRoot\Source\Sterjo\Sterjo_Firefox\FirefoxPasswords.exe";Break}
4{Start-Process "$PSScriptRoot\Source\Sterjo\Sterjo_Key\KeyFinder.exe";Break}
5{Start-Process "$PSScriptRoot\Source\Sterjo\SterJo_Mail_Passwords_sps\MailPasswords.exe";Break}
6{Start-Process "$PSScriptRoot\Source\Sterjo\Sterjo_Wireless\WiFiPasswords.exe";Break}
}
Start-Sleep 1
submenuMDP
}

function submenuTweak
{
Clear-Host
write-host "[1] Fix w10"
write-host "[2] Fix w8"
write-host "[3] Ultimate Windows Tweaker W10"
write-host "[4] Ultimate Windows Tweaker W11"
write-host "[5] Tweaking Windows Repair"
write-host ""
Write-host "[0] Retour au menu precedent" -ForegroundColor 'red'
$choix = read-host "Choisissez une option"

switch ($choix)
{
0{menu}
1{Start-Process "$PSScriptRoot\Source\Tweak\FixWin10\FixWin 10.2.2.exe";Break}
2{Start-Process "$PSScriptRoot\Source\Tweak\FixWin8\FixWin 2.2.exe";break}
3{Start-Process "$PSScriptRoot\Source\Tweak\Ultimate Windows Tweaker w10\Ultimate Windows Tweaker 4.8.exe";Break}
4{Start-Process "$PSScriptRoot\Source\Tweak\Ultimate Windows Tweaker w11\Ultimate Windows Tweaker 5.0.exe";break}
5{Tweaking;Break} 
}
Start-Sleep 1
submenuTweak
}
menu