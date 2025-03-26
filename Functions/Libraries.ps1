Function Test-Library {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Library,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $Library -Silent:$Silent) -And (Test-Properties $Library Id, Title, DefaultViewUrl -Silent:$Silent) -And ($Library.BaseType -Eq "DocumentLibrary"))) {

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
        $Libraries = Get-PnPList -Connection $Connection | Where-Object { $_.Hidden -Eq $False -And $_.IsCatalog -Eq $False -And $_.BaseType -Eq "DocumentLibrary" }

        Return $Libraries | ForEach-Object {

            Add-Member -InputObject $_ -NotePropertyName "ParentSite" -NotePropertyValue $Site -PassThru

        }

    }

}

Function Get-Library {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Parameter(Mandatory = $True)][String]$Identity
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

    }

    Process {
        
        $Connection = Connect-Site $Site -Return -Silent
        Return Get-PnPList -Identity $Identity -Connection $Connection | Where-Object { $_.Hidden -Eq $False -And $_.IsCatalog -Eq $False -And $_.BaseType -Eq "DocumentLibrary" }

    }

}

Function Set-Library {

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

        Invoke-Operation -Message "Setting parameters to library: $($Library.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
            $Connection = Connect-Site $Library.ParentSite -Return -Silent
            
            If ($Library.RootFolder.ServerRelativeUrl.EndsWith("/Documentos/Atuais")) {
                
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

            } ElseIf ($Library.RootFolder.ServerRelativeUrl.EndsWith("/Registros/Atuais")) {
                
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

            } Else {
                
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

            }
            
            Set-PnPList $Library.Id @LibraryParams -Connection $Connection | Out-Null

        }
        
    }
    
}
