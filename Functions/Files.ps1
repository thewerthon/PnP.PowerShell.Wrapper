# Clear Versions
function Clear-FileVersions {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Library,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }
        
	}

	process {

		$Connection = Connect-Site $Library.ParentSite -Return -Silent
		if ($Library.ParentSite.LockState -eq "ReadOnly") { Start-Sleep -Milliseconds 50; return }
        
		$Items = Get-PnPListItem -List $Library.Title -PageSize 1000 -Fields "FileRef", "FileLeafRef" -Connection $Connection
		if ($Items) { Write-Message "Clearing file versions in library: $($Library.ParentSite.Title) - $($Library.Title)" -Color Cyan -Silent:$Silent }

		foreach ($Item in $Items) {

			if ($Item.FileSystemObjectType -eq 'File') {
                
				Invoke-Operation -Message "> Now processing: $($Item.FieldValues.FileRef)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {

					Remove-PnPFileVersion -Url $Item.FieldValues.FileRef -All -Force -Connection $Connection
                    
				}

			}

		}
        
	}
    
}
