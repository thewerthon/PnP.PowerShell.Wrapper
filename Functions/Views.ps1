Function Test-View {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$View,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $View -Silent:$Silent) -And (Test-Properties $View Id, Title -Silent:$Silent))) {

            Write-Message "Invalid view." -Color "Red" -Silent:$Silent
            Return $False

        } Else {

            Return $True

        }

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Get-Views {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$List
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        $Connection = Connect-Site $List.ParentSite -Return -Silent
        $Views = Get-PnPView -List $List.Id -Connection $Connection | Where-Object { $_.Hidden -Eq $False }

        Return $Views | ForEach-Object {

            $_
            | Add-Member -NotePropertyName "ParentList" -NotePropertyValue $List -PassThru

        }

    }

}

Function Get-View {

    Param(
        [Parameter(Mandatory = $True)][String]$Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$List
    )

    Process {
        
        $View = Get-Views $List | Where-Object { $_.Id -Eq $Identity -Or $_.ServerRelativeUrl -Eq $Identity -Or $_.Title -Eq $Identity }
        If ($View) { Return $View[0] }

    }

}

Function Set-View {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$View,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        Invoke-Operation -Message "Setting parameters to view: $($View.ParentList.ParentSite.Title) - $($View.ParentList.Title) - $($View.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
            $Connection = Connect-Site $View.ParentList.ParentSite -Return -Silent
            
            If ($View.ParentList.Type -Eq "Library" -And $View.ViewType2 -NotIn ('TILES', 'CALENDAR', 'MODERNCALENDAR', 'KANBAN')) {

                If ($View.ServerRelativeUrl.EndsWith("AllItems.aspx")) {

                    $ViewFields = @('DocIcon', 'LinkFilename', 'Author', 'Created', 'Editor', 'Modified', 'FileSizeDisplay')
                    $ViewWidths = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Criado Por" width="200" /><FieldRef Name="Criado Em" width="200" /><FieldRef Name="Modificado Por" width="200" /><FieldRef Name="Modificado Em" width="200" /><FieldRef Name="Tamanho do Arquivo" width="100" />'
                    Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null

                }

                If ($View.ParentList.ParentSite.Url.EndsWith("/Documentos") -And $View.ServerRelativeUrl.EndsWith("Recentes.aspx")) { }
                If ($View.ParentList.ParentSite.Url.EndsWith("/Documentos") -And $View.ServerRelativeUrl.EndsWith("Pastas.aspx")) { }
                If ($View.ParentList.ParentSite.Url.EndsWith("/Documentos") -And $View.ServerRelativeUrl.EndsWith("Lista.aspx")) { }
                If ($View.ParentList.ParentSite.Url.EndsWith("/Documentos") -And $View.ServerRelativeUrl.EndsWith("my-sub.aspx")) { }
                If ($View.ParentList.ParentSite.Url.EndsWith("/Documentos") -And $View.ServerRelativeUrl.EndsWith("mod-view.aspx")) { }

                If ($View.ParentList.ParentSite.Url.EndsWith("/Registros") -And $View.ServerRelativeUrl.EndsWith("Recentes.aspx")) { }
                If ($View.ParentList.ParentSite.Url.EndsWith("/Registros") -And $View.ServerRelativeUrl.EndsWith("Pastas.aspx")) { }
                If ($View.ParentList.ParentSite.Url.EndsWith("/Registros") -And $View.ServerRelativeUrl.EndsWith("Lista.aspx")) { }

            }

            If ($View.ParentList.Type -Eq "List" -And $View.ViewType2 -NotIn ('TILES', 'CALENDAR', 'MODERNCALENDAR', 'KANBAN')) {

                If ($View.ServerRelativeUrl.EndsWith("AllItems.aspx")) { }

            }
            
        }
        
    }
    
}
