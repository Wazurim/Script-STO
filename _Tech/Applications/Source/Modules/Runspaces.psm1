# Synchronized hashtable for cross-runspace communication
$global:sync = [Hashtable]::Synchronized(@{})
# Global hashtable to keep track of runspace states
$global:runspaceStates = [Hashtable]::Synchronized(@{})

function Start-Runspace {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RunspaceKey,
        
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ScriptBlock
    )
    
    # Check if the runspace is already opened
    if ($global:runspaceStates.ContainsKey($RunspaceKey)) {
        $state = $global:runspaceStates[$RunspaceKey]
        if ($state -eq 'Opened') {
            Write-Host "Runspace with key '$RunspaceKey' is already opened."
            return
        }
    }
    
    # Create and configure the runspace
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    
    # Set the sync hashtable in the runspace's session state
    $runspace.SessionStateProxy.SetVariable("sync", $global:sync)
    
    # Create the PowerShell instance
    $powerShell = [PowerShell]::Create()
    # Add the script block to the PowerShell instance
    $powerShell.AddScript($ScriptBlock)
    # Associate the PowerShell instance with the runspace
    $powerShell.Runspace = $runspace

    # Start the asynchronous invocation
    $asyncResult = $powerShell.BeginInvoke()
    
    # Update the global state tracker
    $global:runspaceStates[$RunspaceKey] = 'Opened'

    # Return the AsyncResult and the Runspace in a custom object
    return @{ AsyncResult = $asyncResult; PowerShellInstance = $powerShell; Runspace = $runspace }
}

function Get-RunspaceState($RunspaceResult)
{
    if ($RunspaceResult.Runspace.RunspaceStateInfo.State -eq 'Opened') {
        Write-Host "Runspace started successfully and is running."
    } elseif ($RunspaceResult.Runspace.RunspaceStateInfo.State -eq 'Closed') {
        Write-Host "Runspace is closed."
    } elseif ($RunspaceResult.Runspace.RunspaceStateInfo.State -eq 'Disconnected') {
        Write-Host "Runspace is disconnected."
    } elseif ($RunspaceResult.Runspace.RunspaceStateInfo.State -eq 'Broken') {
        Write-Host "Runspace is broken."
    } else {
        Write-Host "Runspace is in an unknown state: $($RunspaceResult.Runspace.RunspaceStateInfo.State)"
    }
}

function Complete-AsyncOperation {
    param (
        [Parameter(Mandatory=$true)]
        [pscustomobject]$RunspaceResult
    )

    # Ensure EndInvoke is called to complete the asynchronous operation
    if ($RunspaceResult.AsyncResult) {
        try {
            $RunspaceResult.PowerShellInstance.EndInvoke($RunspaceResult.AsyncResult)
        } catch {
            Write-Error "Failed to complete asynchronous operation: $_"
        }
    }
}

function Close-Runspace {
    param (
        [Parameter(Mandatory=$true)]
        [pscustomobject]$RunspaceResult,
        [Parameter(Mandatory=$true)]
        [string]$RunspaceKey
    )

    # Close the runspace to stop any active operations
    if ($RunspaceResult.Runspace) {
        try {
            $RunspaceResult.Runspace.Close()
        } catch {
            Write-Error "Failed to close runspace: $_"
        }
    }

     #Update the global state tracker
    if ($global:runspaceStates.ContainsKey($RunspaceKey)) {
        $global:runspaceStates[$RunspaceKey] = 'Closed'
    } else {
        Write-Warning "RunspaceKey '$RunspaceKey' not found in global state tracker."
    }
    # Dispose of the PowerShell instance and runspace
    if ($RunspaceResult.PowerShellInstance) {
        try {
            $RunspaceResult.PowerShellInstance.Dispose()
        } catch {
            Write-Error "Failed to dispose of PowerShell instance: $_"
        }
    }

    if ($RunspaceResult.Runspace) {
        try {
            $RunspaceResult.Runspace.Dispose()
        } catch {
            Write-Error "Failed to dispose of runspace: $_"
        }
    }
}


