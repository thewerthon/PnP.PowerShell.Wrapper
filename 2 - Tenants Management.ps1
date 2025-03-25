Function Test-Tenant {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Tenant,
        [Switch]$Silent
    )

    If (-Not ((Test-SingleObject $Tenant) -And (Test-Properties $Tenant Slug, Name, ClientID))) {

        Write-Message "Invalid tenant." -Color "Red" -Silent:$Silent
        Return $False

    } Else {

        Return $True

    }

}

Function Test-TenantConnection {

    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Tenant = $Global:CurrentTenant,
        [Switch]$Silent
    )
    
    If (-Not (Test-Tenant $Tenant -Silent:$Silent)) { Return $False }

    If (Test-Object $Global:CurrentTenant) {

        If ($Tenant -Eq $Global:CurrentTenant ) {

            Return $True

        } Else {

            Write-Message "Not connected to $($Tenant.Name) tenant." -Color "Red" -Silent:$Silent
            Return $False

        }

    } Else {

        Write-Message "Not connected to a tenant." -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Connect-Tenant {

    Param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Tenant,
        [Switch]$Return,
        [Switch]$Silent
    )

    Process {

        If (-Not (Test-Tenant $Tenant -Silent:$Silent)) { Return }

        Invoke-Operation -Message "Connecting to tenant: $($Tenant.Name)" -Return:$Return -Silent:$Silent -Operation {
            
            Connect-PnPOnline -Url $Tenant.AdminUrl -ClientId $Tenant.ClientID -ReturnConnection:$Return -Interactive
            If (-Not $Return) { Set-Variable -Name "CurrentTenant" -Value $Tenant -Scope Global; Set-Variable -Name "CurrentSite" -Value (Get-PnPTenantSite $CurrentTenant.AdminUrl) -Scope Global }

        }

    }

}

Function Disconnect-Tenant {

    Param (
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Tenant = $Global:CurrentTenant,
        [Switch]$Silent
    )

    If (-Not (Test-TenantConnection $Tenant -Silent:$Silent)) { Return }

    Invoke-Operation -Message "Disconnecting from tenant: $($Tenant.Name)" -Silent:$Silent -Operation {

        Disconnect-PnPOnline
        Set-Variable -Name "CurrentTenant" -Value $Null -Scope Global
        Set-Variable -Name "CurrentSite" -Value $Null -Scope Global

    }

}

