# Clear Host
Clear-Host

# Dot Sourcing
Get-ChildItem -Path (Join-Path -Path "$PSScriptRoot" -ChildPath "..")
| Where-Object Name -Match "Functions"
| Get-ChildItem -Filter "*.ps1"
| ForEach-Object { . $_.FullName }
