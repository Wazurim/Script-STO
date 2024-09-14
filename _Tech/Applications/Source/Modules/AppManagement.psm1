function Test-AppPresence 
{
    <#
   .SYNOPSIS
       VÃ©rifie si le dossier de l'application existe
   .DESCRIPTION
       Peut vÃ©rifier n'importe quel dossier ou fichier en retourant seulement vrai ou faux
   .PARAMETER PathToTest
       Le chemin du dossier ou du fichier Ã  vÃ©rifier
   .EXAMPLE
       Test-AppPresence PathToTest "C:\path\to\file_or_directory"
       Retourne Vrai si le chemin existe, sinon il retourne Faux
    .NOTES
       Va pas mal être utilité pour tester des dossiers
   #>
   [CmdletBinding()]
   param (
       [Parameter(Mandatory=$true)]
       [string]$PathToTest
   )


   return Test-Path -Path $PathToTest
}

function New-Folder 
{
    <#
   .SYNOPSIS
       Créer un dossier
   .DESCRIPTION
       Créer le dossier spécifié par le chemin mis en parametre,
       seulement si le dossier n'existe pas
   .PARAMETER FolderToCreate
       Le chemin du dossier â créer
   .EXAMPLE
       New-Folder FolderToCreate "C:\path\to\mynewdirectory"
       mynewdirectory a été créé
   #>
   [CmdletBinding()]
   param (
       [Parameter(Mandatory=$true)]
       [string]$FolderToCreate
   )


   $folderExist = Test-AppPresence -PathToTest $FolderToCreate 
   if($folderExist -eq $false)
   {
       New-Item -Path $FolderToCreate -ItemType 'Directory' -Force | Out-Null
   }
}

function Get-ZipFileBaseName 
{
    param (
        [string]$File
    )


    $extension = [System.IO.Path]::GetExtension($File)
    if ($extension -eq '.zip') 
    {
        return [System.IO.Path]::GetFileNameWithoutExtension($File)
    }  
    return $null  # Return $null if the file is not a ZIP file
}

function Get-RemoteFile
{
    <#
   .SYNOPSIS
       TÃ©lÃ©charge un fichier
   .DESCRIPTION
       TÃ©lÃ©charge un fichier seulement si il n'est pas dÃ©ja prÃ©sent,
       il va aussi crÃ©er les dossiers si nÃ©cÃ©ssaire
   .PARAMETER File
       Le nom du fichier
       test.zip
    .PARAMETER DownloadLink
       Le lien de tÃ©lÃ©chargement
       https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/test.zip
    .PARAMETER FilePath
       Le chemin du dossier des destination pour le fichier tÃ©lÃ©chargÃ©
       $applicationPath\Source
   .EXAMPLE
       Get-RemoteFile "fondpluiesize.gif" 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/fondpluiesize.gif' "$applicationPath\Source\Images"
       Il va vÃ©rifier si C:\_tech\Applications\Source\Images\fondpluiesize.gif existe, s'il n'existe pas,
       il va CrÃ©er le dossier au besoin et tÃ©lÃ©charger le fichier a C:\_tech\Applications\Source\Images. 
       rÃ©sultat : fondpluiesize.gif a Ã©tÃ© tÃ©lÃ©chargÃ© a l'emplacement suivant "C:\_tech\Applications\Source\Images"
    .NOTES
       On n'inclus pas le fichier $file directement dans $filepath pour pouvoir utilser New-Folder
   #>
   [CmdletBinding()]
   param (
       [Parameter(Mandatory=$true)]
       [string]$File,
       [Parameter(Mandatory=$true)]
       [string]$DownloadLink,
       [Parameter(Mandatory=$true)]
       [string]$FilePath
   )

   $zipBaseName = Get-ZipFileBaseName -File $File
   if ($zipBaseName) 
   {
     $fileExist = Test-AppPresence -PathToTest "$FilePath\$zipBaseName"
       if($fileExist -eq $false)
       {
          New-Folder -FolderToCreate $FilePath
          Invoke-WebRequest -Uri $DownloadLink -OutFile "$FilePath\$File" -TimeoutSec 5 -UseBasicParsing
          Expand-ZipFile -ZipFile $File -Folderpath $FilePath
       }
   }
   else
   {
      $fileExist = Test-AppPresence -PathToTest "$FilePath\$File"
      if($fileExist -eq $false)
      {
          New-Folder -FolderToCreate $FilePath
          Invoke-WebRequest -Uri $DownloadLink -OutFile "$FilePath\$File"
      }
   }
}

