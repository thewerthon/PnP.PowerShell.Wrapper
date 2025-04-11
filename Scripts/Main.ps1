# Clear Host
Clear-Host

# Dot Sourcing
Get-ChildItem -Path (Join-Path -Path "$PSScriptRoot" -ChildPath "..")
| Where-Object Name -Match "Functions"
| Get-ChildItem -Filter "*.ps1"
| ForEach-Object { . $_.FullName }

# Get-Tenant
$Tenant = Get-Tenant "intec"uydz
Connect-Tenant $Tenant
# Set-Tenant $Tenant

# Get Sites
$Sites = Get-Sites -SharePoint -OneDrive -Groups -Channels -Silent
$Start = $Sites | Where-Object Type -EQ "Home" | Sort-Object Title
$SharePoint = $Sites | Where-Object Type -EQ "SharePoint" | Sort-Object Title
$SubSites = If ($Start) { Get-SubSites $Start[0] | Sort-Object Title } Else { $Null }
$OneDrive = $Sites | Where-Object Type -EQ "OneDrive" | Sort-Object Title
$Groups = $Sites | Where-Object Type -EQ "Group" | Sort-Object Title
$Channels = $Sites | Where-Object Type -EQ "Channel" | Sort-Object Title

# Get Locations
$Locations = @()
if ($Start) { $Locations += $Start }
if ($SharePoint) { $Locations += $SharePoint }
if ($SubSites) { $Locations += $SubSites }
if ($Groups) { $Locations += $Groups }
if ($Channels) { $Locations += $Channels }

# Process Home Site
ForEach ($Site In $Start) {

    $Site | Set-Site
    $Site | Set-SiteAdmins
    $Site | Set-SiteAppearance
    $Site | Set-SiteHomePage
    $Site | Set-SiteNavigation

}

# Process SharePoint Sites
ForEach ($Site In $SharePoint) {

    $Site | Set-Site
    $Site | Set-SiteAdmins
    $Site | Set-SiteAppearance
    $Site | Set-SiteHomePage
    $Site | Set-SiteNavigation

}

# Process Sub Sites
ForEach ($Site In $SubSites) {
    
    $Site | Set-SubSite
    $Site | Set-SubSiteAppearance
    $Site | Set-SubSiteHomePage
    $Site | Set-SubSiteNavigation

}

# Process OneDrive Sites
ForEach ($Site In $OneDrive) {

    $Site | Set-SiteAdmins
    
}

# Process Groups Sites
ForEach ($Site In $Groups) {

    $Site | Set-Site
    $Site | Set-SiteAdmins
    $Site | Set-SiteAppearance
    $Site | Set-SiteHomePage
    $Site | Set-SiteNavigation

}

# Process Channels Sites
ForEach ($Site In $Channels) {

    $Site | Set-Site
    $Site | Set-SiteAdmins
    $Site | Set-SiteAppearance
    $Site | Set-SiteHomePage
    $Site | Set-SiteNavigation

}

# Process Libraries
ForEach ($Site In $Sites) {

    $Libraries = Get-Libraries $Site
    $Libraries | Set-Library

}

# Process Lists
ForEach ($Site In $Sites) {

    $Lists = Get-Lists $Site
    $Lists | Set-List
    
}

# Process Fields
ForEach ($Site In $Sites) {

    $Items = @(Get-Libraries $Site) + @(Get-Lists $Site)

    ForEach ($Item In $Items) {

        $Fields = Get-Fields $Item
        $Fields | Set-Field

    }

}

# Process Views
ForEach ($Site In $Sites) {

    $Items = @(Get-Libraries $Site) + @(Get-Lists $Site)

    ForEach ($Item In $Items) {

        $Views = Get-Views $Item
        $Views | Set-View

    }

}
