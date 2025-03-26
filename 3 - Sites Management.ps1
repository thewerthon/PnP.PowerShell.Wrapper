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
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Process {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        If (-Not (Test-Site $Site -Silent:$Silent)) { Return }
        
        Invoke-Operation "Connecting to site: $($Site.Title)" -Return:$Return -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            $Password = ConvertTo-SecureString -String $Global:CurrentTenant.Domain -AsPlainText -Force
            $Certificate = Get-ChildItem -Path "$PSScriptRoot" -Recurse | Where-Object Name -Like "$($Global:CurrentTenant.Name).pfx"
            Connect-PnPOnline -Tenant $Global:CurrentTenant.Domain -Url $Site.Url -ClientId $Global:CurrentTenant.ClientID -CertificatePath $Certificate.FullName -CertificatePassword $Password -ReturnConnection:$Return
            If (-Not $Return) { Set-Variable -Name "CurrentSite" -Value $Site -Scope Global }

        }

    }

}

Function Disconnect-Site {

    Param (
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Site = $Global:CurrentSite,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
    If (-Not (Test-SiteConnection $Site -Silent:$Silent)) { Return }

    Invoke-Operation -Message "Disconnecting from site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

        $Password = ConvertTo-SecureString -String $Global:CurrentTenant.Domain -AsPlainText -Force
        $Certificate = Get-ChildItem -Path "$PSScriptRoot" -Recurse | Where-Object Name -Like "$($Global:CurrentTenant.Name).pfx"
        Connect-PnPOnline -Tenant $Global:CurrentTenant.Domain -Url $Global:CurrentTenant.AdminUrl -ClientId $Global:CurrentTenant.ClientID -CertificatePath $Certificate.FullName -CertificatePassword $Password -ReturnConnection:$Return
        Set-Variable -Name "CurrentSite" -Value (Get-PnPTenantSite $Global:CurrentTenant.AdminUrl) -Scope Global

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

    If (-Not $SharePoint -And -Not $OneDrive -And -Not $Teams -And -Not $Channels) { $Sites = $AllSites }
    If ($SharePoint) { $Sites = $Sites + ($AllSites | Where-Object Template -Match "SitePage" | Where-Object Url -NotMatch "/marca") }
    If ($OneDrive) { $Sites = $Sites + ($AllSites | Where-Object Template -Match "SpsPers" | Where-Object Url -Match "/personal/") }
    If ($Teams) { $Sites = $Sites + ($AllSites | Where-Object Template -Match "Group") }
    If ($Channels) { $Sites = $Sites + ($AllSites | Where-Object Template -Match "TeamChannel") }

    Return $Sites | ForEach-Object {

        If ((Test-SharePointSite $_) -And (Test-HomeSite $_)) { $Type = "Home" }
        ElseIf ((Test-SharePointSite $_) -And -Not (Test-HomeSite $_)) { $Type = "SharePoint" }
        ElseIf (Test-OneDriveSite $_) { $Type = "OneDrive" }
        ElseIf (Test-TeamSite $_) { $Type = "Team" }
        ElseIf (Test-ChannelSite $_) { $Type = "Channel" }
        Else { $Type = "Unknown" }

        Add-Member -InputObject $_ -NotePropertyName "Type" -NotePropertyValue $Type -PassThru

    }
    
}

Function Get-SubSites {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Process {

        $Connection = Connect-Site $Site -Return -Silent
        Return Get-PnPSubWeb -Connection $Connection -Recurse

    }

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

Function Get-SubSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Parameter(Mandatory = $True)][String]$Identity
    )

    Process {

        $Connection = Connect-Site $Site -Return -Silent
        Return Get-PnPSubWeb -Identity $Identity -Connection $Connection -Recurse

    }

}

Function Test-SubSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Null -Ne $Site.ServerRelativeUrl

}

Function Test-HomeSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Site.Url.Replace("/", "").EndsWith(".sharepoint.com")

}

Function Test-LibrarySite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Site.Url.EndsWith("/Documentos") -Or $Site.Url.EndsWith("/Registros")

}

Function Test-ListsSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Return $Site.Url.EndsWith("/Controles")

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
        [Object]$Connection,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        $ParamConnection = $Connection
        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        Invoke-Operation -Message "Setting parameters to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            If ($Site.Type -Eq "OneDrive") { Start-Sleep -Milliseconds 50; Return }
            If (-Not $ParamConnection) { $Connection = Connect-Site $Site -Return -Silent } Else { $Connection = $ParamConnection }

            $SiteParams = @{
                DefaultLinkPermission                       = "View"
                DefaultLinkToExistingAccess                 = $True
                DefaultShareLinkRole                        = "View"
                DefaultShareLinkScope                       = "SpecificPeople"
                DefaultSharingLinkType                      = "Direct"
                DenyAddAndCustomizePages                    = $True
                DisableSharingForNonOwners                  = $True
                InheritVersionPolicyFromTenant              = $True
                ListsShowHeaderAndNavigation                = $True
                OverrideSharingCapability                   = $False
                OverrideTenantAnonymousLinkExpirationPolicy = $False
                OverrideTenantExternalUserExpirationPolicy  = $False
                SharingCapability                           = If ($Site.Type -Eq "Home") { "ExternalUserAndGuestSharing" } Else { "ExistingExternalUserSharingOnly" }
            }
            
            If (-Not (Test-SubSite $Site)) {

                Set-PnPTenantSite -Identity $Site.Url @SiteParams -Connection $Connection
                Disable-PnPSharingForNonOwnersOfSite -Identity $Site.Url -Connection $Connection

            }
            
            Set-PnPWeb -MembersCanShare:$False -DisablePowerAutomate:$False -CommentsOnSitePagesDisabled:$False -Connection $Connection
            
        }

        Get-SubSites $Site | Set-Site -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent

    }

}

