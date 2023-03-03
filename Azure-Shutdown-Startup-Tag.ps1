# Connect to Azure
Connect-AzAccount -Identity

$subscriptions = @"
[
"AAAAAAAA-BBBB-CCCC-DDDD-FFFFFFFFFFF"
]
"@

    
# Get the current time and format it to HH:mm
$currentTime = Get-Date
       
foreach ($subscription in $subscriptions) {

 Set-AzContext -SubscriptionId $subscription 

    # Get all Virtual Machines with the tag "ShutdownTime"
    $vmsOnSchedule = Get-AzVM -status | Where-Object { ($_.Tags.Keys -contains "ShutdownSchedule") }
    $vmsShutdown = Get-AzVM -status | Where-Object { ($_.Tags.Keys -contains "ShutdownTime") -and ($_.PowerState -eq 'VM running') }
    $vmsStartup = Get-AzVM -status  | Where-Object { ($_.Tags.Keys -contains "StartTime") -and ($_.PowerState -eq 'VM deallocated') }
    # Loop through each VM
    foreach ($vm in $vmsOnSchedule) {
        
       # Shutdown?
       if($vm.Tags.Contains["ShutdownTime"] && $vm.PowerState == 'running')
       {
         # Shut this machine down
         $shutdownTime = [DateTime]::ParseExact($vm.Tags["ShutdownTime"], "HH:mm", $null)
         $timeDiff = ($currentTime - $shutdownTime).TotalMinutes
         if ($timeDiff -le 80 -and $timeDiff -ge 0) {
            # Shut down the VM
            Write-Output "Shutting down VM $($vm.Name) in $($vm.ResourceGroupName) because ShutdownTime tag value is $($shutdownTime)."
            Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force

        }
         continue;
       }
                    
       # Startup?       
       if($vm.Tags.Contains["StartTime"] && $vm.PowerState == 'deallocated')
       {
         # Start this machine up
         $startupTime = [DateTime]::ParseExact($vm.Tags["StartTime"], "HH:mm", $null)
         $timeDiff = ($currentTime - $startupTime).TotalMinutes
         $validDay = !$vm.Tags.Contains["StartTime"] || $vm.Tags["StartTime"] == 'false' || [int]$currentTime.DayOfWeek -le 4;
         if ($validDay -and $timeDiff -le 60 -and $timeDiff -ge 0) {
            # Shut down the VM
            Write-Output "Starting VM $($vm.Name) in $($vm.ResourceGroupName) because StartupTime tag value is $($startupTime)."
            Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name

        }
         continue;
       }

    } 
}
