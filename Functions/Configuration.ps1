# Config All
function Start-AllConfig {

	Start-TenantConfig
	Start-SitesConfig -Recurse

}

# Config Tenant
function Start-TenantConfig {

	if (-not (Test-TenantConnection)) { return }
    
	$Tenant = Get-Tenant
	$Tenant | Set-Tenant

}

# Config Site
function Start-SiteConfig {

	param(
		[Switch]$Recurse
	)
    
	$Site = Read-Host "Site"
	$Site = Get-Site $Site
	if ($Site) { Start-SitesConfig $Site -Recurse:$Recurse }

}

# Config Sites
function Start-SitesConfig {

	param(
		[Parameter(Mandatory = $True)][Object]$Sites,
		[Switch]$Recurse
	)
    
	# Check Connection
	if (-not (Test-TenantConnection)) { return }
    
	# Sort Sites
	$Sites = $Sites | Sort-Object Title
    
	# Process Sites
	foreach ($Site in $Sites) {

		$Site | Set-Site
		$Site | Set-SiteAdmins
		$Site | Set-SiteAppearance
		$Site | Set-SiteHomePage
		$Site | Set-SiteNavigation

		$Libraries = Get-Libraries $Site
		if ($Libraries) { Start-LibrariesConfig $Libraries }

		$Lists = Get-Lists $Site
		if ($Lists) { Start-ListsConfig $Lists }

		if ($Recurse) {

			$SubSites = Get-SubSites $Site
			Start-SitesConfig $SubSites -Recurse

		}
        
	}

}

# Config SubSite
function Start-SubSiteConfig {

	param(
		[Switch]$Recurse
	)
    
	$Site = Read-Host "Site"
	$Site = Get-Site $Site

	if ($Site) {

		$SubSite = Read-Host "SubSite"
		$SubSite = Get-SubSite $SubSite $Site
		if ($SubSite) { Start-SitesConfig $SubSite -Recurse:$Recurse }

	}

}

# Config SubSites
function Start-SubSitesConfig {

	param(
		[Object]$SubSites,
		[Switch]$Recurse
	)
    
	# Check Connection
	if (-not (Test-TenantConnection)) { return }
    
	# Check Parameter
	if ($SubSites) {

		Start-SitesConfig $SubSites -Recurse:$Recurse

	} else {

		$Site = Read-Host "Site"
		$Site = Get-Site $Site

		if ($Site) {

			$SubSites = Get-SubSites $Site
			if ($SubSites) { Start-SubSitesConfig $SubSites }

		}

	}

}

# Config Library
function Start-LibraryConfig {

	$Site = Read-Host "Site"
	$Site = Get-Site $Site

	if ($Site) {

		$Library = Read-Host "Library"
		$Library = Get-Library $Library $Site
		if ($Library) { Start-LibrariesConfig $Library }

	}

}

# Config Libraries
function Start-LibrariesConfig {

	param(
		[Object]$Libraries
	)
    
	# Check Connection
	if (-not (Test-TenantConnection)) { return }
    
	# Check Parameter
	if ($Libraries) {

		$Libraries = $Libraries | Sort-Object Title
		foreach ($Library in $Libraries) {

			$Fields = Get-Fields $Library
			$Views = Get-Views $Library

			$Library | Set-Library
			$Fields | Set-Field
			$Views | Set-View

		}

	} else {

		$Site = Read-Host "Site"
		$Site = Get-Site $Site

		if ($Site) {

			$Libraries = Get-Libraries $Site
			if ($Libraries) { Start-LibrariesConfig $Libraries }

		}

	}

}

# Config List
function Start-ListConfig {

	$Site = Read-Host "Site"
	$Site = Get-Site $Site

	if ($Site) {

		$List = Read-Host "List"
		$List = Get-List $List $Site
		if ($List) { Start-ListsConfig $List }

	}

}

# Config Lists
function Start-ListsConfig {

	param(
		[Object]$Lists
	)
    
	# Check Connection
	if (-not (Test-TenantConnection)) { return }
    
	# Check Parameter
	if ($Lists) {

		$Lists = $Lists | Sort-Object Title
		foreach ($List in $Lists) {

			$Fields = Get-Fields $List
			$Views = Get-Views $List

			$List | Set-List
			$Fields | Set-Field
			$Views | Set-View

		}

	} else {

		$Site = Read-Host "Site"
		$Site = Get-Site $Site

		if ($Site) {
            
			$Lists = Get-Lists $Site
			if ($Lists) { Start-ListsConfig $Lists }

		}

	}

}
