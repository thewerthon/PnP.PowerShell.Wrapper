function Get-Root {

	if ($PSScriptRoot) {
        
		return Join-Path -Path "$PSScriptRoot" -ChildPath ".."
    
	} else {
        
		return (Get-Location).Path
    
	}

}

function Get-Path {

	param(
		[Parameter(Mandatory = $True)][String]$Path
	)

	return Join-Path -Path (Get-Root) -ChildPath $Path

}

function Test-Param {

	param (
		[Parameter(Mandatory = $True)][String]$Name,
		[Parameter(Mandatory = $True)][Hashtable]$Params,
		[Switch]$Silent
	)

	try {

		return $Params.ContainsKey($Name)

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-Object {

	param(
		[Object]$Object = $Null,
		[Switch]$Silent
	)

	try {

		return $Null -ne $Object

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-NullObject {

	param(
		[Object]$Object = $Null,
		[Switch]$Silent
	)

	try {

		return $Null -eq $Object

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-SingleObject {

	param(
		[Object]$Object = $Null,
		[Switch]$Silent
	)

	try {

		return $Null -ne $Object -and $Object.Count -eq 1

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-SingleOrNullObject {

	param(
		[Object]$Object = $Null,
		[Switch]$Silent
	)

	try {

		return $Null -eq $Object -or $Object.Count -eq 1

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-CollectionObject {

	param(
		[Object]$Object = $Null,
		[Switch]$Silent
	)

	try {

		return $Null -ne $Object -and $Object.Count -gt 1

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-CollectionOrNullObject {

	param(
		[Object]$Object = $Null,
		[Switch]$Silent
	)

	try {

		return $Null -eq $Object -or $Object.Count -gt 1

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Test-Properties {

	param (
		[Parameter(Mandatory = $True)][Object]$Object,
		[Parameter(Mandatory = $True, ValueFromRemainingArguments = $True)][String[]]$Properties,
		[Switch]$AllowNull,
		[Switch]$Silent
	)

	try {

		foreach ($Property in $Properties) {

			if (-not ($Object.PSObject.Properties.Name -contains $Property)) { return $False }
			if (-not $AllowNull -and $Null -eq $Object.$Property) { return $False }

		}

		return $True

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Write-Message {

	param (
		[String]$Message,
		[String]$Color,
		[Switch]$Silent,
		[Switch]$NoNewLine,
		[Boolean]$Condition = $True
	)

	if (-not $Silent) {
        
		if ($Condition) {
            
			Write-Host $Message -ForegroundColor $Color -NoNewline:$NoNewLine
        
		}
    
	}

}

function Invoke-Operation {

	param(
		[Parameter(Mandatory = $True)][String]$Message,
		[Parameter(Mandatory = $True)][ScriptBlock]$Operation,
		[Switch]$Return,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	try {
        
		Write-Message "$($Message)... " -Color "Cyan" -Silent:$Silent -NoNewline
        
		$Output = & $Operation *>&1

		Write-Message "success!" -Color "Green" -Silent:$Silent

		Write-Message $Output -Color "Gray" -Condition:$DisplayInfos -Silent:$Silent

		if ($Return) { return $Output }

		$Output

	} catch {

		Write-Message "failed!" -Color "Magenta" -Silent:$Silent
        
		Write-Message $Output -Color "Gray" -Condition:$DisplayInfos -Silent:$Silent

		Write-Message $_.Exception.Message -Color "Red" -Condition:(!$SuppressErrors) -Silent:$Silent

		if ($Return) { return $Null }

		$Output

	}

}
