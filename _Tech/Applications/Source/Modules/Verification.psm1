# Fonction pour tester l'URL
function Test-Url($url)
{
 $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 
        if ($response.StatusCode -eq 200) 
        {
            return $true
        } 
        else 
        {
            return $false
        } 
    catch 
    {
        return $false
    }
}

function CheckAdminStatus
{
    $adminStatus = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator') 
    return $adminStatus
}
function CheckInternetStatus
{
   $InternetStatus =  test-connection 8.8.8.8 -Count 1 -quiet
   return $InternetStatus
}
function CheckInternetStatusLoop
{
    while (!(test-connection 8.8.8.8 -Count 1 -quiet)) #Ping Google et recommence jusqu'a ce qu'il y est internet
    {
    [Microsoft.VisualBasic.Interaction]::MsgBox("Veuillez vous connecter à Internet et cliquer sur OK",'OKOnly,SystemModal,Information', "Installation Windows") | Out-Null
    start-sleep 5
    }
}
function CheckNugetStatus
{
    $nugetStatus = Get-PackageProvider -name Nuget | Select-Object -expand name
    return $nugetStatus
}
function CheckWingetStatus
{
    $wingetVersion = winget -v
    $nb = $wingetVersion.substring(1)
    return $nb
}
function CheckChocoStatus
{
    $chocoExist = VerifPresenceApp "$env:SystemDrive\ProgramData\chocolatey"
    return $chocoExist
}
function CheckGitStatus
{
    $url = 'https://github.com/jeremyrenaud42/Bat'
    $test = Test-Url -url $url
    return $test
}
function CheckFtpStatus
{
    $url = 'https://ftp.alexchato9.com'
    $test = Test-Url -url $url
    return $test
}