Function Test-Site {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $Site -Silent:$Silent) -And (Test-Properties $Site Url, Title -Silent:$Silent))) {

            Write-Message "Invalid site." -Color "Red" -Silent:$Silent
            Return $False

        } Else {

            Return $True

        }

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-SiteConnection {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site = $Global:CurrentSite,
        [Switch]$Silent
    )
    
    Try {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return $False }
        If (-Not (Test-Site $Site -Silent:$Silent)) { Return $False }

        If (Test-Object $Global:CurrentSite -Silent:$Silent) {

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

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
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
            $Certificate = Get-ChildItem -Path (Get-Path("Certificates")) -Recurse | Where-Object Name -Like "$($Global:CurrentTenant.Name).pfx"
            Connect-PnPOnline -Tenant $Global:CurrentTenant.Domain -Url $Site.Url -ClientId $Global:CurrentTenant.ClientID -CertificatePath $Certificate.FullName -CertificatePassword $Password -ReturnConnection:$Return
            If (-Not $Return) { Set-Variable -Name "CurrentSite" -Value $Site -Scope Global }

        }

    }

}

Function Disconnect-Site {

    Param (
        [Parameter(ValueFromPipeline = $True)][Object]$Site = $Global:CurrentSite,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
    If (-Not (Test-SiteConnection $Site -Silent:$Silent)) { Return }

    Invoke-Operation -Message "Disconnecting from site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

        $Password = ConvertTo-SecureString -String $Global:CurrentTenant.Domain -AsPlainText -Force
        $Certificate = Get-ChildItem -Path (Get-Path("Certificates")) -Recurse | Where-Object Name -Like "$($Global:CurrentTenant.Name).pfx"
        Connect-PnPOnline -Tenant $Global:CurrentTenant.Domain -Url $Global:CurrentTenant.AdminUrl -ClientId $Global:CurrentTenant.ClientID -CertificatePath $Certificate.FullName -CertificatePassword $Password -ReturnConnection:$Return
        Set-Variable -Name "CurrentSite" -Value (Get-PnPTenantSite $Global:CurrentTenant.AdminUrl) -Scope Global

    }

}

Function Get-Sites {

    Param(
        [Switch]$SharePoint,
        [Switch]$OneDrive,
        [Switch]$Teams,
        [Switch]$Channels,
        [Switch]$Silent
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

        If ((Test-SharePointSite $_ -Silent:$Silent) -And (Test-HomeSite $_ -Silent:$Silent)) { $Type = "Home" }
        ElseIf ((Test-SharePointSite $_ -Silent:$Silent) -And -Not (Test-HomeSite $_ -Silent:$Silent)) { $Type = "SharePoint" }
        ElseIf (Test-OneDriveSite $_ -Silent:$Silent) { $Type = "OneDrive" }
        ElseIf (Test-TeamSite $_ -Silent:$Silent) { $Type = "Team" }
        ElseIf (Test-ChannelSite $_ -Silent:$Silent) { $Type = "Channel" }
        Else { $Type = "Unknown" }

        $_
        | Add-Member -NotePropertyName "Type" -NotePropertyValue $Type -PassThru
        

    }
    
}

Function Get-Site {

    Param(
        [Parameter(ValueFromPipeline = $True)][String]$Identity
    )

    Process {

        If ($Identity) {

            $Site = Get-Sites | Where-Object { $_.SiteId -EQ $Identity -Or $_.Url -EQ $Identity -Or $_.Title -EQ $Identity }

        } Else {

            $Site = $Global:CurrentTenant

        }

        If ($Site) { Return $Site[0] }

    }

}

Function Test-HomeSite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        Return $Site.Url.Replace("/", "").EndsWith(".sharepoint.com")

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-LibrarySite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        Return $Site.Url.EndsWith("/Documentos") -Or $Site.Url.EndsWith("/Registros")

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-ListsSite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        Return $Site.Url.EndsWith("/Controles")

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-SharePointSite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        Return $Site.Template -Match "SitePage"

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-OneDriveSite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        Return $Site.Template -Match "SpsPers" -And $Site.Url -Match "/personal/"

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-TeamSite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        Return $Site.Template -Match "Group"

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-ChannelSite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        Return $Site.Template -Match "TeamChannel"

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Set-Site {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent,
        [Switch]$SubSites
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        Invoke-Operation -Message "Setting parameters to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            If ($Site.Type -Eq "OneDrive") { Start-Sleep -Milliseconds 50; Return }
            $Connection = Connect-Site $Site -Return -Silent

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
                SharingCapability                           = "ExistingExternalUserSharingOnly"
            }
            
            If ($Site.Type -Eq "Home") { 
                
                $SiteParams.SharingCapability = "ExternalUserAndGuestSharing"
            
            }

            If (-Not $SubSites) {

                Set-PnPTenantSite -Identity $Site.Url @SiteParams -Connection $Connection
                Disable-PnPSharingForNonOwnersOfSite -Identity $Site.Url -Connection $Connection

            }
            
            Set-PnPWeb -MembersCanShare:$False -DisablePowerAutomate:$False -CommentsOnSitePagesDisabled:$False -Connection $Connection
            
        }

    }

}