function Start-AsyncTask {
    param (
        [ScriptBlock]$ScriptBlock
    )

# CrÃ©e une instance de PowerShell
$runspace = [powershell]::Create().AddScript($ScriptBlock)
# DÃ©marre l'exÃ©cution asynchrone
$asyncResult = $runspace.BeginInvoke()
# Retourne l'AsyncResult et le Runspace dans un objet personnalisÃ©
return @{ AsyncResult = $asyncResult; Runspace = $runspace }
}

# Fonction pour vÃ©rifier si la tÃ¢che est terminÃ©e
function Wait-ForTaskCompletion {
    param (
        [Parameter(Mandatory=$true)]
        [System.IAsyncResult]$AsyncResult
    )

    # Boucle pour attendre que la tÃ¢che soit terminÃ©e
    while (-not $AsyncResult.IsCompleted) {
        Start-Sleep -Milliseconds 100
    }
}

<#
# Synchronized hashtable for cross-runspace communication
$global:sync = [Hashtable]::Synchronized(@{})
# Global hashtable to keep track of runspace states
$global:runspaceStates = [Hashtable]::Synchronized(@{})

# Create a runspace pool
$global:runspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
$global:runspacePool.ApartmentState = "STA"
$global:runspacePool.ThreadOptions = "ReuseThread"
$global:runspacePool.Open()

function Start-Runspace {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RunspaceKey,

        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ScriptBlock
    )

    # Check if the runspace is already in use
    if ($global:runspaceStates.ContainsKey($RunspaceKey)) {
        $state = $global:runspaceStates[$RunspaceKey]
        if ($state -eq 'InUse') {
            Write-Host "Runspace with key '$RunspaceKey' is already in use."
            return
        }
    }

    # Create the PowerShell instance
    $powerShell = [PowerShell]::Create()
    $powerShell.RunspacePool = $global:runspacePool

    # Set the sync hashtable in the runspace's initial session state
    $powerShell.AddScript({ param($sync) $global:sync = $sync }).AddArgument($global:sync)

    # Add the script block to the PowerShell instance
    $powerShell.AddScript($ScriptBlock)

    # Start the asynchronous invocation
    $asyncResult = $powerShell.BeginInvoke()

    # Update the global state tracker
    $global:runspaceStates[$RunspaceKey] = 'InUse'

    # Return the AsyncResult and the PowerShell instance in a custom object
    return @{ AsyncResult = $asyncResult; PowerShellInstance = $powerShell }
}

function Get-RunspaceState($RunspaceResult) {
    if ($RunspaceResult.PowerShellInstance.InvocationStateInfo.State -eq 'Running') {
        Write-Host "Runspace is running."
    } elseif ($RunspaceResult.PowerShellInstance.InvocationStateInfo.State -eq 'Completed') {
        Write-Host "Runspace task is completed."
    } elseif ($RunspaceResult.PowerShellInstance.InvocationStateInfo.State -eq 'Failed') {
        Write-Host "Runspace task failed."
    } else {
        Write-Host "Runspace is in state: $($RunspaceResult.PowerShellInstance.InvocationStateInfo.State)"
    }
}

function Complete-AsyncOperation {
    param (
        [Parameter(Mandatory=$true)]
        [pscustomobject]$RunspaceResult
    )

    # Ensure EndInvoke is called to complete the asynchronous operation
    if ($RunspaceResult.AsyncResult) {
        try {
            $RunspaceResult.PowerShellInstance.EndInvoke($RunspaceResult.AsyncResult)
        } catch {
            Write-Error "Failed to complete asynchronous operation: $_"
        }
    }
}

function Close-Runspace {
    param (
        [Parameter(Mandatory=$true)]
        [pscustomobject]$RunspaceResult,
        [Parameter(Mandatory=$true)]
        [string]$RunspaceKey
    )

    # Dispose of the PowerShell instance
    if ($RunspaceResult.PowerShellInstance) {
        try {
            $RunspaceResult.PowerShellInstance.Dispose()
        } catch {
            Write-Error "Failed to dispose of PowerShell instance: $_"
        }
    }

    # Update the global state tracker
    if ($global:runspaceStates.ContainsKey($RunspaceKey)) {
        $global:runspaceStates.Remove($RunspaceKey)
    } else {
        Write-Warning "RunspaceKey '$RunspaceKey' not found in global state tracker."
    }
}



# Don't forget to close the runspace pool when you're done with all operations
# $global:runspacePool.Close()
# $global:runspacePool.Dispose()

#>