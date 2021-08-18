<#
    .DESCRIPTION
        Manages SSL settings for IIS web sites on a target node.
#>
#Requires -Module xPSDesiredStateConfiguration
#Requires -Module xWebAdministration


configuration WebSiteSslSettings
{
    param
    (
        [Parameter()]
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
        Create DSC resource for Web Site SSL settings
    #>
    foreach ($i in $Items)
    {
        # remove case sensitivity of ordered Dictionary or Hashtables
        $i = @{ } + $i

        # if not specified, ensure 'Present'
        if ($null -eq $i.Ensure)
        {
            $i.Ensure = 'Present'
        }

        # this resource depends on Windows Feature
        $i.DependsOn = '[xWindowsFeature]AddWebServer'

        # create execution name for the resource
        $executionName = "$($i.Name -replace '[-().:\s]', '_')"


        # create DSC resource
        $Splatting = @{
            ResourceName  = 'xSslSettings'
            ExecutionName = $executionName
            Properties    = $i
            NoInvoke      = $true
        }
        (Get-DscSplattedResource @Splatting).Invoke($i)
    } #end foreach
} #end configuration