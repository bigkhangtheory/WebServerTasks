<#
    .DESCRIPTION

#>
#Requires -Module xPSDesiredStateConfiguration
#Requires -Module xWebAdministration


configuration WebSites {
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
        Create DSC resource for each web site
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

        # enumerate each Binding Info resource
        if ($i.BindingInfo)
        {
            $i.BindingInfo = @(
                foreach ($b in $i.BindingInfo)
                {
                    switch ($b.Protocol)
                    {
                        'http'
                        {
                            MSFT_xWebBindingInformation {
                                Protocol  = $b.Protocol
                                IPAddress = $b.IPAddress
                                Port      = $b.Port
                                HostName  = $b.HostName
                            }
                        } #end http
                        'https'
                        {
                            MSFT_xWebBindingInformation {
                                Protocol              = $b.Protocol
                                IPAddress             = $b.IPAddress
                                Port                  = $b.Port
                                HostName              = $b.HostName
                                CertificateThumbprint = $b.CertificateThumbprint
                                CertificateSubject    = $b.CertificateSubject
                                SslFlags = switch ($b.SslFlags)
                                {
                                    0 { $b.SslFlags }
                                    1 { $b.SslFlags }
                                    2 { $b.SslFlags }
                                    3 { $b.SslFlags }
                                    default { 0 }
                                }
                            }
                        }
                    } #end switch
                } #end foreach
            )
        } #end if

        # enumerate each Authentication Info Resource
        if ($i.AuthenticationInfo)
        {
            $i.AuthenticationInfo = MSFT_xWebAuthenticationInformation {
                Anonymous = $i.AuthenticationInfo.Anonymous
                Basic     = $i.AuthenticationInfo.Basic
                Digest    = $i.AuthenticationInfo.Digest
                Windows   = $i.AuthenticationInfo.Windows
            }
        }

        # this resource depends on Windows feature
        $i.DependsOn = '[xWindowsFeature]AddWebAspNet45'
        
        # create DSC resource
        $Splatting = @{
            ResourceName  = 'xWebSite'
            ExecutionName = $executionName
            Properties    = $i
            NoInvoke      = $true
        }
        (Get-DscSplattedResource @Splatting).Invoke($i)
    } #end foreach
} #end configuration
