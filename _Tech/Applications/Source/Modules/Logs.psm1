function AddLog ($filename,$message)
{
    $logfilepath = ".\Source\$filename" #chemin du fichier texte
    (Get-Date).ToString() + " - " + $message + "`r`n" | Out-file -filepath $logfilepath -append -force
}

function AddErrorsLog ($filename,$message)
{
    $errorslogfilepath = ".\Source\$filename" #chemin du fichier texte
    (Get-Date).ToString() + " - " + $message + "`r`n" | Out-file -filepath $errorslogfilepath -append -force #ajoute le texte dans le fichier
}

function RemoveLog($filename)
{
    $logfilepath = ".\Source\$filename" #chemin du fichier texte 
    Remove-Item $logfilepath -Force | out-null
}

function CopyLog($filename,$destination)
{
    Copy-Item ".\Source\$filename" -destination $destination -Force | out-null 
}