Function Set-SiteAdmins {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        $ParamConnection = $Connection
        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $GlobalAdmin = "Administradores Globais"
        $OtherAdmins = $Null

    }

    Process {

        Invoke-Operation -Message "Setting administrators to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            If (-Not $ParamConnection) { $Connection = Connect-Site $Site -Return -Silent } Else { $Connection = $ParamConnection }

            If ($Site.Type -Eq "OneDrive") {

                If ($Site.LockState -Eq "ReadOnly") { Start-Sleep -Milliseconds 50; Return }
                Add-PnPSiteCollectionAdmin -Owners @($GlobalAdmin + $OtherAdmins) -Connection $Connection
                
            } Else {

                $SiteAdmins = Get-PnPSiteCollectionAdmin -Connection $Connection
                Add-PnPSiteCollectionAdmin -Owners $OtherAdmins -PrimarySiteCollectionAdmin $GlobalAdmin -Connection $Connection
                $SiteAdmins | Where-Object Title -NE $GlobalAdmin | Where-Object LoginName -NotIn ($OtherAdmins) | Remove-PnPSiteCollectionAdmin -Connection $Connection

            }
            
        }
        
    }

}

Function Set-SiteAppearance {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        $ParamConnection = $Connection
        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $TenantTheme = ConvertFrom-Json $Global:CurrentTenant.Theme -AsHashtable

    }

    Process {

        Invoke-Operation -Message "Setting appearance to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
            If (-Not $ParamConnection) { $Connection = Connect-Site $Site -Return -Silent } Else { $Connection = $ParamConnection }

            If (-Not (Get-PnPTenantTheme $TenantTheme.name)) {

                Remove-PnPTenantTheme -Identity $TenantTheme.name -Connection $Connection
                Add-PnPTenantTheme -Identity $TenantTheme.name -Palette $TenantTheme.palette -IsInverted $TenantTheme.isInverted -Overwrite -Connection $Connection

            }

            Set-PnPWebTheme -Theme $TenantTheme.name -Connection $Connection
            Set-PnPWeb -HeaderLayout "Standard" -HeaderEmphasis "None" -HideTitleInHeader:$False -QuickLaunchEnabled:$True -HorizontalQuickLaunch:$True -MegaMenuEnabled:$False -Connection $Connection
            Set-PnPWebHeader -HeaderLayout "Standard" -HeaderEmphasis "None" -HideTitleInHeader:$False -HeaderBackgroundImageUrl $Null -LogoAlignment Left -Connection $Connection
            Set-PnPFooter -Enabled:$False -Layout "Simple" -BackgroundTheme "Neutral" -Title $Null -LogoUrl $Null -Connection $Connection
            
        }

        Get-SubSites $Site | Set-SiteAppearance -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent
            
    }

}

Function Set-SiteHomePage {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        $ParamConnection = $Connection
        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

    }

    Process {

        Invoke-Operation -Message "Setting homepage to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            If ($Site.Type -In ("OneDrive") ) { Start-Sleep -Milliseconds 50; Return }
            If (-Not $ParamConnection) { $Connection = Connect-Site $Site -Return -Silent } Else { $Connection = $ParamConnection }
        
            $Pages = Get-PnPPage -Connection:$Connection
            $DefaultPage = $Pages | Where-Object Name -EQ "Home.aspx"
            If ($Pages -And -Not $DefaultPage) { $DefaultPage = $Pages[0] }

            $Libraries = Get-PnPList -Includes IsDefaultDocumentLibrary -Connection:$Connection | Where-Object { -Not $_.Hidden -And -Not $_.IsCatalog -And -Not $_.IsApplicationList -And $_.BaseType -Eq "DocumentLibrary" -And $_.DefaultViewUrl -Notlike "*Form*Templates*" -And $_.DefaultViewUrl -Notlike "*Wiki*Data*" }
            $DefaultLibrary = $Libraries | Where-Object IsDefaultDocumentLibrary -EQ $True
            If ($Libraries -And -Not $DefaultLibrary) { $DefaultLibrary = $Libraries[0] }
        
            If ((Test-TeamSite $Site) -Or (Test-ChannelSite $Site) -Or (Test-LibrarySite $Site)) {
            
                $FullUrl = "$($Global:CurrentTenant.BaseUrl)$($DefaultLibrary.DefaultViewUrl)"
                $RootUrl = $FullUrl.Replace($Site.Url, "")

                Set-PnPHomePage -RootFolderRelativeUrl $RootUrl -Connection:$Connection
        
            } Else {

                Set-PnPHomePage -RootFolderRelativeUrl "SitePages/$($DefaultPage.Name)" -Connection:$Connection

            }

        }

        Get-SubSites $Site | Set-SiteHomePage -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent
        
    }

}

