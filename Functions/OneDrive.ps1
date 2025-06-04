Function Get-OneDriveConfig {

    If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }

    $OneDriveConfig = @()
    $TeamSites = Get-Sites -Teams

    ForEach ($TeamSite In $TeamSites) {

        $Connection = Connect-Site $TeamSite -Return -Silent

        $OneDriveConfig += [Ordered]@{
            Name      = $TeamSite.Title
            Icon      = "C:\Startup\OneDrive\$($CurrentTenant.Name)\Icons\Default.ico"
            SiteId    = (Get-PnPSite -Includes Id -Connection $Connection).Id
            WebId     = (Get-PnPWeb -Includes Id -Connection $Connection).Id
            WebUrl    = $TeamSite.Url
            ListId    = (Get-PnPList -Identity "Documentos" -Connection $Connection).Id
            GroupId   = $TeamSite.RelatedGroupId
            WebTitle  = $CurrentTenant.Name
            ListTitle = $TeamSite.Title
        }

    }

    Return $OneDriveConfig | ConvertTo-Json

}