function Get-RemoteFileForce
{
    <#
   .SYNOPSIS
       Télécharge un fichier
   .DESCRIPTION
       Télécharge un fichier seulement s'il est déja présent
   .PARAMETER File
       Le nom du fichier
       test.zip
    .PARAMETER DownloadLink
       Le lien de téléchargement
       https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/test.zip
    .PARAMETER FilePath
       Le chemin du dossier des destination pour le fichier téléchargé
       $applicationPath\Source
   .EXAMPLE
       Get-RemoteFile "fondpluiesize.gif" 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/fondpluiesize.gif' "$applicationPath\Source\Images"
       Il va vérifier si C:\_tech\Applications\Source\Images\fondpluiesize.gif existe, s'il exsite,
       télécharger/écrase le fichier présent C:\_tech\Applications\Source\Images. 
       résultat : fondpluiesize.gif a été téléchargé a l'emplacement suivant "C:\_tech\Applications\Source\Images"
    .NOTES
       On pourrait inclure le file direct dans le path, mais pour que sa est la même nomenclature que Get-Remotefile
       on le met pareille pour garder sa simple
   #>
   [CmdletBinding()]
   param (
       [Parameter(Mandatory=$true)]
       [string]$File,
       [Parameter(Mandatory=$true)]
       [string]$DownloadLink,
       [Parameter(Mandatory=$true)]
       [string]$FilePath
   )
   $fileExist = Test-AppPresence -PathToTest $FilePath\$File
   if($fileExist -eq $true)
   {
       Invoke-WebRequest -Uri $DownloadLink -OutFile "$FilePath\$File" -TimeoutSec 5 -UseBasicParsing
   }
}
function Start-App
{
    <#
    .SYNOPSIS
       Execute un fichier
   .DESCRIPTION
       Excute un fichier en admin
   .PARAMETER ExeFile
       Le nom du fichier a éxécuter
       test.exe ou test
    .PARAMETER FilePath
       Le chemin du fichier a éxécuté
       $applicationPath\Source
   .EXAMPLE
       Start-App "test.exe" "$applicationPath\Source"
       Il va executer le fichier $applicationPath\Source\test.exe 
   .NOTES
       Pas obligé d'avoir l'extension (.exe)
   #>
   [CmdletBinding()]
   param (
       [Parameter(Mandatory=$true)]
       [string]$ExeFile,
       [Parameter(Mandatory=$true)]
       [string]$FilePath
   )


   Start-Process -FilePath "$FilePath\$ExeFile" -verb runas
}

function Invoke-App
{
     <#
    .SYNOPSIS
       Télécharge et Execute un fichier
   .DESCRIPTION
       Télécharge et Execute Excute un fichier en admin
       Télécharge un fichier seulement si il n'est pas déja présent,
       il va aussi créer les dossiers si nécéssaire
   .PARAMETER ExeFile
       Le nom du fichier a éxécuter
       test.exe ou test
    .PARAMETER DownloadLink
        Le lien de téléchargement
       https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/test.zip
    .PARAMETER FilePath
       Le chemin du fichier a éxécuté
       $applicationPath\Source
   .EXAMPLE
       Invoke-App "test.exe" https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/test.zip.exe "$applicationPath\Source"
       Il va télécharger et executer le fichier $applicationPath\Source\test.exe 
   .NOTES
       Pas obligé d'avoir l'extension (.exe)
   #>
   [CmdletBinding()]
   param (
       [Parameter(Mandatory=$true)]
       [string]$ExeFile,
       [Parameter(Mandatory=$true)]
       [string]$DownloadLink,
       [Parameter(Mandatory=$true)]
       [string]$FilePath
   )


   Get-RemoteFile -File $ExeFile -DownloadLink $DownloadLink -FilePath $FilePath
   $zipBaseName = Get-ZipFileBaseName -File $ExeFile
   if ($zipBaseName) 
   {
      Start-App -ExeFile $zipBaseName -FilePath $FilePath\$zipBaseName
   }
   else
   {
     Start-App -ExeFile $ExeFile -FilePath $FilePath
   }  
}

