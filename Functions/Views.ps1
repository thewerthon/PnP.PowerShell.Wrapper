function Test-View {

	param(
		[Parameter(ValueFromPipeline = $True)][Object]$View,
		[Switch]$Silent
	)

	try {

		if (-not ((Test-SingleObject $View -Silent:$Silent) -and (Test-Properties $View Id, Title -Silent:$Silent))) {

			Write-Message "Invalid view." -Color "Red" -Silent:$Silent
			return $False

		} else {

			return $True

		}

	} catch {

		Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
		return $False

	}

}

function Get-Views {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$List
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }
        
	}

	process {

		$Connection = Connect-Site $List.ParentSite -Return -Silent
		$Views = Get-PnPView -List $List.Id -Connection $Connection | Where-Object { $_.Hidden -eq $False }

		return $Views | ForEach-Object {

			$_
			| Add-Member -NotePropertyName "ParentList" -NotePropertyValue $List -PassThru

		}

	}

}

function Get-View {

	param(
		[Parameter(Mandatory = $True)][String]$Identity,
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$List
	)

	process {
        
		$View = Get-Views $List | Where-Object { $_.Id -like $Identity -or $_.ServerRelativeUrl -like $Identity -or $_.Title -like $Identity }
		if ($View) { return $View[0] }

	}

}

