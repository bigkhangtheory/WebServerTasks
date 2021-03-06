<#
    .DESCRIPTION

#>
#Requires -Module xPSDesiredStateConfiguration
#Requires -Module xWebAdministration


configuration WebApplications {
    param (
        [Parameter(Mandatory)]
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
        Create DSC resource for each web application
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

        # enumerate each Authentication Info Resource
        if ($i.AuthenticationInfo)
        {
            $i.AuthenticationInfo = MSFT_xWebApplicationAuthenticationInformation {
                Anonymous = $i.AuthenticationInfo.Anonymous
                Basic     = $i.AuthenticationInfo.Basic
                Digest    = $i.AuthenticationInfo.Digest
                Windows   = $i.AuthenticationInfo.Windows
            }
        } #end if
        
        # create execution name for the resource
        $executionName = "$($i.Name -replace '[-().:\s]', '_')"

        # create DSC resource
        $Splatting = @{
            ResourceName  = 'xWebApplication'
            ExecutionName = $executionName
            Properties    = $i
            NoInvoke      = $true
        }
        (Get-DscSplattedResource @Splatting).Invoke($i)
    }
}
