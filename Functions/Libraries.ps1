Function Test-Library {

    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$Library,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $Library -Silent:$Silent) -And (Test-Properties $Library Title, DefaultViewUrl -Silent:$Silent) -And ($Library.BaseType -Eq "DocumentLibrary"))) {

            Write-Message "Invalid library." -Color "Red" -Silent:$Silent
            Return $False

        } Else {

            Return $True

        }

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Get-Libraries {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        $Connection = Connect-Site $Site -Return -Silent
        Return Get-PnPList -Connection $Connection | Where-Object { $_.Hidden -Eq $False -And $_.IsCatalog -Eq $False -And $_.BaseType -Eq "DocumentLibrary" }

    }

}

Function Set-Library {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Library
    )

    Process {

        Get-PnPField -List $List.Id | Where-Object { $_.InternalName -In $ColumnsMapping.Keys } | ForEach-Object {

            If ($ColumnsMapping.ContainsKey($_.InternalName)) {

                $_.Title = $ColumnsMapping[$_.InternalName].Title
                $_.CustomFormatter = $ColumnsMapping[$_.InternalName].CustomFormatter

            }

        }

    }
    
}
