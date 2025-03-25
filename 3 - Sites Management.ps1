Function Test-Site {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    If (-Not ((Test-SingleObject $Site) -And (Test-Properties $Site Url, Title))) {

        Write-Message "Invalid site." -Color "Red" -Silent:$Silent
        Return $False

    } Else {

        Return $True

    }

}

Function Test-SiteConnection {

    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Site = $Global:CurrentSite,
        [Switch]$Silent
    )
    
    If (-Not (Test-TenantConnection -Silent:$Silent)) { Return $False }
    If (-Not (Test-Site $Site -Silent:$Silent)) { Return $False }

    If (Test-Object $Global:CurrentSite) {

        If ($Site -Eq $Global:CurrentSite ) {

            Return $True

        } Else {

            Write-Message "Not connected to $($Site.Title) site." -Color "Red" -Silent:$Silent
            Return $False

        }

    } Else {

        Write-Message "Not connected to a site." -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Connect-Site {

    Param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Return,
        [Switch]$Silent
    )

    Process {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        If (-Not (Test-Site $Site -Silent:$Silent)) { Return }
        
        Invoke-Operation "Connecting to site: $($Site.Title)" -Return:$Return -Silent:$Silent -Operation {

            Connect-PnPOnline -Url $Site.Url -ClientId $Global:CurrentTenant.ClientID -ReturnConnection:$Return -Interactive
            If (-Not $Return) { Set-Variable -Name "CurrentSite" -Value $Site -Scope Global }

        }

    }

}

Function Disconnect-Site {

    Param (
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Site = $Global:CurrentSite,
        [Switch]$Silent
    )

    If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
    If (-Not (Test-SiteConnection $Site -Silent:$Silent)) { Return }

    Invoke-Operation -Message "Disconnecting from site: $($Site.Title)" -Silent:$Silent -Operation {

        Connect-PnPOnline -Url $Global:CurrentTenant.AdminUrl -ClientId $Global:CurrentTenant.ClientID -Interactive
        Set-Variable -Name "CurrentSite" -Value (Get-PnPTenantSite $CurrentTenant.AdminUrl) -Scope Global

    }

}

Function Get-Sites {

    Param(
        [Switch]$SharePoint,
        [Switch]$OneDrive,
        [Switch]$Teams,
        [Switch]$Channels
    )

    If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

    $Sites = @()
    $AllSites = Get-PnPTenantSite -IncludeOneDriveSites

    If ($SharePoint) { $Sites = $Sites + ($AllSites | Where-Object Template -Match "SitePage" | Where-Object Url -NotMatch "/marca") }
    If ($OneDrive) { $Sites = $Sites + ($AllSites | Where-Object Template -Match "SpsPers" | Where-Object Url -Match "/personal/") }
    If ($Teams) { $Sites = $Sites + ($AllSites | Where-Object Template -Match "Group") }
    If ($Channels) { $Sites = $Sites + ($AllSites | Where-Object Template -Match "TeamChannel") }

    If (-Not $SharePoint -And -Not $OneDrive -And -Not $Teams -And -Not $Channels) { $Sites = $AllSites }

    Return $Sites

}

Function Get-Site {

    Param(
        [String]$Identity
    )

    If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

    If ($Identity) {

        $Site = Get-PnPTenantSite -Identity $Identity

    } Else {

        $Site = $Global:CurrentTenant

    }

    Return $Site

}

Function Test-HomeSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Site.Url.Replace("/", "").EndsWith(".sharepoint.com")

}

Function Test-SharePointSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Site.Template -Match "SitePage"

}

Function Test-OneDriveSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Site.Template -Match "SpsPers" -And $Site.Url -Match "/personal/"

}

Function Test-TeamSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Site.Template -Match "Group"

}

Function Test-ChannelSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Site.Template -Match "TeamChannel"

}

Function Set-Site {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$All,
        [Switch]$Admins,
        [Switch]$Params,
        [Switch]$Appearance,
        [Switch]$Versioning,
        [Switch]$Navigation,
        [Switch]$ShowInfo,
        [Switch]$ShowErrors
    )

    Begin {

        $ParamConnection = $Connection

    }

    Process {

        # Connect to Site
        $Connection = Invoke-Operation -Message "Connecting to site: $($Site.Title)" -ShowInfo:$ShowInfo -ShowErrors:$ShowErrors -ReturnValue -Operation {

            Connect-Site -Site $Site -Silent -Return

        }

        # Line Break
        Write-Host ""

    }

}

