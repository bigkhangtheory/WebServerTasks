<#
    .DESCRIPTION
        This DSC configuration creates a new web virtual directory for an IIS web site on a target node.
#>
#Requires -Module xPSDesiredStateConfiguration
#Requires -Module xWebAdministration


configuration WebVirtualDirectories
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $Items
    )

    <#
        Import required modules
    #>
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

    <#
        Ensure required Windows Features
    #>
    xWindowsFeature AddWebServer
    {
        Name   = 'Web-Server'
        Ensure = 'Present'
    }
    xWindowsFeature AddWebAspNet45
    {
        Name      = 'Web-Asp-Net45'
        Ensure    = 'Present'
        DependsOn = '[xWindowsFeature]AddWebServer'
    }

    <#
        Enumerate all items and create DSC resource for IIS virtual directories
    #>
    foreach ($i in $Items)
    {
        # remove case sensitivity of ordered Dictionary or Hashtables
        $i = @{ } + $i

        # if not specified, ensure 'Present'
        if (-not $i.ContainsKey('Ensure'))
        {
            $i.Ensure = 'Present'
        }

        # create execution name for the resource
        $executionName = "$($i.Name -replace '[-().:\s]', '_')"

        # create DSC resource
        $Splatting = @{
            ResourceName  = 'xWebVirtualDirectory'
            ExecutionName = $executionName
            Properties    = $i
            NoInvoke      = $true
        }
        (Get-DscSplattedResource @Splatting).Invoke($i)
    } #end foreach
} #end configuration
