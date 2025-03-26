Function Test-SubSite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Silent
    )

    Try {

        Return $Null -Ne $Site.ServerRelativeUrl

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Get-SubSites {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Recurse
    )

    Process {

        $Connection = Connect-Site $Site -Return -Silent
        $SubSites = Get-PnPSubWeb -Connection $Connection -Recurse:$Recurse

        Return $SubSites | ForEach-Object {

            $_
            | Add-Member -NotePropertyName "Type" -NotePropertyValue "SharePoint" -PassThru
            | Add-Member -NotePropertyName "ParentSite" -NotePropertyValue $Site -PassThru
                
        }

    }

}

Function Get-SubSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Parameter(Mandatory = $True)][String]$Identity,
        [Switch]$Recurse
    )

    Process {

        $SubSite = (Get-SubSites $Site -Recurse:$Recurse | Where-Object { ($_.Title -Eq $Identity) -Or ($_.Url -Eq $Identity) })[0]
        Return $SubSite

    }

}

Function Set-SubSite {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$SubSite,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Process {

        Set-Site $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -SubSites

    }

}

Function Set-SubSiteAppearance {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$SubSite,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Process {

        Set-SiteAppearance $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent

    }

}

Function Set-SubSiteHomePage {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$SubSite,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Process {

        Set-SiteHomePage $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent
        
    }

}

Function Set-SubSiteNavigation {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$SubSite,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent,
        [Switch]$Reset,
        [Switch]$Force
    )

    Process {

        Set-SiteNavigation $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Reset:$Reset -Force:$Force
        
    }

}
