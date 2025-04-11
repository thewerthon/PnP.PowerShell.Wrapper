Function Test-List {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$List,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $List -Silent:$Silent) -And (Test-Properties $List Id, Title, DefaultViewUrl -Silent:$Silent) -And ($List.BaseType -Eq "GenericList"))) {

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
        $Lists = Get-PnPList -Connection $Connection | Where-Object { $_.Hidden -Eq $False -And $_.IsCatalog -Eq $False -And $_.BaseType -Eq "GenericList" }

        Return $Lists | ForEach-Object {

            $_
            | Add-Member -NotePropertyName "Type" -NotePropertyValue "List" -PassThru
            | Add-Member -NotePropertyName "ParentSite" -NotePropertyValue $Site -PassThru

        }

    }

}

Function Get-List {

    Param(
        [Parameter(Mandatory = $True)][String]$Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Process {
        
        $List = Get-Lists $Site | Where-Object { $_.Id -Like $Identity -Or $_.RootFolder.ServerRelativeUrl -Like $Identity -Or $_.Title -Like $Identity }
        If ($List) { Return $List[0] }

    }

}

Function Set-List {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$List,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        Invoke-Operation -Message "Setting parameters to list: $($List.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
            $Connection = Connect-Site $List.ParentSite -Return -Silent
            
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
