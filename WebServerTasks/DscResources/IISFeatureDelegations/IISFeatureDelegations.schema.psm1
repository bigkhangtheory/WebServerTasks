<#
    .DESCRIPTION
        This configuration manages the IIS configuration section locking (overrideMode) to control what configuration can be set in web.config.
#>
#Requires -Module xPSDesiredStateConfiguration
#Requires -Module xWebAdministration


configuration IISFeatureDelegations
{
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]
        $Machine,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $Modules
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
        Create DSC resource for IIS feature delegations at the machine-level
    #>
    if ($Machine)
    {
        # enumerate each configuration section
        foreach ($s in $Machine.Sections)
        {
            # remove case sensitivity of ordered Dictionary or Hashtables
            $s = @{ } + $s

            # create execution name for the resource
            $myFilter = $s.Filter -split '/' | Select-Object -Last 1
            $executionName = "APPHOST_$($myFilter)_$($s.overrideMode)"

            # create DSC resource to allow write access to machine IIS configuration sections
            xIisFeatureDelegation "$executionName"
            {
                Filter = $s.Filter
                OverrideMode = $s.OverrideMode
                Path         = 'MACHINE/WEBROOT/APPHOST'
                DependsOn    = '[xWindowsFeature]AddWebAspNet45'
            }
        } #end foreach
    } #end if


    <#
        Create DSC resource for IIS feature delegations at the module-level
    #>
    if ($Modules)
    {
        # enumerate list of IIS module paths
        foreach ($p in $Modules)
        {
            # remove case sensitivity of ordered Dictionary or Hashtables
            $p = @{ } + $p

            # form path name
            $myPath = $p.Path -split '\\' | Select-Object -Last 1

            # enumerate supplied configuration sections for the IIS module
            foreach ($s in $p.Sections)
            {
                # remove case sensitivity or ordered Dictionary or Hashtables
                $s = @{ } + $s

                # create execution name for the resource
                $myPath = $myPath -replace '[-().:\s]', '_'
                $myFilter = $s.Filter -split '/' | Select-Object -Last 1
                $executionName = "$($myPath)_$($myFilter)_$($s.OverrideMode)"

                # create DSC resource to allow write access to module IIS configuration sections
                xIisFeatureDelegation "$executionName"
                {
                    Filter = $s.Filter
                    OverrideMode = $s.OverrideMode
                    Path         = $p.Path
                    DependsOn    = '[xWindowsFeature]AddWebAspNet45'
                } #end configuration
            } #end foreach
        } #end foreach
    } #end if
} #end configuration