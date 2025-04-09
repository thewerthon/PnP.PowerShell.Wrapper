Function Test-SubSite {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$SubSite,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $SubSite -Silent:$Silent) -And (Test-Properties $SubSite Url, Title -Silent:$Silent))) {

            Write-Message "Invalid subsite." -Color "Red" -Silent:$Silent
            Return $False

        } Else {

            Return $True

        }

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
        [Parameter(Mandatory = $True)][String]$Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Site,
        [Switch]$Recurse
    )

    Process {

        $SubSite = Get-SubSites $Site -Recurse:$Recurse | Where-Object { $_.Id -Eq $Identity -Or $_.Url -Eq $Identity -Or $_.Title -Eq $Identity }
        If ($SubSite) { Return $SubSite[0] }

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
        [Switch]$Silent
    )

    Process {

        Set-SiteNavigation $SubSite -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent
        
    }

}
