configuration WebApplicationPools {
    param (
        [Parameter(Mandatory)]
        [hashtable[]]$Items
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

    foreach ($item in $Items) {
        
        if (-not $item.ContainsKey('Ensure')) {
            $item.Ensure = 'Present'
        }

        $executionName = "$($item.Name -replace '[-().:\s]', '_')"
        
        (Get-DscSplattedResource -ResourceName xWebAppPool -ExecutionName $executionName -Properties $item -NoInvoke).Invoke($item)
    }
}
