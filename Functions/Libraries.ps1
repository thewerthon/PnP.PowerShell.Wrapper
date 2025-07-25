function Test-Library {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$Library,
		[Switch]$Silent
	)

	try {

		if (-not ((Test-SingleObject $Library -Silent:$Silent) -and (Test-Properties $Library Id, Title, DefaultViewUrl -Silent:$Silent) -and ($Library.BaseType -eq "DocumentLibrary"))) {

			Write-Message "Invalid library." -Color "Red" -Silent:$Silent
			return $False

		} else {

			return $True

		}

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Get-Libraries {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }
        
	}

	process {

		$Connection = Connect-Site $Site -Return -Silent
		$Libraries = Get-PnPList -Connection $Connection | Where-Object { $_.Hidden -eq $False -and $_.IsCatalog -eq $False -and $_.BaseType -eq "DocumentLibrary" }

		return $Libraries | ForEach-Object {

			$_
			| Add-Member -NotePropertyName "Type" -NotePropertyValue "Library" -PassThru
			| Add-Member -NotePropertyName "ParentSite" -NotePropertyValue $Site -PassThru

		}

	}

}

function Get-Library {

	param(
		[Parameter(Mandatory = $True)][String]$Identity,
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
	)

	process {
        
		$Library = Get-Libraries $Site | Where-Object { $_.Id -like $Identity -or $_.RootFolder.ServerRelativeUrl -like $Identity -or $_.Title -like $Identity }
		if ($Library) { return $Library[0] }

	}

}

function Set-Library {

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

		Invoke-Operation -Message "Setting parameters to library: $($Library.ParentSite.Title) - $($Library.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
			$Connection = Connect-Site $Library.ParentSite -Return -Silent
			if ($Library.ParentSite.LockState -eq "ReadOnly") { Start-Sleep -Milliseconds 50; return }

			$LibraryParams = @{
				DraftVersionVisibility          = "Reader"
				EnableAutoExpirationVersionTrim = $True
				EnableMinorVersions             = $False
				EnableModeration                = $False
				EnableVersioning                = $True
				ForceCheckout                   = $False
				ListExperience                  = "Auto"
				OpenDocumentsMode               = "ClientApplication"
			}

			if ($Library.RootFolder.ServerRelativeUrl.EndsWith("/Documentos/Atuais")) {
                
				$LibraryParams = @{
					DraftVersionVisibility          = "Author"
					EnableAutoExpirationVersionTrim = $True
					EnableMinorVersions             = $True
					EnableModeration                = $True
					EnableVersioning                = $True
					ForceCheckout                   = $True
					ListExperience                  = "Auto"
					OpenDocumentsMode               = "ClientApplication"
				}

			}
            
			if ($Library.RootFolder.ServerRelativeUrl.EndsWith("/Registros/Atuais")) {
                
				$LibraryParams = @{
					DraftVersionVisibility          = "Author"
					EnableAutoExpirationVersionTrim = $True
					EnableMinorVersions             = $False
					EnableModeration                = $False
					EnableVersioning                = $True
					ForceCheckout                   = $False
					ListExperience                  = "Auto"
					OpenDocumentsMode               = "ClientApplication"
				}

			}

			Set-PnPList -Identity $Library.Id @LibraryParams -Connection $Connection | Out-Null

		}
        
	}
    
}
