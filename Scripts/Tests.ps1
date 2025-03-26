# Clear Host
Clear-Host

# Dot Sourcing
Get-ChildItem -Path (Join-Path -Path "$PSScriptRoot" -ChildPath "..")
| Where-Object Name -Match "Functions"
| Get-ChildItem -Filter "*.ps1"
| ForEach-Object { . $_.FullName }

# Testing Tenants
If (-Not $Tenants) { $Tenants = Get-Tenants }
If (-Not $Tenant) { $Tenant = $Tenants[0] }
If (-Not (Test-TenantConnection $Tenant -Silent)) { Connect-Tenant $Tenant }

# Testing Sites
If (-Not $Sites) { $Sites = Get-Sites -SharePoint -OneDrive -Team -Channel }
If (-Not $Site) { $Site = $Sites[0] }
If (-Not (Test-SiteConnection $Site -Silent)) { Connect-Site $Site }

# Testing SubSites
If (-Not $SubSites) { $SubSites = Get-SubSites $Site }
If (-Not $SubSite) { $SubSite = $SubSites[0] }

# Testing Libraries
If (-Not $Libraries) { $Libraries = Get-Libraries $Site }
If (-Not $Library) { $Library = $Libraries[0] }

# Testing Lists
If (-Not $Lists) { $Lists = Get-Lists $Site }
If (-Not $List) { $List = $Lists[0] }
