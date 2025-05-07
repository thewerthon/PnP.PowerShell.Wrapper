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

            $_
            | Add-Member -NotePropertyName "Type" -NotePropertyValue "Library" -PassThru
            | Add-Member -NotePropertyName "ParentSite" -NotePropertyValue $Site -PassThru

        }

    }

}

Function Get-Library {

    Param(
        [Parameter(Mandatory = $True)][String]$Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site
    )

    Process {
        
        $Library = Get-Libraries $Site | Where-Object { $_.Id -Like $Identity -Or $_.RootFolder.ServerRelativeUrl -Like $Identity -Or $_.Title -Like $Identity }
        If ($Library) { Return $Library[0] }

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

        Invoke-Operation -Message "Setting parameters to library: $($Library.ParentSite.Title) - $($Library.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
            $Connection = Connect-Site $Library.ParentSite -Return -Silent
            If ($Library.ParentSite.LockState -Eq "ReadOnly") { Start-Sleep -Milliseconds 50; Return }

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

            }
            
            If ($Library.RootFolder.ServerRelativeUrl.EndsWith("/Registros/Atuais")) {
                
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