function Expand-ZipFile
{
   [CmdletBinding()]
   param (
       [Parameter(Mandatory=$true)]
       [string]$ZipFile,
       [Parameter(Mandatory=$true)]
       [string]$Folderpath
   )
   Expand-Archive -Path "$Folderpath\$ZipFile" -DestinationPath $Folderpath
   Remove-Item -Path "$Folderpath\$ZipFile" -Force
}

function Remove-App($path)
{
   Remove-Item $path -Force | out-null
}

function Install-Choco
{
   $progressPreference = 'SilentlyContinue' #cache la barre de progres
   $chocoExist = Test-AppPresence "$env:SystemDrive\ProgramData\chocolatey"
   if($chocoExist -eq $false)
   {
       Invoke-WebRequest https://chocolatey.org/install.ps1 -TimeoutSec 5 -UseBasicParsing | Invoke-Expression | Out-Null #install le module choco
       $env:Path += ";$env:SystemDrive\ProgramData\chocolatey" #permet de pouvoir installer les logiciels sans reload powershell
   }
}

function Install-Winget
{
   $progressPreference = 'SilentlyContinue' #cache la barre de progres
   $wingetVersion = winget -v
   $nb = $wingetVersion.substring(1)
   if($nb -le '1.8')
   {  
       $vclibsUWPVersin = (Get-AppxPackage Microsoft.VCLibs.140.00.UWPDesktop).version
       if($vclibsUWPVersin -lt '14.0.30704.0')
       {
            Get-RemoteFile "Microsoft.VCLibs.140.00.UWPDesktop_14.0.30704.0_x64__8wekyb3d8bbwe.Appx" 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/Microsoft.VCLibs.140.00.UWPDesktop_14.0.30704.0_x64__8wekyb3d8bbwe.Appx' "$env:SystemDrive\_Tech\Applications\Source"
            Add-AppxPackage -path "$env:SystemDrive\_Tech\Applications\Source\Microsoft.VCLibs.140.00.UWPDesktop_14.0.30704.0_x64__8wekyb3d8bbwe.Appx" -ForceApplicationShutdown
       }
       $VCLibsExist = (Get-AppxPackage Microsoft.VCLibs.140.00).name
       if($null -eq $VCLibsExist)
       {
           Add-AppxPackage https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
       }
       $UIXamlExist = (Get-AppxPackage Microsoft.UI.Xaml.2.8).name
       if($null -eq $UIXamlExist )
       {
           Get-RemoteFile "Microsoft.UI.Xaml.2.8.x64.appx" 'https://raw.githubusercontent.com/jeremyrenaud42/Menu/main/Microsoft.UI.Xaml.2.8.x64.appx' "$env:SystemDrive\_Tech\Applications\Source"
           Add-AppxPackage -path "$env:SystemDrive\_Tech\Applications\Source\Microsoft.UI.Xaml.2.8.x64.appx" -ForceApplicationShutdown
       }
       Get-RemoteFile "winget.msixbundle" 'https://aka.ms/getwinget' "$env:SystemDrive\_Tech\Applications\Source"
       Add-AppxPackage -path "$env:SystemDrive\_Tech\Applications\Source\winget.msixbundle" -ForceApplicationShutdown
   }
}

function Install-Nuget
{
   get-packageprovider -Name Nuget -Force #vÃ©rifie et install si false
   $nugetModuleExist = Test-AppPresence "C:\Program Files\WindowsPowerShell\Modules\NuGet"
   if($nugetModuleExist -eq $false)
   {
       Install-Module -Name NuGet -Force #pour use avec PowerShell
   }
}

function Add-DesktopShortcut($shortcutPath,$targetPath,$iconLocation)
{
   $shortcutExist = Test-AppPresence $shortcutPath
   if($shortcutExist -eq $false)
   {
   $WshShell = New-Object -comObject WScript.Shell
   $Shortcut = $WshShell.CreateShortcut($shortcutPath)
   $Shortcut.TargetPath = $targetPath
   $Shortcut.IconLocation = $iconLocation
   $Shortcut.Save()
   }
}