Function Test-Tenant {

    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Tenant,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $Tenant -Silent:$Silent) -And (Test-Properties $Tenant Slug, Name, Domain, TenantID, ClientID -Silent:$Silent))) {

            Write-Message "Invalid tenant." -Color "Red" -Silent:$Silent
            Return $False

        } Else {

            Return $True

        }

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-TenantConnection {

    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Tenant = $Global:CurrentTenant,
        [Switch]$Silent
    )
    
    Try {

        If (-Not (Test-Tenant $Tenant -Silent:$Silent)) { Return $False }

        If (Test-Object $Global:CurrentTenant -Silent:$Silent) {

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

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Connect-Tenant {

    Param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Tenant,
        [Switch]$Return,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Process {

        If (-Not (Test-Tenant $Tenant -Silent:$Silent)) { Return }

        Invoke-Operation -Message "Connecting to tenant: $($Tenant.Name)" -Return:$Return -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
            $Password = ConvertTo-SecureString -String $Tenant.Domain -AsPlainText -Force
            $Certificate = Get-ChildItem -Path (Get-Path("Certificates")) -Recurse | Where-Object Name -Like "$($Tenant.Name).pfx"
            Connect-PnPOnline -Tenant $Tenant.Domain -Url $Tenant.AdminUrl -ClientId $Tenant.ClientID -CertificatePath $Certificate.FullName -CertificatePassword $Password -ReturnConnection:$Return
            If (-Not $Return) { Set-Variable -Name "CurrentTenant" -Value $Tenant -Scope Global; Set-Variable -Name "CurrentSite" -Value (Get-PnPTenantSite $Tenant.AdminUrl) -Scope Global }

        }

    }

}

Function Disconnect-Tenant {

    Param (
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Tenant = $Global:CurrentTenant,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    If (-Not (Test-TenantConnection $Tenant -Silent:$Silent)) { Return }

    Invoke-Operation -Message "Disconnecting from tenant: $($Tenant.Name)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

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
            TenantID = '5b9e12f8-488e-4289-a70b-23371cd3e822'
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
            TenantID = '1f8fd295-6082-4f7c-8631-7a1cb72171d3'
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
            TenantID = '3fa6e3f1-f73c-4e8a-b082-cd8267d7d69a'
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
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Process {

        Invoke-Operation -Message "Setting tenant: $($Tenant.Name)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
            $Connection = Connect-Tenant $Tenant -Return -Silent

            $TenantParams = @{
                AllowCommentsTextOnEmailEnabled            = $True
                AllowFilesWithKeepLabelToBeDeletedODB      = $False
                AllowFilesWithKeepLabelToBeDeletedSPO      = $False
                AnyoneLinkTrackUsers                       = $True
                BlockUserInfoVisibilityInOneDrive          = "ApplyToNoUsers"
                BlockUserInfoVisibilityInSharePoint        = "ApplyToNoUsers"
                CommentsOnFilesDisabled                    = $False
                CommentsOnListItemsDisabled                = $False
                ConditionalAccessPolicy                    = "AllowFullAccess"
                CoreDefaultLinkToExistingAccess            = $True
                CoreDefaultShareLinkRole                   = "View"
                CoreDefaultShareLinkScope                  = "SpecificPeople"
                CoreSharingCapability                      = "ExternalUserAndGuestSharing"
                DefaultLinkPermission                      = "View"
                DefaultSharingLinkType                     = "Direct"
                DisableAddToOneDrive                       = $True
                DisableBackToClassic                       = $True
                DisablePersonalListCreation                = $False
                DisplayNamesOfFileViewers                  = $True
                DisplayNamesOfFileViewersInSpo             = $True
                DisplayStartASiteOption                    = $False
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
                SpecialCharactersStateInFileFolderNames    = "Allowed"
                ViewersCanCommentOnMediaDisabled           = $False
            }
            
            Set-PnPTenant @TenantParams -Force -Connection:$Connection

        }

    }

}
