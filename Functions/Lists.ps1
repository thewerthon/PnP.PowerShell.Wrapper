function Test-List {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$List,
		[Switch]$Silent
	)

	try {

		if (-not ((Test-SingleObject $List -Silent:$Silent) -and (Test-Properties $List Id, Title, DefaultViewUrl -Silent:$Silent) -and ($List.BaseType -eq "GenericList"))) {

			Write-Message "Invalid list." -Color "Red" -Silent:$Silent
			return $False

		} else {

			return $True

		}

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Get-Lists {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }
        
	}

	process {

		$Connection = Connect-Site $Site -Return -Silent
		$Lists = Get-PnPList -Connection $Connection | Where-Object { $_.Hidden -eq $False -and $_.IsCatalog -eq $False -and $_.BaseType -eq "GenericList" }

		return $Lists | ForEach-Object {

			$_
			| Add-Member -NotePropertyName "Type" -NotePropertyValue "List" -PassThru
			| Add-Member -NotePropertyName "ParentSite" -NotePropertyValue $Site -PassThru

		}

	}

}

function Get-List {

	param(
		[Parameter(Mandatory = $True)][String]$Identity,
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
	)

	process {
        
		$List = Get-Lists $Site | Where-Object { $_.Id -like $Identity -or $_.RootFolder.ServerRelativeUrl -like $Identity -or $_.Title -like $Identity }
		if ($List) { return $List[0] }

	}

}

function Set-List {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$List,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }
        
	}

	process {

		Invoke-Operation -Message "Setting parameters to list: $($List.ParentSite.Title) - $($List.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
			$Connection = Connect-Site $List.ParentSite -Return -Silent
			if ($List.ParentSite.LockState -eq "ReadOnly") { Start-Sleep -Milliseconds 50; return }
            
			$ListParams = @{
				EnableAutoExpirationVersionTrim = $True
				EnableMinorVersions             = $False
				EnableModeration                = $False
				EnableVersioning                = $True
				ListExperience                  = "Auto"
			}

			Set-PnPList -Identity $List.Id @ListParams -Connection $Connection | Out-Null

		}
        
	}
    
}
