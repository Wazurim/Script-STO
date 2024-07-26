function VerifRestorepoint
{
    $listrestorepoint = Get-ComputerRestorePoint | Select-Object Description
    if($listrestorepoint -match "STO")
    {
        [System.Windows.MessageBox]::Show("Point de restauration cree avec succes","Point de restauration",0) | Out-Null
    }
    else 
    {
        [System.Windows.MessageBox]::Show("Erreur lors de la creation du point de restauration","Point de restauration",0) | Out-Null
    }
}
function CreateRestorePoint
{
    #REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /V "SystemRestorePointCreationFrequency" /T REG_DWORD /D 0 /F
    Enable-ComputerRestore -Drive "$env:SystemDrive" 
    Checkpoint-Computer -Description "STO" -RestorePointType "MODIFY_SETTINGS"
    VerifRestorepoint
}