function Set-View {

	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$View,
		[Switch]$DisplayInfos,
		[Switch]$SuppressErrors,
		[Switch]$Silent
	)

	begin {

		if (-not (Test-TenantConnection -Silent:$Silent)) { return }
        
	}

	process {

		Invoke-Operation -Message "Setting parameters to view: $($View.ParentList.ParentSite.Title) - $($View.ParentList.Title) - $($View.Title)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
			$Connection = Connect-Site $View.ParentList.ParentSite -Return -Silent
            
			if ($View.ParentList.Type -eq "Library" -and $View.ServerRelativeUrl -match "/personal/") {

				if ($View.ServerRelativeUrl.EndsWith("All.aspx")) {

					$ViewFields = @('DocIcon', 'LinkFilename', 'Editor', 'Modified', 'SharedWith')
					$ViewWidths = '<FieldRef Name="Nome" width="350" /><FieldRef Name="Modificado Por" width="180" /><FieldRef Name="Modificado Em" width="180" /><FieldRef Name="Compartilhamento" width="120" /><FieldRef Name="Tamanho do arquivo" width="100" /><FieldRef Name="Atividade" width="200" />'
					Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null

				}
                
			}

			if ($View.ParentList.Type -eq "Library" -and $View.ViewType2 -notin ('TILES', 'CALENDAR', 'MODERNCALENDAR', 'KANBAN')) {

				if ($View.ServerRelativeUrl.EndsWith("AllItems.aspx")) {

					$ViewFields = @('DocIcon', 'LinkFilename', 'Author', 'Created', 'Editor', 'Modified', 'FileSizeDisplay')
					$ViewWidths = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Criado Por" width="200" /><FieldRef Name="Criado Em" width="200" /><FieldRef Name="Modificado Por" width="200" /><FieldRef Name="Modificado Em" width="200" /><FieldRef Name="Tamanho do Arquivo" width="100" />'
					Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null

				}

				if ($View.ServerRelativeUrl.EndsWith("/Documentos/Atuais/Forms/Pastas.aspx")) {
                    
					$ViewFields = @('DocIcon', 'LinkFilename', 'ElaboradoPor', 'ElaboradoEm', 'VerificadoPor', 'VerificadoEm', 'AprovadoPor', 'AprovadoEm', '_ModerationStatus', 'Validade', '_DisplayName', '_ComplianceTag', 'FileSizeDisplay')
					$ViewWidths = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Área" width="250" /><FieldRef Name="Categoria" width="250" /><FieldRef Name="Nível" width="120" /><FieldRef Name="Origem" width="120" /><FieldRef Name="Elaborado Por" width="180" /><FieldRef Name="Elaborado Em" width="130" /><FieldRef Name="Verificado Por" width="180" /><FieldRef Name="Verificado Em" width="130" /><FieldRef Name="Aprovado Por" width="180" /><FieldRef Name="Aprovado Em" width="130" /><FieldRef Name="Estado" width="120" /><FieldRef Name="Válido Até" width="120" /><FieldRef Name="Retenção" width="160" /><FieldRef Name="Confidencialidade" width="160" /><FieldRef Name="Tamanho do Arquivo" width="100" />'
					Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null

				}

				if ($View.ServerRelativeUrl.EndsWith("/Documentos/Atuais/Forms/Lista.aspx")) {
                    
					$ViewFields = @('DocIcon', 'LinkFilename', 'AreaDocumento', 'CategoriaDocumento', 'Categoria_x003a_N_x00ed_vel', 'Origem', 'ElaboradoPor', 'ElaboradoEm', 'VerificadoPor', 'VerificadoEm', 'AprovadoPor', 'AprovadoEm', '_ModerationStatus', 'Validade', '_DisplayName', '_ComplianceTag', 'FileSizeDisplay')
					$ViewWidths = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Área" width="250" /><FieldRef Name="Categoria" width="250" /><FieldRef Name="Nível" width="120" /><FieldRef Name="Origem" width="120" /><FieldRef Name="Elaborado Por" width="180" /><FieldRef Name="Elaborado Em" width="130" /><FieldRef Name="Verificado Por" width="180" /><FieldRef Name="Verificado Em" width="130" /><FieldRef Name="Aprovado Por" width="180" /><FieldRef Name="Aprovado Em" width="130" /><FieldRef Name="Estado" width="120" /><FieldRef Name="Válido Até" width="120" /><FieldRef Name="Retenção" width="160" /><FieldRef Name="Confidencialidade" width="160" /><FieldRef Name="Tamanho do Arquivo" width="100" />'
					Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null

				}

				if ($View.ServerRelativeUrl.EndsWith("/Documentos/Obsoletos/Forms/Pastas.aspx")) {

					$ViewFields = @('DocIcon', 'LinkFilename', 'ElaboradoPor', 'ElaboradoEm', 'VerificadoPor', 'VerificadoEm', 'AprovadoPor', 'AprovadoEm', '_DisplayName', '_ComplianceTag', 'FileSizeDisplay')
					$ViewWidths = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Área" width="250" /><FieldRef Name="Categoria" width="250" /><FieldRef Name="Nível" width="120" /><FieldRef Name="Origem" width="120" /><FieldRef Name="Elaborado Por" width="180" /><FieldRef Name="Elaborado Em" width="130" /><FieldRef Name="Verificado Por" width="180" /><FieldRef Name="Verificado Em" width="130" /><FieldRef Name="Aprovado Por" width="180" /><FieldRef Name="Aprovado Em" width="130" /><FieldRef Name="Retenção" width="160" /><FieldRef Name="Confidencialidade" width="160" /><FieldRef Name="Tamanho do Arquivo" width="100" />'
					Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null
                    
				}

				if ($View.ServerRelativeUrl.EndsWith("/Documentos/Obsoletos/Forms/Lista.aspx")) {
                    
					$ViewFields = @('DocIcon', 'LinkFilename', 'AreaDocumento', 'CategoriaDocumento', 'Categoria_x003a_N_x00ed_vel', 'Origem', 'ElaboradoPor', 'ElaboradoEm', 'VerificadoPor', 'VerificadoEm', 'AprovadoPor', 'AprovadoEm', '_DisplayName', '_ComplianceTag', 'FileSizeDisplay')
					$ViewWidths = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Área" width="250" /><FieldRef Name="Categoria" width="250" /><FieldRef Name="Nível" width="120" /><FieldRef Name="Origem" width="120" /><FieldRef Name="Elaborado Por" width="180" /><FieldRef Name="Elaborado Em" width="130" /><FieldRef Name="Verificado Por" width="180" /><FieldRef Name="Verificado Em" width="130" /><FieldRef Name="Aprovado Por" width="180" /><FieldRef Name="Aprovado Em" width="130" /><FieldRef Name="Retenção" width="160" /><FieldRef Name="Confidencialidade" width="160" /><FieldRef Name="Tamanho do Arquivo" width="100" />'
					Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null

				}

				if ($View.ServerRelativeUrl.EndsWith("/Registros/Atuais/Forms/AllItems.aspx")) {

					$ViewFields = @('DocIcon', 'LinkFilename', 'Author', 'Created', 'Editor', 'Modified', '_DisplayName', '_ComplianceTag', 'FileSizeDisplay')
					$ViewWidths = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Criado Por" width="200" /><FieldRef Name="Criado Em" width="200" /><FieldRef Name="Modificado Por" width="200" /><FieldRef Name="Modificado Em" width="200" /><FieldRef Name="Retenção" width="160" /><FieldRef Name="Confidencialidade" width="160" /><FieldRef Name="Tamanho do Arquivo" width="100" />'
					Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null

				}

				if ($View.ServerRelativeUrl.EndsWith("/Registros/Obsoletos/Forms/AllItems.aspx")) {

					$ViewFields = @('DocIcon', 'LinkFilename', 'Author', 'Created', 'Editor', 'Modified', '_DisplayName', '_ComplianceTag', 'FileSizeDisplay')
					$ViewWidths = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Criado Por" width="200" /><FieldRef Name="Criado Em" width="200" /><FieldRef Name="Modificado Por" width="200" /><FieldRef Name="Modificado Em" width="200" /><FieldRef Name="Retenção" width="160" /><FieldRef Name="Confidencialidade" width="160" /><FieldRef Name="Tamanho do Arquivo" width="100" />'
					Set-PnPView -Identity $View.Id -List $View.ParentList.Id -Values @{ ColumnWidth = $ViewWidths } -Fields $ViewFields -Connection $Connection | Out-Null

				}

			}

			if ($View.ParentList.Type -eq "List" -and $View.ViewType2 -notin ('TILES', 'CALENDAR', 'MODERNCALENDAR', 'KANBAN')) {

				if ($View.ServerRelativeUrl.EndsWith("AllItems.aspx")) { }

			}
            
		}
        
	}
    
}
