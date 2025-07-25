function Test-Site {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Silent
	)

	try {

		if (-not ((Test-SingleObject $Site -Silent:$Silent) -and (Test-Properties $Site Url, Title -Silent:$Silent))) {

			Write-Message "Invalid site." -Color "Red" -Silent:$Silent
			return $False

		} else {

			return $True

		}

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-SiteConnection {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site = $Global:CurrentSite,
		[Switch]$Silent
	)
    
	try {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return $False }
		if (-not (Test-Site $Site -Silent:$Silent)) { return $False }

		if (Test-Object $Global:CurrentSite -Silent:$Silent) {

			if ($Site -eq $Global:CurrentSite ) {

				return $True

			} else {

				Write-Message "Not connected to $($Site.Title) site." -Color "Red" -Silent:$Silent
				return $False

			}

		} else {

			Write-Message "Not connected to a site." -Color "Red" -Silent:$Silent
			return $False

		}

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Connect-Site {

	param (
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Return,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	process {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }
		if (-not (Test-Site $Site -Silent:$Silent)) { return }
        
		Invoke-Operation "Connecting to site: $($Site.Title)" -Return:$Return -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

			$Password = ConvertTo-SecureString -String $Global:CurrentTenant.Domain -AsPlainText -Force
			$Certificate = Get-ChildItem -Path (Get-Path("Certificates")) -Recurse | Where-Object Name -Like "$($Global:CurrentTenant.Name).pfx"
			Connect-PnPOnline -Tenant $Global:CurrentTenant.Domain -Url $Site.Url -ClientId $Global:CurrentTenant.ClientID -CertificatePath $Certificate.FullName -CertificatePassword $Password -ReturnConnection:$Return
			if (-not $Return) { Set-Variable -Name "CurrentSite" -Value $Site -Scope Global }

		}

	}

}

function Disconnect-Site {

	param (
		[Parameter(ValueFromPipeline = $True)][Object]$Site = $Global:CurrentSite,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	if (-not (Test-TenantConnection -Silent:$Silent)) { return }
	if (-not (Test-SiteConnection $Site -Silent:$Silent)) { return }

	Invoke-Operation -Message "Disconnecting from site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

		$Password = ConvertTo-SecureString -String $Global:CurrentTenant.Domain -AsPlainText -Force
		$Certificate = Get-ChildItem -Path (Get-Path("Certificates")) -Recurse | Where-Object Name -Like "$($Global:CurrentTenant.Name).pfx"
		Connect-PnPOnline -Tenant $Global:CurrentTenant.Domain -Url $Global:CurrentTenant.AdminUrl -ClientId $Global:CurrentTenant.ClientID -CertificatePath $Certificate.FullName -CertificatePassword $Password -ReturnConnection:$Return
		Set-Variable -Name "CurrentSite" -Value (Get-PnPTenantSite $Global:CurrentTenant.AdminUrl) -Scope Global

	}

}

