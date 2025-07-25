# Install Module
$Env:PNPPOWERSHELL_UPDATECHECK = "Off"
# Install-Module PnP.PowerShell -Scope AllUsers -AllowPrerelease -SkipPublisherCheck -Confirm:$False -Force
# Update-Module PnP.PowerShell -Scope AllUsers -AllowPrerelease -Confirm:$False -Force

# Clear Host
Clear-Host

# Set Location
$Folder = (Get-Item (Join-Path -Path "$PSScriptRoot" -ChildPath ".."))
Set-Location $Folder.FullName

# Dot Sourcing
Get-ChildItem -Path $Folder.FullName
| Where-Object Name -Match "Functions"
| Get-ChildItem -Filter "*.ps1"
| ForEach-Object { . $_.FullName }

# Connect Tenant
while (-not $Global:CurrentTenant) {

	$Tenant = Get-Tenant (Read-Host "Tenant to connect")
	if (-not (Test-TenantConnection $Tenant -Silent)) { Connect-Tenant $Tenant }

}