Function Set-SiteAdmins {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $GlobalAdmin = "Administradores Globais"
        $OtherAdmins = $Null

    }

    Process {

        Invoke-Operation -Message "Setting administrators to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            $Connection = Connect-Site $Site -Return -Silent

            If ($Site.Type -Eq "OneDrive") {

                If ($Site.LockState -Eq "ReadOnly") { Start-Sleep -Milliseconds 50; Return }
                Add-PnPSiteCollectionAdmin -Owners @($GlobalAdmin + $OtherAdmins) -PrimarySiteCollectionAdmin $Sites.Owner -Connection $Connection
                
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
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $TenantTheme = ConvertFrom-Json $Global:CurrentTenant.Theme -AsHashtable

    }

    Process {

        Invoke-Operation -Message "Setting appearance to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
            $Connection = Connect-Site $Site -Return -Silent

            If (-Not (Get-PnPTenantTheme $TenantTheme.name)) {

                Remove-PnPTenantTheme -Identity $TenantTheme.name -Connection $Connection
                Add-PnPTenantTheme -Identity $TenantTheme.name -Palette $TenantTheme.palette -IsInverted $TenantTheme.isInverted -Overwrite -Connection $Connection

            }

            Set-PnPWebTheme -Theme $TenantTheme.name -Connection $Connection
            Set-PnPWeb -HeaderLayout "Standard" -HeaderEmphasis "None" -HideTitleInHeader:$False -QuickLaunchEnabled:$True -HorizontalQuickLaunch:$True -MegaMenuEnabled:$False -Connection $Connection
            Set-PnPWebHeader -HeaderLayout "Standard" -HeaderEmphasis "None" -HideTitleInHeader:$False -HeaderBackgroundImageUrl $Null -LogoAlignment Left -Connection $Connection
            Set-PnPFooter -Enabled:$False -Layout "Simple" -BackgroundTheme "Neutral" -Title $Null -LogoUrl $Null -Connection $Connection
            
        }
 
    }

}

Function Set-SiteHomePage {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

    }

    Process {

        Invoke-Operation -Message "Setting homepage to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            If ($Site.Type -In ("OneDrive") ) { Start-Sleep -Milliseconds 50; Return }
            $Connection = Connect-Site $Site -Return -Silent
        
            $Pages = Get-PnPPage -Connection:$Connection
            $DefaultPage = $Pages | Where-Object Name -EQ "Home.aspx"
            If ($Pages -And -Not $DefaultPage) { $DefaultPage = $Pages[0] }

            $Libraries = Get-PnPList -Includes IsDefaultDocumentLibrary -Connection:$Connection | Where-Object { -Not $_.Hidden -And -Not $_.IsCatalog -And -Not $_.IsApplicationList -And $_.BaseType -Eq "DocumentLibrary" -And $_.DefaultViewUrl -Notlike "*Form*Templates*" -And $_.DefaultViewUrl -Notlike "*Wiki*Data*" }
            $DefaultLibrary = $Libraries | Where-Object IsDefaultDocumentLibrary -EQ $True
            If ($Libraries -And -Not $DefaultLibrary) { $DefaultLibrary = $Libraries[0] }
        
            If ((Test-TeamSite $Site -Silent:$Silent) -Or (Test-ChannelSite $Site -Silent:$Silent) -Or (Test-LibrarySite $Site -Silent:$Silent)) {
            
                $FullUrl = "$($Global:CurrentTenant.BaseUrl)$($DefaultLibrary.DefaultViewUrl)"
                $RootUrl = $FullUrl.Replace($Site.Url, "")

                Set-PnPHomePage -RootFolderRelativeUrl $RootUrl -Connection:$Connection
        
            } Else {

                Set-PnPHomePage -RootFolderRelativeUrl "SitePages/$($DefaultPage.Name)" -Connection:$Connection

            }

        }

    }

}

Function Set-SiteNavigation {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent,
        [Switch]$Reset,
        [Switch]$Force
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

        $EventsList = $Global:CurrentTenant.EventsID
        
    }

    Process {

        Invoke-Operation -Message "Setting navigation to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

            If ($Site.Type -In ("OneDrive") ) { Start-Sleep -Milliseconds 50; Return }
            $Connection = Connect-Site $Site -Return -Silent
            
            If ($Reset) {
                
                $Locations = @("TopNavigationBar", "QuickLaunch", "SearchNav", "Footer")
                ForEach ($Location in $Locations) { Get-PnPNavigationNode -Location $Location -Connection:$Connection | Remove-PnPNavigationNode -Force -Connection:$Connection }
                
            }

            If (Test-HomeSite $Site -Silent:$Silent) {

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

            }
            
            If ((Test-TeamSite $Site -Silent:$Silent) -Or (Test-ChannelSite $Site -Silent:$Silent)) {
                
                $Navigation = @(
                    @{ Title = "Arquivos"; Url = "$($Site.Url)/Documentos Compartilhados"; First = $True }
                )

            }
            
            If (Test-LibrarySite $Site -Silent:$Silent -Silent:$Silent) {

                $Navigation = @(
                    @{ Title = "Arquivos"; Url = "$($Site.Url)/Documentos Compartilhados"; First = $True }
                )

                If ($Site.Url -Like "*/Documentos") {

                    $Navigation = @(
                        @{ Title = "Documentos Atuais"; Url = "$($Site.Url)/Atuais"; First = $True }
                        @{ Title = "Documentos Obsoletos"; Url = "$($Site.Url)/Obsoletos" }
                    )

                }
                
                If ($Site.Url -Like "*/Registros") {

                    $Navigation = @(
                        @{ Title = "Registros Atuais"; Url = "$($Site.Url)/Atuais"; First = $True }
                        @{ Title = "Registros Obsoletos"; Url = "$($Site.Url)/Obsoletos" }
                    )

                }

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

    }

}