function Get-Sites {

	param(
		[Switch]$SharePoint,
		[Switch]$OneDrive,
		[Switch]$Groups,
		[Switch]$Teams,
		[Switch]$Channels,
		[Switch]$Silent,
		[Switch]$All
	)

	if (-not (Test-TenantConnection -Silent:$Silent)) { return }

	$Sites = @()
	$AllSites = Get-PnPTenantSite -IncludeOneDriveSites

	if (-not ($SharePoint -or $OneDrive -or $Groups -or $Teams -or $Channels)) { $All = $True }

	if ($SharePoint -or $All) {
        
		$TempSites = $AllSites | Where-Object Template -Match "SitePage" | Where-Object Url -NotMatch "/marca"
		$TempSites = $TempSites | ForEach-Object { $_ | Add-Member -NotePropertyName "Type" -NotePropertyValue ($(if (Test-HomeSite $_) { "Home" } else { "SharePoint" })) -PassThru }
		$Sites += $TempSites
    
	}

	if ($OneDrive -or $All) {
        
		$TempSites = $AllSites | Where-Object Template -Match "SpsPers" | Where-Object Url -Match "/personal/"
		$TempSites = $TempSites | ForEach-Object { $_ | Add-Member -NotePropertyName "Type" -NotePropertyValue "OneDrive" -PassThru }
		$Sites += $TempSites
    
	}
    
	if ($Groups -or $Teams -or $All) {
        
		if ($Groups -or $All) {

			$TempSites = $AllSites | Where-Object Template -Match "Group"
			$TempSites = $TempSites | ForEach-Object { $_ | Add-Member -NotePropertyName "Type" -NotePropertyValue "Group" -PassThru }
			$Sites += $TempSites
            
		} elseif ($Teams) {

			$TempSites = $AllSites | Where-Object Template -Match "Group" | Where-Object Url -NotLike "*/*.membros" | Where-Object Url -NotLike "*/*engage*" | Where-Object Url -NotLike "*/*yammer*" | Where-Object Url -NotLike "*/*admin*" | Where-Object Url -NotLike "*//*/$($Global:CurrentTenant.Slug)*"
			$TempSites = $TempSites | ForEach-Object { $_ | Add-Member -NotePropertyName "Type" -NotePropertyValue "Team" -PassThru }
			$Sites += $TempSites
            
		}
    
	}

	if ($Channels -or $All) {
        
		$TempSites = $AllSites | Where-Object Template -Match "TeamChannel"
		$TempSites = $TempSites | ForEach-Object { $_ | Add-Member -NotePropertyName "Type" -NotePropertyValue "Channel" -PassThru }
		$Sites += $TempSites
    
	}

	return $Sites
    
}

function Get-Site {

	param(
		[Parameter(ValueFromPipeline = $True)][String]$Identity
	)

	process {

		if ($Identity) {

			$Site = Get-Sites | Where-Object { $_.SiteId -like $Identity -or $_.Url -like $Identity -or $_.Title -like $Identity }

		} else {

			$Site = $Global:CurrentTenant

		}

		if ($Site) { return $Site[0] }

	}

}