Function Get-Tenants {

    $Tenants = @(

        [PSCustomObject]@{
            Slug     = 'siwindbr'
            Name     = 'SIW Kits Eólicos'
            Domain   = 'siw.ind.br'
            BaseUrl  = 'https://siwindbr.sharepoint.com'
            AdminUrl = 'https://siwindbr-admin.sharepoint.com'
            ClientID = '8b14c0ea-5f50-4c5c-b2f8-a50b5ca20d8b'
            EventsID = '502190fd-356c-434c-a73f-db7146b5c1eb'
            Theme    = '{"name":"SIW Kits Eólicos","isInverted":false,"palette":{"themeDarker":"#835719","themeDark":"#b27622","themeDarkAlt":"#d38c28","themePrimary":"#eb9d2d","themeSecondary":"#eda744","themeTertiary":"#f3c27d","themeLight":"#f9e0bc","themeLighter":"#fceedb","themeLighterAlt":"#fefbf6","black":"#000000","neutralDark":"#201f1e","neutralPrimary":"#323130","neutralPrimaryAlt":"#3b3a39","neutralSecondary":"#605e5c","neutralTertiary":"#a19f9d","neutralTertiaryAlt":"#c8c6c4","neutralLight":"#edebe9","neutralLighter":"#f3f2f1","neutralLighterAlt":"#faf9f8","white":"#ffffff","neutralQuaternaryAlt":"#e1dfdd","neutralQuaternary":"#d0d0d0","accent":"#ffc000"}}'
            Params   = [Object]$Null
        },

        [PSCustomObject]@{
            Slug     = 'gcgestao'
            Name     = 'GC Gestão'
            Domain   = 'gcgestao.com.br'
            BaseUrl  = 'https://gcgestao.sharepoint.com'
            AdminUrl = 'https://gcgestao-admin.sharepoint.com'
            ClientID = '91aac6c3-b063-4175-8073-7e5b5a4ff281'
            EventsID = '2eb9023a-c795-4c5e-b536-2975c670ac40'
            Theme    = '{"name":"GC Gestão","isInverted":false,"palette":{"themeDarker":"#002a61","themeDark":"#003984","themeDarkAlt":"#00449c","themePrimary":"#004aad","themeSecondary":"#165cb7","themeTertiary":"#5288ce","themeLight":"#a1bfe7","themeLighter":"#cbdcf2","themeLighterAlt":"#f2f6fc","black":"#000000","neutralDark":"#201f1e","neutralPrimary":"#323130","neutralPrimaryAlt":"#3b3a39","neutralSecondary":"#605e5c","neutralTertiary":"#a19f9d","neutralTertiaryAlt":"#c8c6c4","neutralLight":"#edebe9","neutralLighter":"#f3f2f1","neutralLighterAlt":"#faf9f8","white":"#ffffff","neutralQuaternaryAlt":"#e1dfdd","neutralQuaternary":"#d0d0d0","accent":"#159aff"}}'
            Params   = [Object]$Null
        },

        [PSCustomObject]@{
            Slug     = 'inteceletrica'
            Name     = 'Intec Elétrica'
            Domain   = 'inteceletrica.com.br'
            BaseUrl  = 'https://inteceletrica.sharepoint.com'
            AdminUrl = 'https://inteceletrica-admin.sharepoint.com'
            ClientID = '7735abc1-32a8-416b-a7be-3d2496ba4724'
            EventsID = 'c38fba0b-6ca6-4e1b-9b55-f284a18a6333'
            Theme    = '{"name":"Intec Elétrica","isInverted":false,"palette":{"themeDarker":"#002849","themeDark":"#003663","themeDarkAlt":"#004075","themePrimary":"#004782","themeSecondary":"#115891","themeTertiary":"#4883b4","themeLight":"#98bcda","themeLighter":"#c5daeb","themeLighterAlt":"#f0f6fa","black":"#000000","neutralDark":"#201f1e","neutralPrimary":"#323130","neutralPrimaryAlt":"#3b3a39","neutralSecondary":"#605e5c","neutralTertiary":"#a19f9d","neutralTertiaryAlt":"#c8c6c4","neutralLight":"#edebe9","neutralLighter":"#f3f2f1","neutralLighterAlt":"#faf9f8","white":"#ffffff","neutralQuaternaryAlt":"#e1dfdd","neutralQuaternary":"#d0d0d0","accent":"#159aff"}}'
            Params   = [Object]$Null
        }

    )

    Return $Tenants

}

Function Get-Tenant {

    Param(
        [String]$Identity,
        [Switch]$Params
    )

    If ($Identity) {

        $Tenant = (Get-Tenants | Where-Object { $_.Slug -Eq $Identity -Or $_.Name -Eq $Identity })[0]

    } Else {

        $Tenant = $Global:CurrentTenant

    }

    If ($Tenant -And $Params) {

        $Connection = Connect-Tenant $Tenant -Return -Silent
        $Tenant.Params = Get-PnPTenant -Connection $Connection

    }

    Return $Tenant

}

