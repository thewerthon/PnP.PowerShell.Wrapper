# Config All
Function Start-AllConfig {

    Start-TenantConfig
    Start-SitesConfig -Recurse

}

# Config Tenant
Function Start-TenantConfig {

    If (-Not (Test-TenantConnection)) { Return }
    
    $Tenant = Get-Tenant
    $Tenant | Set-Tenant

}

# Config Site
Function Start-SiteConfig {

    Param(
        [Switch]$Recurse
    )
    
    $Site = Read-Host "Site"
    $Site = Get-Site $Site
    If ($Site) { Start-SitesConfig $Site -Recurse:$Recurse }

}

# Config Sites
Function Start-SitesConfig {

    Param(
        [Parameter(Mandatory = $True)][Object]$Sites,
        [Switch]$Recurse
    )
    
    # Check Connection
    If (-Not (Test-TenantConnection)) { Return }
    
    # Sort Sites
    $Sites = $Sites | Sort-Object Title
    
    # Process Sites
    ForEach ($Site In $Sites) {

        $Site | Set-Site
        $Site | Set-SiteAdmins
        $Site | Set-SiteAppearance
        $Site | Set-SiteHomePage
        $Site | Set-SiteNavigation

        $Libraries = Get-Libraries $Site
        If ($Libraries) { Start-LibrariesConfig $Libraries }

        $Lists = Get-Lists $Site
        If ($Lists) { Start-ListsConfig $Lists }

        If ($Recurse) {

            $SubSites = Get-SubSites $Site
            Start-SitesConfig $SubSites -Recurse

        }
        
    }

}

# Config SubSite
Function Start-SubSiteConfig {

    Param(
        [Switch]$Recurse
    )
    
    $Site = Read-Host "Site"
    $Site = Get-Site $Site

    If ($Site) {

        $SubSite = Read-Host "SubSite"
        $SubSite = Get-SubSite $SubSite $Site
        If ($SubSite) { Start-SitesConfig $SubSite -Recurse:$Recurse }

    }

}

# Config SubSites
Function Start-SubSitesConfig {

    Param(
        [Object]$SubSites,
        [Switch]$Recurse
    )
    
    # Check Connection
    If (-Not (Test-TenantConnection)) { Return }
    
    # Check Parameter
    If ($SubSites) {

        Start-SitesConfig $SubSites -Recurse:$Recurse

    } Else {

        $Site = Read-Host "Site"
        $Site = Get-Site $Site

        If ($Site) {

            $SubSites = Get-SubSites $Site
            If ($SubSites) { Start-SubSitesConfig $SubSites }

        }

    }

}

# Config Library
Function Start-LibraryConfig {

    $Site = Read-Host "Site"
    $Site = Get-Site $Site

    If ($Site) {

        $Library = Read-Host "Library"
        $Library = Get-Library $Library $Site
        If ($Library) { Start-LibrariesConfig $Library }

    }

}

# Config Libraries
Function Start-LibrariesConfig {

    Param(
        [Object]$Libraries
    )
    
    # Check Connection
    If (-Not (Test-TenantConnection)) { Return }
    
    # Check Parameter
    If ($Libraries) {

        $Libraries = $Libraries | Sort-Object Title
        ForEach ($Library In $Libraries) {

            $Fields = Get-Fields $Library
            $Views = Get-Views $Library

            $Library | Set-Library
            $Fields | Set-Field
            $Views | Set-View

        }

    } Else {

        $Site = Read-Host "Site"
        $Site = Get-Site $Site

        If ($Site) {

            $Libraries = Get-Libraries $Site
            If ($Libraries) { Start-LibrariesConfig $Libraries }

        }

    }

}

# Config List
Function Start-ListConfig {

    $Site = Read-Host "Site"
    $Site = Get-Site $Site

    If ($Site) {

        $List = Read-Host "List"
        $List = Get-List $List $Site
        If ($List) { Start-ListsConfig $List }

    }

}

# Config Lists
Function Start-ListsConfig {

    Param(
        [Object]$Lists
    )
    
    # Check Connection
    If (-Not (Test-TenantConnection)) { Return }
    
    # Check Parameter
    If ($Lists) {

        $Lists = $Lists | Sort-Object Title
        ForEach ($List In $Lists) {

            $Fields = Get-Fields $List
            $Views = Get-Views $List

            $List | Set-List
            $Fields | Set-Field
            $Views | Set-View

        }

    } Else {

        $Site = Read-Host "Site"
        $Site = Get-Site $Site

        If ($Site) {
            
            $Lists = Get-Lists $Site
            If ($Lists) { Start-ListsConfig $Lists }

        }

    }

}
