Function Get-Root {

    If ($PSScriptRoot) {
        
        Return Join-Path -Path "$PSScriptRoot" -ChildPath ".."
    
    } Else {
        
        Return (Get-Location).Path
    
    }

}

Function Get-Path {

    Param(
        [Parameter(Mandatory = $True)][String]$Path
    )

    Return Join-Path -Path (Get-Root) -ChildPath $Path

}

Function Test-Param {

    Param (
        [Parameter(Mandatory = $True)][String]$Name,
        [Parameter(Mandatory = $True)][Hashtable]$Params,
        [Switch]$Silent
    )

    Try {

        Return $Params.ContainsKey($Name)

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-Object {

    Param(
        [Object]$Object = $Null,
        [Switch]$Silent
    )

    Try {

        Return $Null -Ne $Object

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-NullObject {

    Param(
        [Object]$Object = $Null,
        [Switch]$Silent
    )

    Try {

        Return $Null -Eq $Object

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-SingleObject {

    Param(
        [Object]$Object = $Null,
        [Switch]$Silent
    )

    Try {

        Return $Null -Ne $Object -And $Object.Count -Eq 1

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-SingleOrNullObject {

    Param(
        [Object]$Object = $Null,
        [Switch]$Silent
    )

    Try {

        Return $Null -Eq $Object -Or $Object.Count -Eq 1

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-CollectionObject {

    Param(
        [Object]$Object = $Null,
        [Switch]$Silent
    )

    Try {

        Return $Null -Ne $Object -And $Object.Count -Gt 1

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-CollectionOrNullObject {

    Param(
        [Object]$Object = $Null,
        [Switch]$Silent
    )

    Try {

        Return $Null -Eq $Object -Or $Object.Count -Gt 1

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Test-Properties {

    Param (
        [Parameter(Mandatory = $True)][Object]$Object,
        [Parameter(Mandatory = $True, ValueFromRemainingArguments = $True)][String[]]$Properties,
        [Switch]$AllowNull,
        [Switch]$Silent
    )

    Try {

        ForEach ($Property in $Properties) {

            If (-Not ($Object.PSObject.Properties.Name -Contains $Property)) { Return $False }
            If (-Not $AllowNull -And $Null -Eq $Object.$Property) { Return $False }

        }

        Return $True

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Write-Message {

    Param (
        [String]$Message,
        [String]$Color,
        [Switch]$Silent,
        [Switch]$NoNewLine,
        [Boolean]$Condition = $True
    )

    If (-Not $Silent) {
        
        If ($Condition) {
            
            Write-Host $Message -ForegroundColor $Color -NoNewline:$NoNewLine
        
        }
    
    }

}

Function Invoke-Operation {

    Param(
        [Parameter(Mandatory = $True)][String]$Message,
        [Parameter(Mandatory = $True)][ScriptBlock]$Operation,
        [Switch]$Return,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Try {
        
        Write-Message "$($Message)... " -Color "Cyan" -Silent:$Silent -NoNewline
        
        $Output = & $Operation *>&1

        Write-Message "success!" -Color "Green" -Silent:$Silent

        Write-Message $Output -Color "Gray" -Condition:$DisplayInfos -Silent:$Silent

        If ($Return) { Return $Output }

        $Output

    } Catch {

        Write-Message "failed!" -Color "Magenta" -Silent:$Silent
        
        Write-Message $Output -Color "Gray" -Condition:$DisplayInfos -Silent:$Silent

        Write-Message $_.Exception.Message -Color "Red" -Condition:(!$SuppressErrors) -Silent:$Silent

        If ($Return) { Return $Null }

        $Output

    }

}

Function Invoke-UpdateModule {

    Param(
        [String]$ModuleName = "PnP.PowerShell",
        [Switch]$AllowPrerelease,
        [Switch]$Reinstall
    )
    
    If ($Reinstall) { Uninstall-Module $ModuleName -Force -ErrorAction Ignore }
    If (-Not (Get-InstalledModule $ModuleName -ErrorAction Ignore)) { If ($AllowPrerelease) { Install-Module $ModuleName -AllowPrerelease -SkipPublisherCheck -Force } Else { Install-Module $ModuleName -Force } }
    If ($AllowPrerelease) { Update-Module $ModuleName -AllowPrerelease -Force } Else { Update-Module $ModuleName -Force }

}
