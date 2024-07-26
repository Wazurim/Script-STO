function VerifPresenceApp($appPath)
{
    $appExistStatus = $false
    $appExist = Test-Path $appPath
    if($appExist)
    {
       $appExistStatus = $true 
    } 
    return $appExistStatus
}

function CreateFolder($folder) 
{
    $folderPath = "$env:SystemDrive\$folder"
    $folderExist = VerifPresenceApp $folderPath 
    if($folderExist -eq $false)
    {
        New-Item $folderPath -ItemType 'Directory' -Force | Out-Null
    }
}

function DownloadFile($file,$downloadLink,$path)
{
    $appExist = VerifPresenceApp "$path\$file"
    if($appExist -eq $false)
    {
        Invoke-WebRequest $downloadLink -OutFile "$path\$file"
    }
}

function StartExeFile($exe,$path)
{
    Start-Process "$path\$exe" -verb runas
}

function DownloadLaunchApp($exe,$downloadLink,$path)
{
    DownloadFile $exe $downloadLink $path
    StartExeFile $exe $path
}

function UnzipApp($appFolder,$downloadLink,$path)
{
    $appExist = VerifPresenceApp "$path\$appFolder"
    $zipFile = "$path\$appFolder.zip"
    if($appExist -eq $false)
    {
        Invoke-WebRequest $downloadLink -OutFile $zipFile
        Expand-Archive $zipFile $path
        Remove-Item $zipFile
    }
}

function StartApp($appExe,$appFolder,$path)
{
    Start-Process "$path\$appFolder\$appExe" -verb runas
}

function UnzipAppLaunch($appFolder,$downloadLink,$appExe,$path)
{
    UnzipApp $appFolder $downloadLink $path
    StartApp $appExe $appFolder $path
} 

function RemoveApp($path)
{
    Remove-Item $path -Force | out-null
}

function Chocoinstall
{
    $progressPreference = 'SilentlyContinue' #cache la barre de progres
    $chocoExist = VerifPresenceApp "$env:SystemDrive\ProgramData\chocolatey"
    if($chocoExist -eq $false)
    {
        Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression | Out-Null #install le module choco
        $env:Path += ";$env:SystemDrive\ProgramData\chocolatey" #permet de pouvoir installer les logiciels sans reload powershell
    }
}

function Wingetinstall
{
    $progressPreference = 'SilentlyContinue' #cache la barre de progres
    $wingetVersion = winget -v
    $nb = $wingetVersion.substring(1) 
    if($nb -le '1.8')
    {  
        $VCLibsExist = (Get-AppxPackage Microsoft.VCLibs.140.00).name
        if($VCLibsExist -eq $false)
        {
            Add-AppxPackage https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
        }
        $UIXamlExist = (Get-AppxPackage Microsoft.UI.Xaml.2.8).name
        if($UIXamlExist-eq $false)
        {
            Install-Package Microsoft.UI.Xaml -Source  https://www.nuget.org/api/v2 -force
        }
        DownloadFile "winget.msixbundle" 'https://aka.ms/getwinget' "$env:SystemDrive\_Tech\Applications\Source"
        Add-AppxPackage -path "$env:SystemDrive\_Tech\Applications\Source\winget.msixbundle" -ForceApplicationShutdown
    }
}

function Nugetinstall
{
    get-packageprovider -Name Nuget -Force #vérifie et install si false
    $nugetModuleExist = VerifPresenceApp "C:\Program Files\WindowsPowerShell\Modules\NuGet"
    if($nugetModuleExist -eq $false)
    {
        Install-Module -Name NuGet -Force #pour use avec PowerShell
    }
}

function CreateDesktopShortcut($shortcutPath,$targetPath,$iconLocation)
{
    $shortcutExist = VerifPresenceApp $shortcutPath
    if($shortcutExist -eq $false)
    {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $targetPath
    $Shortcut.IconLocation = $iconLocation
    $Shortcut.Save()
    }
}