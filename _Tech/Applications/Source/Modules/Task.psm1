function Invoke-Task
{
    [CmdletBinding()]
    param
    (
        [string]$Taskname,
        [string]$ExecutedScript
    )


    $taskExist = Get-ScheduledTask $Taskname | Select-Object -expand state -ErrorAction SilentlyContinue
    if($taskExist -match 'Ready')
    {
        Unregister-ScheduledTask -TaskName $Taskname -Confirm:$false
    }
        $action = New-ScheduledTaskAction -Execute $ExecutedScript
        $seconds = '05'
        $trigger = New-ScheduledTaskTrigger -At (Get-Date).AddSeconds($seconds) -Once
        $currentUser = whoami
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -Compatibility Win8 #si ordi éteint, le refait après 10 minutes
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        Register-ScheduledTask -TaskName $Taskname -InputObject $task
}