Function Set-Tenant {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Tenant,
        [Switch]$Connection,
        [Switch]$ShowInfo,
        [Switch]$ShowErrors,
        [Switch]$Silent
    )

    Begin {
    
        $ParamConnection = $Connection

    }

    Process {

        If (-Not (Test-Tenant $Tenant -Silent:$Silent)) { Return }

        $TenantParams = @{
            AllowCommentsTextOnEmailEnabled            = $True
            AllowFilesWithKeepLabelToBeDeletedODB      = $False
            AllowFilesWithKeepLabelToBeDeletedAppO     = $False
            AnyoneLinkTrackUsers                       = $True
            BlockUserInfoVisibilityInOneDrive          = "ApplyToNoUsers"
            BlockUserInfoVisibilityInSharePoint        = "ApplyToNoUsers"
            CommentsOnFilesDisabled                    = $False
            CommentsOnListItemsDisabled                = $False
            ConditionalAccesAppolicy                   = "AllowFullAccess"
            CoreDefaultLinkToExistingAccess            = $True
            CoreDefaultShareLinkRole                   = "View"
            CoreDefaultShareLinkScope                  = "SpecificPeople"
            CoreSharingCapability                      = "ExternalUserAndGuestSharing"
            DefaultLinkPermission                      = "View"
            DefaultSharingLinkType                     = "Direct"
            DisableAddToOneDrive                       = $True
            DisableBackToClassic                       = $True
            DisablePersonalListCreation                = $False
            DiApplayNamesOfFileViewers                 = $True
            DiApplayNamesOfFileViewersInAppo           = $True
            DiApplayStartASiteOption                   = $False
            EnableAIPIntegration                       = $True
            EnableAutoExpirationVersionTrim            = $True
            EnableAutoNewsDigest                       = $True
            EnableDiscoverableByOrganizationForVideos  = $True
            EnableSensitivityLabelForPDF               = $True
            ExtendPermissionsToUnprotectedFiles        = $True
            ExternalUserExpirationRequired             = $True
            ExternalUserExpireInDays                   = 90
            FileAnonymousLinkType                      = "View"
            FolderAnonymousLinkType                    = "View"
            HideDefaultThemes                          = $True
            HideSyncButtonOnDocLib                     = $True
            HideSyncButtonOnODB                        = $True
            HideSyncButtonOnTeamSite                   = $True
            IncludeAtAGlanceInShareEmails              = $True
            IsDataAccessInCardDesignerEnabled          = $True
            IsFluidEnabled                             = $True
            IsLoopEnabled                              = $True
            MassDeleteNotificationDisabled             = $False
            ODBAccessRequests                          = "On"
            ODBMembersCanShare                         = "Off"
            OneDriveDefaultLinkToExistingAccess        = $False
            OneDriveDefaultShareLinkRole               = "View"
            OneDriveDefaultShareLinkScope              = "SpecificPeople"
            OneDriveSharingCapability                  = "ExistingExternalUserSharingOnly"
            OrphanedPersonalSitesRetentionPeriod       = 365
            PreventExternalUsersFromReSharing          = $True
            ProvisionSharedWithEveryoneFolder          = $False
            PublicCdnAllowedFileTypes                  = "CSS,EOT,GIF,ICO,JPEG,JPG,JS,MAP,PNG,SVG,TTF,WOFF"
            PublicCdnEnabled                           = $True
            RecycleBinRetentionPeriod                  = 93
            RequireAcceptingAccountMatchInvitedAccount = $True
            RequireAnonymousLinksExpireInDays          = 90
            SearchResolveExactEmailOrUPN               = $False
            SelfServiceSiteCreationDisabled            = $True
            SharingCapability                          = "ExternalUserAndGuestSharing"
            ShowAllUsersClaim                          = $False
            ShowEveryoneClaim                          = $False
            ShowEveryoneExceptExternalUsersClaim       = $False
            ShowOpenInDesktopOptionForSyncedFiles      = $True
            SocialBarOnSitePagesDisabled               = $False
            AppecialCharactersStateInFileFolderNames   = "Allowed"
            ViewersCanCommentOnMediaDisabled           = $False
        }

        If (-Not $ParamConnection) { $Connection = Connect-Tenant $Tenant -Return -Silent } Else { $Connection = $ParamConnection }

        Invoke-Operation -Message "Setting tenant: $($Tenant.Name)" -ShowInfo:$ShowInfo -ShowErrors:$ShowErrors -Silent:$Silent -Operation {

            Set-PnPTenant @TenantParams -Force -Connection:$Connection

        }

    }

}