Function Set-SiteNavigation {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Object]$Connection,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent,
        [Switch]$Reset,
        [Switch]$Force
    )

    Begin {

        $ParamConnection = $Connection
        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $EventsList = $Global:CurrentTenant.EventsID
        
    }

    Process {

        Invoke-Operation -Message "Setting navigation to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            If ($Site.Type -In ("OneDrive") ) { Start-Sleep -Milliseconds 50; Return }
            If (-Not $ParamConnection) { $Connection = Connect-Site $Site -Return -Silent } Else { $Connection = $ParamConnection }
            
            If ($Reset) {
                
                $Locations = @("TopNavigationBar", "QuickLaunch", "SearchNav", "Footer")
                ForEach ($Location in $Locations) { Get-PnPNavigationNode -Location $Location -Connection:$Connection | Remove-PnPNavigationNode -Force -Connection:$Connection }
                
            }

            If (Test-HomeSite $Site) {

                $Navigation = @(
                    @{ Title = "Início"; Url = "/"; First = $True }
                    @{ Title = "Notícias"; Url = "/_layouts/15/news.aspx" }
                    @{ Title = "Eventos"; Url = "/_layouts/15/Events.aspx?ListGuid=$($EventsList)&EndDate=2050-12-31" }
                    @{ Title = "Documentos"; Url = "/Documentos" }
                    @{ Title = "Registros"; Url = "/Registros" }
                    @{ Title = "Controles"; Url = "/Controles" }
                    @{ Title = "Arquivos Públicos"; Url = "/Publico" }
                    @{ Title = "Arquivos Pessoais"; Url = $Global:CurrentTenant.BaseUrl.Replace(".sharepoint.com", "-my.sharepoint.com/my"); External = $True }
                    @{ Title = "Arquivos de Equipes"; Url = "http://linkless.header/" }
                    @{ Title = "Aplicativos"; Url = "http://linkless.header/" }
                    @{ Title = "Configurações"; Url = "http://linkless.header/" }
                    @{ Title = "Site Comercial"; Url = "https://www.$($Global:CurrentTenant.Domain)"; External = $True; OpenInNewTab = $True }
                )

            } ElseIf ((Test-TeamSite $Site) -Or (Test-ChannelSite $Site)) {
                
                $Navigation = @(
                    @{ Title = "Arquivos"; Url = "$($Site.Url)/Documentos Compartilhados"; First = $True }
                )

            } ElseIf (Test-LibrarySite $Site) {

                If ($Site.Url -Like "*/Documentos") {

                    $Navigation = @(
                        @{ Title = "Documentos Atuais"; Url = "$($Site.Url)/Atuais"; First = $True }
                        @{ Title = "Documentos Obsoletos"; Url = "$($Site.Url)/Obsoletos" }
                    )

                } ElseIf ($Site.Url -Like "*/Registros") {

                    $Navigation = @(
                        @{ Title = "Registros Atuais"; Url = "$($Site.Url)/Atuais"; First = $True }
                        @{ Title = "Registros Obsoletos"; Url = "$($Site.Url)/Obsoletos" }
                    )

                } Else {

                    $Navigation = @(
                        @{ Title = "Arquivos"; Url = "$($Site.Url)/Documentos Compartilhados"; First = $True }
                    )

                }

            } Else {

                $Navigation = $Null

            }

            If ($Navigation) { 

                $CurrentItem = $Null
                $PreviousItem = $Null
                $Nodes = Get-PnPNavigationNode -Connection:$Connection

                ForEach ($Item In $Navigation) {

                    $CurrentItem = $Nodes | Where-Object Title -EQ $Item.Title
                    If ($CurrentItem -And $Force) { $CurrentItem | Remove-PnPNavigationNode -Force -Connection:$Connection }

                    If (-Not $CurrentItem -Or $Force) {

                        $PreviousItem = If ($PreviousItem) { 

                            Add-PnPNavigationNode @Item -Location "QuickLaunch" -PreviousNode $PreviousItem -Connection:$Connection 

                        } Else { 

                            Add-PnPNavigationNode @Item -Location "QuickLaunch" -Connection:$Connection 

                        }

                    } Else {

                        $PreviousItem = $CurrentItem

                    }

                }

            }

        }

        Get-SubSites $Site | Set-SiteNavigation -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Reset:$Reset -Force:$Force

    }

}
