<#
    .DESCRIPTION
        Manages default settings for IIS web sites and web application pools on a target node.
#>
#Requires -Module xPSDesiredStateConfiguration
#Requires -Module xWebAdministration


configuration IISDefaults
{
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]
        $WebSites,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]
        $WebApplicationPools
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
        Create DSC resource for IIS Web Server default settings
    #>
    if ($WebSites)
    {
        # remove case sensitivity of ordered Dictionary or Hashtables
        $WebSites = @{ } + $WebSites

        # add required key
        $WebSites.Key = 'Machine'


        # this resource depends on Windows feature
        $WebSites.DependsOn = '[xWindowsFeature]AddWebServer'

        # create DSC resource
        xWebSiteDefaults 'SetWebSiteDefaults'
        {
            IsSingleInstance       = 'Yes'
            LogFormat              = $WebSites.LogFormat
            LogDirectory           = $WebSites.LogDirectory
            TraceLogDirectory      = $WebSites.TraceLogDirectory
            DefaultApplicationPool = $WebSites.DefaultApplicationPool
            AllowSubDirConfig      = $WebSites.AllowSubDirConfig
            DependsOn              = '[xWindowsFeature]AddWebServer'
        }
    } #end if


    <#
        Create DSC resource for IIS Web Application default settings
    #>
    if ($WebApplicationPools)
    {
        # remove case sensitivity of ordered Dictionary or Hashtables
        $WebApplicationPools = @{ } + $WebApplicationPools

        # add required key
        $WebApplicationPools.IsSingleInstance = 'Yes'

        # this resource depends on Windows feature
        $WebApplicationPools.DependsOn = '[xWindowsFeature]AddWebAspNet45'

        # create DSC resource
        xWebAppPoolDefaults 'SetWebAppPoolDefaults'
        {
            IsSingleInstance      = 'Yes'
            ManagedRuntimeVersion = $WebApplicationPools.ManagedRuntimeVersion
            IdentityType          = $WebApplicationPools.IdentityType
            DependsOn             = '[xWindowsFeature]AddWebAspNet45'
        }
    } #end if
} #end configuration