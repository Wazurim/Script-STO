function Test-Url 
{
    [CmdletBinding()]
    param 
    (
        [string]$Url
    )

    try 
    {
        Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        return $true
    }
    catch 
    {
        Write-Error "Error checking URL: $_"
        return $false
    }
}

function Get-AdminStatus
{
    $adminStatus = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator') 
    return $adminStatus
}
function Restart-Elevated
{
    <#
    .SYNOPSIS
        Relance le script en tant qu'administrateur
    .DESCRIPTION
        Si le script est pas executé en admin il va le relancer en admin et fermer l'ancien pas admin
    .PARAMETER Path
        Emplacement du fichier .ps1
    .EXAMPLE
        Restart-Elevated -Path c:\pathtomyscipt\myscript.ps1
        Va redémarer le script en admin
    #>  

    [CmdletBinding()]
    param
    (
        [string]$Path
    )


    Start-Process powershell.exe -ArgumentList ("-NoProfile -windowstyle hidden -ExecutionPolicy Bypass -File `"{0}`"" -f $Path) -Verb RunAs
    Exit
}
function Get-InternetStatus
{
   $InternetStatus =  test-connection 8.8.8.8 -Count 1 -quiet
   return $InternetStatus
}
function Get-InternetStatusLoop
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
        $result = [System.Windows.MessageBox]::Show("Veuillez vous connecter à Internet et cliquer sur OK","Menu - Boite à outils du technicien",1,48)
        if($result -eq 'Cancel')
        {
            exit
        }
            start-sleep $CheckInterval
    }
}
function Get-NugetStatus
{
    $nugetExist = test-path $env:APPDATA\NuGet
    return $nugetExist
}
function Get-WingetStatus
{
    $wingetVersion = winget -v
    $nb = $wingetVersion.substring(1)
    return $nb
}
function Get-ChocoStatus
{
    $chocoExist = Test-AppPresence "$env:SystemDrive\ProgramData\chocolatey"
    return $chocoExist
}
function Get-GitStatus
{
    $url = 'https://github.com/jeremyrenaud42/Bat'
    $test = Test-Url -url $url
    return $test
}
function Get-FtpStatus
{
    $url = 'https://ftp.alexchato9.com'
    $test = Test-Url -url $url
    return $test
}

function Test-ScriptIsRunning 
{
    param 
    (
        [string]$identifier
    )

    Get-Process powershell -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Id -ne $PID) #exclu ce script ci (ce pid ci) pour ne pas s'autodétecter
        {
            # Trouve les details du process,la command utilisée pour lancer le process (la command dans le .bat par exemple)
            #exemple : START powershell.exe -executionpolicy unrestricted -command %~d0\_TECH\Menu.ps1 -Verb runAs
            $processArguments = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine

            #Vérifie si mon identifier(Menu.ps1 dans ce cas) est contenue dans la commandline
            if ($processArguments -like "*$identifier*") 
            {
                return $true
            }
        }
    }
    return $false
}

function Test-ScriptInstance ($LockFile, $Identifier)
{
    if (Test-Path $LockFile)
    {
        $messageBoxText = "Une instance semble déjà ouvert, voulez-vous l'ouvrir à nouveau?"
        $messageBoxTitle = "Stoolbox - Boite à outils du technicien"
        $lockFileMessageBox = [System.Windows.MessageBox]::Show($messageBoxText,$messageBoxTitle,4,48)
        if($lockFileMessageBox -eq 'No')
        {
            exit
        }    
        elseif($lockFileMessageBox -eq 'Yes')
        {
            if (Test-ScriptIsRunning -identifier $Identifier) 
            {
                $lockFileMessageBox = [System.Windows.MessageBox]::Show("Une instance est deja en cours d'execution",$messageBoxTitle,0,64)
                exit
            } 
        }         
    }
    else 
    {
        New-Item -Path $LockFile -ItemType 'File' -Force 
    }
}