# Clear Host
Clear-Host

# Dot Sourcing
Get-ChildItem -Path "$PSScriptRoot"
| Where-Object Extension -Like "*.ps1"
| Where-Object Name -NotLike "*Main*"
| Where-Object Name -NotLike "9*"
| ForEach-Object { . $_.FullName }

# Testing
If (-Not (Test-TenantConnection)) {

    $Tenants = Get-Tenants
    $Tenant = $Tenants[0]
    $Tenant | Connect-Tenant

}
