# Clear Host
Clear-Host

# Install Dependencies
#Uninstall-Module PnP.PowerShell -Force
#Install-Module PnP.PowerShell -AllowPrerelease -SkipPublisherCheck -Force
#Update-Module PnP.PowerShell -AllowPrerelease -Force

# Dot Sourcing
Get-ChildItem -Path "$PSScriptRoot" | Where-Object Extension -Like "*.ps1" | Where-Object Name -NotLike "*Main*" | Where-Object Name -NotLike "9*" | ForEach-Object { . $_.FullName }

# Testing
$Tenants = Get-Tenants
$Tenant = $Tenants[0]

$Tenant | Connect-Tenant