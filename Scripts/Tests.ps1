# Clear Host
Clear-Host

# Dot Sourcing
Get-ChildItem -Path (Join-Path -Path "$PSScriptRoot" -ChildPath "..")
| Where-Object Name -Match "Functions"
| Get-ChildItem -Filter "*.ps1"
| ForEach-Object { . $_.FullName }

# Testing
If (-Not (Test-TenantConnection -Silent)) {

    $Tenants = Get-Tenants
    $Tenant = $Tenants[0]
    $Tenant | Connect-Tenant

}
