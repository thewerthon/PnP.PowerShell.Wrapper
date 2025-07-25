function Get-GroupsMembers {

	param(
		[string]$ExportTo
	)

	if (-not (Test-TenantConnection -Silent:$Silent)) { return }

	$ExportList = @()

	$Sites = Get-Sites -Groups
	$Groups = Get-PnPMicrosoft365Group

	foreach ($Group in $Groups) {

		try {
			
			$Site = $Sites | Where-Object { $_.GroupId -eq $Group.Id }
			if ($Site) { $Connection = Connect-Site $Site[0] -Return }
			
			$Owners = Get-PnPMicrosoft365GroupOwner -Identity $Group.Id
			$Members = Get-PnPMicrosoft365GroupMember -Identity $Group.Id
			$Visitors = Get-PnPGroupMember -Identity (Get-PnPGroup -Connection $Connection | Where-Object { $_.Title -like "*Visit*" }).Title -Connection $Connection
			
			foreach ($Owner in $Owners) {
				
				$ExportList += [PSCustomObject]@{
					Id    = $Group.Id
					Group = $Group.DisplayName
					Name  = $Owner.DisplayName
					Email = $Owner.UserPrincipalName
					Type  = "Owner"
				}

			}

			foreach ($Member in $Members) {
				
				$Exists = $ExportList | Where-Object { $_.Id -eq $Group.Id -and $_.Email -eq $Member.UserPrincipalName }

				if (-not $Exists) {
					$ExportList += [PSCustomObject]@{
						Id    = $Group.Id
						Group = $Group.DisplayName
						Name  = $Member.DisplayName
						Email = $Member.UserPrincipalName
						Type  = "Member"
					}
				}
				
			}

			foreach ($Visitor in $Visitors) {
				
				$Exists = $ExportList | Where-Object { $_.Id -eq $Group.Id -and $_.Email -eq $Visitor.Email }

				if (-not $Exists) {
					$ExportList += [PSCustomObject]@{
						Id    = $Group.Id
						Group = $Group.DisplayName
						Name  = $Visitor.Title
						Email = $Visitor.Email
						Type  = "Visitor"
					}
				}
				
			}

			if ($Owners.Count -eq 0 -and $Members.Count -eq 0) {
				$ExportList += [PSCustomObject]@{
					Id    = $Group.Id
					Group = $Group.DisplayName
					Name  = ""
					Email = ""
					Type  = ""
				}
			}

		} catch {

			Write-Host "Error while accessing group: $($Group.DisplayName)" -ForegroundColor Red

		}

	}

	if ($ExportTo) {

		try {

			$ExportList | Export-Csv -Path $ExportTo -NoTypeInformation -Encoding UTF8
			Write-Host "Exported to $ExportTo" -ForegroundColor Green

		} catch {

			Write-Host "Error while exporting to ${$ExportTo}: $_" -ForegroundColor Red

		}

	} else {

		return $ExportList

	}

}