function Test-HomeSite {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Silent
	)

	try {

		return $Site.Url.Replace("/", "").EndsWith(".sharepoint.com")

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-LibrarySite {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Silent
	)

	try {

		return $Site.Url.EndsWith("/Documentos") -or $Site.Url.EndsWith("/Registros")

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-ListsSite {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Silent
	)

	try {

		return $Site.Url.EndsWith("/Controles")

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-SharePointSite {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Silent
	)

	try {

		return $Site.Template -match "SitePage"

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-OneDriveSite {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Silent
	)

	try {

		return $Site.Template -match "SpsPers" -and $Site.Url -match "/personal/"

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-TeamSite {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Silent
	)

	try {

		return $Site.Template -match "Group"

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-ChannelSite {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Silent
	)

	try {

		return $Site.Template -match "TeamChannel"

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Set-Site {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }
        
	}

	process {

		if ($Site.Type -eq "OneDrive") { Start-Sleep -Milliseconds 50; return }

		Invoke-Operation -Message "Setting parameters to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

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
            
			if ($Site.Type -eq "Home") { 
                
				$SiteParams.SharingCapability = "ExternalUserAndGuestSharing"
            
			}
            
			if (-not $Site.ParentSite) {

				Set-PnPTenantSite -Identity $Site.Url @SiteParams -Connection $Connection
				Disable-PnPSharingForNonOwnersOfSite -Identity $Site.Url -Connection $Connection

			}
            
			Set-PnPWeb -MembersCanShare:$False -DisablePowerAutomate:$False -CommentsOnSitePagesDisabled:$False -Connection $Connection
            
		}

	}

}

function Set-SiteAdmins {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent,
		[Switch]$Clear
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }

		$GlobalAdmin = "Administradores Globais"
		$OtherAdmins = $Null

	}

	process {

		if ($Site.ParentSite) { Start-Sleep -Milliseconds 50; return }

		Invoke-Operation -Message "Setting administrators to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

			$Connection = Connect-Site $Site -Return -Silent

			if ($Site.Type -eq "OneDrive") {

				if ($Site.LockState -eq "ReadOnly") { Start-Sleep -Milliseconds 50; return }
				Add-PnPSiteCollectionAdmin -Owners @($GlobalAdmin + $OtherAdmins) -PrimarySiteCollectionAdmin $Site.Owner -Connection $Connection
				if ($Clear) { Get-PnPSiteCollectionAdmin -Connection $Connection | Where-Object Title -NE $GlobalAdmin | Where-Object Email -NotIn ($OtherAdmins + $Site.Owner) | Remove-PnPSiteCollectionAdmin -Connection $Connection }

			} else {

				Add-PnPSiteCollectionAdmin -Owners $OtherAdmins -PrimarySiteCollectionAdmin $GlobalAdmin -Connection $Connection
				if ($Clear) { Get-PnPSiteCollectionAdmin -Connection $Connection | Where-Object Title -NE $GlobalAdmin | Where-Object Email -NotIn ($OtherAdmins) | Remove-PnPSiteCollectionAdmin -Connection $Connection }

			}
            
		}
        
	}

}

function Set-SiteAppearance {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }

		$TenantTheme = ConvertFrom-Json $Global:CurrentTenant.Theme -AsHashtable

	}

	process {

		if ($Site.Type -in ("OneDrive") ) { Start-Sleep -Milliseconds 50; return }
        
		Invoke-Operation -Message "Setting appearance to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
			$Connection = Connect-Site $Site -Return -Silent

			if (-not (Get-PnPTenantTheme $TenantTheme.name -ErrorAction Ignore)) {
                
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

function Set-SiteHomePage {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }

	}

	process {

		if ($Site.Type -in ("OneDrive") ) { Start-Sleep -Milliseconds 50; return }
        
		Invoke-Operation -Message "Setting homepage to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

			$Connection = Connect-Site $Site -Return -Silent
        
			$Pages = Get-PnPPage -Connection:$Connection
			$DefaultPage = $Pages | Where-Object Name -EQ "Home.aspx"
			if ($Pages -and -not $DefaultPage) { $DefaultPage = $Pages[0] }

			$Libraries = Get-PnPList -Includes IsDefaultDocumentLibrary -Connection:$Connection | Where-Object { -not $_.Hidden -and -not $_.IsCatalog -and -not $_.IsApplicationList -and $_.BaseType -eq "DocumentLibrary" -and $_.DefaultViewUrl -notlike "*Form*Templates*" -and $_.DefaultViewUrl -notlike "*Wiki*Data*" }
			$DefaultLibrary = $Libraries | Where-Object IsDefaultDocumentLibrary -EQ $True
			if ($Libraries -and -not $DefaultLibrary) { $DefaultLibrary = $Libraries[0] }
        
			if ((Test-TeamSite $Site -Silent:$Silent) -or (Test-ChannelSite $Site -Silent:$Silent) -or (Test-LibrarySite $Site -Silent:$Silent)) {
            
				$FullUrl = "$($Global:CurrentTenant.BaseUrl)$($DefaultLibrary.DefaultViewUrl)"
				$RootUrl = $FullUrl.Replace($Site.Url, "")

				Set-PnPHomePage -RootFolderRelativeUrl $RootUrl -Connection:$Connection
        
			} else {

				Set-PnPHomePage -RootFolderRelativeUrl "SitePages/$($DefaultPage.Name)" -Connection:$Connection

			}

		}

	}

}

