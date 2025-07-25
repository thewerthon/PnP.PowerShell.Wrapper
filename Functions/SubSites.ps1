function Test-SubSite {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$SubSite,
		[Switch]$Silent
	)

	try {

		if (-not ((Test-SingleObject $SubSite -Silent:$Silent) -and (Test-Properties $SubSite Url, Title -Silent:$Silent))) {

			Write-Message "Invalid subsite." -Color "Red" -Silent:$Silent
			return $False

		} else {

			return $True

		}

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Get-SubSites {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Recurse
	)

	process {

		$Connection = Connect-Site $Site -Return -Silent
		$SubSites = Get-PnPSubWeb -Connection $Connection -Recurse:$Recurse

		return $SubSites | ForEach-Object {

			$_
			| Add-Member -NotePropertyName "Type" -NotePropertyValue "SharePoint" -PassThru
			| Add-Member -NotePropertyName "ParentSite" -NotePropertyValue $Site -PassThru
                
		}

	}

}

function Get-SubSite {

	param(
		[Parameter(Mandatory = $True)][String]$Identity,
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
		[Switch]$Recurse
	)

	process {

		$SubSite = Get-SubSites $Site -Recurse:$Recurse | Where-Object { $_.Id -like $Identity -or $_.Url -like $Identity -or $_.Title -like $Identity }
		if ($SubSite) { return $SubSite[0] }

	}

}

function Set-SubSite {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$SubSite,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	process {

		Set-Site $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent

	}

}

function Set-SubSiteAppearance {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$SubSite,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	process {

		Set-SiteAppearance $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent

	}

}

function Set-SubSiteHomePage {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$SubSite,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	process {

		Set-SiteHomePage $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent
        
	}

}

function Set-SubSiteNavigation {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$SubSite,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	process {

		Set-SiteNavigation $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent
        
	}

}