Function Set-SiteAdmins {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$ShowInfo,
        [Switch]$ShowErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $ParamConnection = $Connection
        $GlobalAdmin = "Administradores Globais"
        $OtherAdmins = $Null

    }

    Process {

        If (-Not $ParamConnection) { $Connection = Connect-Site $Site -Return -Silent } Else { $Connection = $ParamConnection }

        Invoke-Operation -Message "Setting administrators to site: $($Site.Title)" -ShowInfo:$ShowInfo -ShowErrors:$ShowErrors -Silent:$Silent -Operation {

            $SiteAdmins = Get-PnPSiteCollectionAdmin -Connection $Connection
            Add-PnPSiteCollectionAdmin -Owners $OtherAdmins -PrimarySiteCollectionAdmin $GlobalAdmin -Connection $Connection
            $SiteAdmins | Where-Object Title -NE $GlobalAdmin | Where-Object LoginName -NotIn ($OtherAdmins) | Remove-PnPSiteCollectionAdmin -Connection $Connection

        }
        
    }

}

Function Set-SiteAppearance {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$ShowInfo,
        [Switch]$ShowErrors,
        [Switch]$Silent
    )

    Begin {
        
        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $ParamConnection = $Connection
        $TenantTheme = ConvertFrom-Json $Global:CurrentTenant.Theme -AsHashtable
        
    }

    Process {

        If (-Not $Connection) { $Connection = Connect-Site -Site $Site -Return -Silent }

        Invoke-Operation -Message "Setting appearance to site: $($Site.Title)" -ShowInfo:$ShowInfo -ShowErrors:$ShowErrors -Silent:$Silent -Operation {

            Remove-PnPTenantTheme -Identity $TenantTheme.name -Connection $Connection
            Add-PnPTenantTheme -Identity $TenantTheme.name -Palette $TenantTheme.palette -IsInverted $TenantTheme.isInverted -Overwrite -Connection $Connection
            Set-PnPWebTheme -Theme $TenantTheme.name -Connection $Connection

            Set-PnPWebHeader -HeaderLayout "Standard" -HeaderEmphasis "None" -HideTitleInHeader:$False -HeaderBackgroundImageUrl $Null -LogoAlignment Left -Connection $Connection
            Set-PnPFooter -Enabled:$False -Layout "Simple" -BackgroundTheme "Neutral" -Title $Null -LogoUrl $Null -Connection $Connection
                
        }
            
    }

}

Function Set-SiteVersioning {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$ShowInfo,
        [Switch]$ShowErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
     
        $ParamConnection = $Connection

    }

    Process {

        If (-Not $Connection) { $Connection = Connect-Site -Site $Site -Return -Silent }

        Invoke-Operation -Message "Setting versioning to site: $($Site.Title)" -ShowInfo:$ShowInfo -ShowErrors:$ShowErrors -Operation {

            $Status = (Get-PnPSiteVersionPolicyStatus).Status

            If ($Status -Ne "New") {

                Set-PnPSiteVersionPolicy -EnableAutoExpirationVersionTrim $True -ApplyToNewDocumentLibraries -ApplyToExistingDocumentLibraries -Connection $Connection
                Set-PnPSiteVersionPolicy -InheritFromTenant -Connection $Connection

            }
                
        }
            
    }

}

Function Set-SiteNavigation {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$ShowInfo,
        [Switch]$ShowErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $ParamConnection = $Connection
        $EventsList = $Global:CurrentTenant.EventsID
        
    }

    Process {

        If (-Not $Connection) { $Connection = Connect-Site -Site $Site -Return -Silent }
        
        Invoke-Operation -Message "Setting navigation to site: $($Site.Title)" -ShowInfo:$ShowInfo -ShowErrors:$ShowErrors -Operation {

            # aqui...
                
        }

    }

}