function Set-SiteNavigation {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }

		$AdminGroup = Get-PnPEntraIDGroup -Identity "Administradores Globais"
		$EventsList = $Global:CurrentTenant.EventsID
        
	}

	process {

		if ($Site.Type -in ("OneDrive") ) { Start-Sleep -Milliseconds 50; return }
        
		Invoke-Operation -Message "Setting navigation to site: $($Site.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

			$Connection = Connect-Site $Site -Return -Silent
        
			$Navigation = $Null
			$TeamsNavigation = $Null
			$Locations = @("TopNavigationBar", "QuickLaunch", "SearchNav", "Footer")

			foreach ($Location in $Locations) {
                
				Get-PnPNavigationNode -Location $Location -Connection:$Connection | Remove-PnPNavigationNode -Force -Connection:$Connection
            
			}

			if (Test-HomeSite $Site -Silent:$Silent) {

				$Navigation = @(
					@{ Title = "Início"; Url = "/"; First = $True }
					@{ Title = "Notícias"; Url = "/_layouts/15/news.aspx" }
					@{ Title = "Eventos"; Url = "/_layouts/15/Events.aspx?ListGuid=$($EventsList)&EndDate=2050-12-31" }
					@{ Title = "Documentos"; Url = "/Documentos" }
					@{ Title = "Registros"; Url = "/Registros" }
					@{ Title = "Controles"; Url = "/Controles" }
					@{ Title = "Identidade"; Url = "/Identidade" }
					@{ Title = "Arquivos Públicos"; Url = "/Publico" }
					@{ Title = "Arquivos Pessoais"; Url = $Global:CurrentTenant.BaseUrl.Replace(".sharepoint.com", "-my.sharepoint.com/my"); External = $True }
					@{ Title = "Arquivos de Equipes"; Url = "http://linkless.header/" }
					@{ Title = "Site Comercial"; Url = "https://www.$($Global:CurrentTenant.Domain)"; External = $True; OpenInNewTab = $True }
				)

				$TeamsNavigation = Get-Sites -Teams | Sort-Object Title | ForEach-Object {

					@{
						Title       = $_.Title
						Url         = $_.Url
						External    = $True
						AudienceIds = @($AdminGroup.Id, $_.RelatedGroupId)
					}

				}

			}
            
			if ((Test-TeamSite $Site -Silent:$Silent) -or (Test-ChannelSite $Site -Silent:$Silent)) {
                
				$Navigation = @(
					@{ Title = "Arquivos"; Url = "$($Site.Url)/Documentos Compartilhados"; First = $True }
				)

			}
            
			if (Test-LibrarySite $Site -Silent:$Silent) {

				$Navigation = @(
					@{ Title = "Arquivos"; Url = "$($Site.Url)/Documentos Compartilhados"; First = $True }
				)

				if ($Site.Url -like "*/Documentos") {

					$Navigation = @(
						@{ Title = "Atuais"; Url = "$($Site.Url)/Atuais"; First = $True }
						@{ Title = "Obsoletos"; Url = "$($Site.Url)/Obsoletos" }
					)

				}
                
				if ($Site.Url -like "*/Registros") {

					$Navigation = @(
						@{ Title = "Atuais"; Url = "$($Site.Url)/Atuais"; First = $True }
						@{ Title = "Obsoletos"; Url = "$($Site.Url)/Obsoletos" }
					)

				}

			}

			if ($Navigation) {

				foreach ($Item in $Navigation) {

					Add-PnPNavigationNode @Item -Location "QuickLaunch" -Connection:$Connection | Out-Null

				}

			}

			if ($TeamsNavigation) {

				$ParentNode = Get-PnPNavigationNode -Location "QuickLaunch" -Connection:$Connection | Where-Object Title -EQ "Arquivos de Equipes"
				if (-not $ParentNode) { return }

				foreach ($Item in $TeamsNavigation) {

					Add-PnPNavigationNode @Item -Parent $ParentNode.Id -Location "QuickLaunch" -Connection:$Connection | Out-Null
                    
				}

			}

		}

	}

}
