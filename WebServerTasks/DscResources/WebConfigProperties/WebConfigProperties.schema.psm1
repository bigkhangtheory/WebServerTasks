<#
    .DESCRIPTION

#>
#Requires -Module xPSDesiredStateConfiguration
#Requires -Module xWebAdministration


configuration WebConfigProperties {
    param
    (
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
        Create DSC resource for Web Config Properties
    #>
    foreach ($i in $Items)
    {
        # remove case sensitivity of ordered Dictionary or Hashtables
        $i = @{ } + $i
    
        # enumerate all properties of a web site
        foreach ($p in $i.Properties)
        {

            # if not specified, ensure 'Present'
            if ($null -eq $p.Ensure)
            {
                $p.Ensure = 'Present'
            }

            # create execution name for the resource
            $websitePath = $i.WebsitePath -split '\\' | Select-Object -Last 1
            $myFilter = $p.Filter -split '/' | Select-Object -Last 1
            $executionName = "$($websitePath)_$($myFilter)_$($p.PropertyName)"

            # create DSC resource
            xWebConfigProperty "$executionName"
            {
                WebsitePath  = $i.WebsitePath
                Filter = $p.Filter
                PropertyName = $p.PropertyName
                Value        = $p.Value
                Ensure       = $p.Ensure
                DependsOn    = '[xWindowsFeature]AddWebAspNet45'
            } #end xWebConfigProperty
        } #end foreach
    } #end foreach
} #end configuration