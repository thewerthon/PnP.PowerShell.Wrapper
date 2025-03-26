Function Test-List {

    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)][Object]$List,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $List -Silent:$Silent) -And (Test-Properties $List Title, DefaultViewUrl -Silent:$Silent) -And ($List.BaseType -Eq "GenericList"))) {

            Write-Message "Invalid list." -Color "Red" -Silent:$Silent
            Return $False

        } Else {

            Return $True

        }

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Get-Lists {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        $Connection = Connect-Site $Site -Return -Silent
        Return Get-PnPList -Connection $Connection | Where-Object { $_.Hidden -Eq $False -And $_.IsCatalog -Eq $False -And $_.BaseType -Eq "GenericList" }

    }

}
