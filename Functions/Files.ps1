# Clear Versions
Function Clear-FileVersions {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Library,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        $Connection = Connect-Site $Library.ParentSite -Return -Silent
        If ($Library.ParentSite.LockState -Eq "ReadOnly") { Start-Sleep -Milliseconds 50; Return }
        
        $Items = Get-PnPListItem -List $Library.Title -PageSize 1000 -Fields "FileRef", "FileLeafRef" -Connection $Connection
        If ($Items) { Write-Message "Clearing file versions in library: $($Library.ParentSite.Title) - $($Library.Title)" -Color Cyan -Silent:$Silent }

        ForEach ($Item In $Items) {

            If ($Item.FileSystemObjectType -Eq 'File') {
                
                Invoke-Operation -Message "> Now processing: $($Item.FieldValues.FileRef)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

                    Remove-PnPFileVersion -Url $Item.FieldValues.FileRef -All -Force -Connection $Connection
                    
                }

            }

        }
        
    }
    
}