Function Set-SiteParams {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$ShowInfo,
        [Switch]$ShowErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $ParamConnection = $Connection
        
    }

    Process {

        If (-Not $Connection) { $Connection = Connect-Site -Site $Site -Return -Silent }
        
        If ((Test-SharePointSite $Site) -And (Test-HomeSite $Site)) {

            $SiteParams = @{
                DefaultLinkPermission                       = "View"
                DefaultLinkToExistingAccess                 = $True
                DefaultShareLinkRole                        = "View"
                DefaultShareLinkScope                       = "SpecificPeople"
                DefaultSharingLinkType                      = "Direct"
                DenyAddAndCustomizePages                    = $True
                DisableSharingForNonOwners                  = $True
                InheritVersionPolicyFromTenant              = $True
                OverrideSharingCapability                   = $False
                OverrideTenantAnonymousLinkExpirationPolicy = $False
                OverrideTenantExternalUserExpirationPolicy  = $False
                SharingCapability                           = "ExternalUserAndGuestSharing"
            }

        }
        
        If ((Test-SharePointSite $Site) -And -Not (Test-HomeSite $Site)) {

            $SiteParams = @{
                DefaultLinkPermission                       = "View"
                DefaultLinkToExistingAccess                 = $True
                DefaultShareLinkRole                        = "View"
                DefaultShareLinkScope                       = "SpecificPeople"
                DefaultSharingLinkType                      = "Direct"
                DenyAddAndCustomizePages                    = $True
                DisableSharingForNonOwners                  = $True
                InheritVersionPolicyFromTenant              = $True
                OverrideSharingCapability                   = $False
                OverrideTenantAnonymousLinkExpirationPolicy = $False
                OverrideTenantExternalUserExpirationPolicy  = $False
                SharingCapability                           = "ExistingExternalUserSharingOnly"
            }

        }
        
        If (Test-OneDriveSite $Site) {

            $SiteParams = @{
                DefaultLinkPermission                       = "View"
                DefaultLinkToExistingAccess                 = $False
                DefaultShareLinkRole                        = "View"
                DefaultShareLinkScope                       = "SpecificPeople"
                DefaultSharingLinkType                      = "Direct"
                DenyAddAndCustomizePages                    = $True
                DisableSharingForNonOwners                  = $True
                InheritVersionPolicyFromTenant              = $True
                OverrideSharingCapability                   = $False
                OverrideTenantAnonymousLinkExpirationPolicy = $False
                OverrideTenantExternalUserExpirationPolicy  = $False
                SharingCapability                           = "ExistingExternalUserSharingOnly"
            }
            
        }

        If (Test-TeamSite $Site) {

            $SiteParams = @{
                DefaultLinkPermission                       = "View"
                DefaultLinkToExistingAccess                 = $True
                DefaultShareLinkRole                        = "View"
                DefaultShareLinkScope                       = "SpecificPeople"
                DefaultSharingLinkType                      = "Direct"
                DenyAddAndCustomizePages                    = $True
                DisableSharingForNonOwners                  = $True
                InheritVersionPolicyFromTenant              = $True
                OverrideSharingCapability                   = $False
                OverrideTenantAnonymousLinkExpirationPolicy = $False
                OverrideTenantExternalUserExpirationPolicy  = $False
                SharingCapability                           = "ExistingExternalUserSharingOnly"
            }
            
        }

        If (Test-ChannelSite $Site) {

            $SiteParams = @{
                DefaultLinkPermission                       = "View"
                DefaultLinkToExistingAccess                 = $True
                DefaultShareLinkRole                        = "View"
                DefaultShareLinkScope                       = "SpecificPeople"
                DefaultSharingLinkType                      = "Direct"
                DenyAddAndCustomizePages                    = $True
                DisableSharingForNonOwners                  = $True
                InheritVersionPolicyFromTenant              = $True
                OverrideSharingCapability                   = $False
                OverrideTenantAnonymousLinkExpirationPolicy = $False
                OverrideTenantExternalUserExpirationPolicy  = $False
                SharingCapability                           = "ExistingExternalUserSharingOnly"
            }
            
        }
        
        Invoke-Operation -Message "Setting parameters to site: $($Site.Title)" -ShowInfo:$ShowInfo -ShowErrors:$ShowErrors -Silent:$Silent -Operation {

            Set-PnPTenantSite -Identity $Site.Url @SiteParams -Connection $Connection
            Disable-PnPSharingForNonOwnersOfSite -Identity $Site.Url -Connection $Connection

        }

    }

}
