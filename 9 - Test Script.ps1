# Get-PnPWeb => Site Configs
# Get-PnPSubWeb => Subsite Configs
# Get-PnPTenantCdnEnabled -CdnType Public
# Get-PnPNavigationNode

# Get-PnPPage
# Get-PnPPageComponent
# Get-PnPFeature
# Get-PnPGroup
# Get-PnPGroupMember
# Get-PnPGroupPermissions
# Get-PnPSiteGroup
# Get-PnPFileSharingLink
# Get-PnPFolderSharingLink
# Get-PnPSearchConfiguration
# Get-PnPSearchSettings
# Configure Personal Sites

# Invoke Testing
Function Invoke-Testing {

    # Connect Tenant
    $Tenants = Get-Tenants
    $Tenant = $Tenants[0]
    $Tenant | Connect-Tenant

    # Connect Site
    $Sites = Get-Sites -SharePoint
    $Sites | Set-Site -All

}

# Function to Get Fields
Function Get-Fields {

    Param(
        [Parameter(Mandatory = $True)]
        [Object]$List
    )

    $Fields = Get-PnPField -List $List.Id
    Return $Fields

}

# Function to Get Views
Function Get-Views {

    Param(
        [Parameter(Mandatory = $True)]
        [Object]$List
    )

    $Views = Get-PnPView -List $List.Id | Where-Object { $_.Hidden -Eq $False }
    Return $Views

}

# Function to Get Lists
Function Get-Lists {

    $Lists = Get-PnPList | Where-Object { $_.Hidden -Eq $False -And $_.IsCatalog -Eq $False -And $_.BaseType -In ('DocumentLibrary', 'GenericList') }
    Return $Lists

}

# Function to Set Field
Function Set-Field {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Object]$Field
    )

    Process {
        
        # Fields Formats
        $DateFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/App/v2/column-formatting.schema.json","elmType":"div","children":[{"elmType":"Appan","style":{"padding-right":"10px","padding-bottom":"2px","font-size":"16px"},"attributes":{"iconName":"Calendar"}},{"elmType":"Appan","txtContent":"@currentField.diApplayValue","style":{"padding-bottom":"4px"}}]}'
        $PersonFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/App/v2/column-formatting.schema.json","elmType":"div","style":{"diApplay":"flex","flex-wrap":"wrap","overflow":"hidden"},"children":[{"elmType":"div","forEach":"person in @currentField","defaultHoverField":"[$person]","attributes":{"class":"ms-bgColor-neutralLighter ms-fontColor-neutralSecondary"},"style":{"diApplay":"flex","overflow":"hidden","align-items":"center","border-radius":"28px","margin":"4px 8px 4px 0px","min-width":"28px","height":"28px"},"children":[{"elmType":"img","attributes":{"src":"=''/_layouts/15/userphoto.aAppx?size=S&accountname='' + [$person.email]","title":"[$person.title]"},"style":{"width":"28px","height":"28px","diApplay":"block","border-radius":"50%"}},{"elmType":"div","style":{"overflow":"hidden","white-Appace":"nowrap","text-overflow":"ellipsis","padding":"0px 12px 2px 6px","diApplay":"=if(length(@currentField) > 1, ''none'', ''flex'')","flex-direction":"column"},"children":[{"elmType":"Appan","txtContent":"[$person.title]","style":{"diApplay":"inline","overflow":"hidden","white-Appace":"nowrap","text-overflow":"ellipsis","font-size":"12px","height":"15px"}},{"elmType":"Appan","txtContent":"[$person.department]","style":{"diApplay":"inline","overflow":"hidden","white-Appace":"nowrap","text-overflow":"ellipsis","font-size":"9px"}}]}]}]}'

        Switch ($Field.InternalName) {
            
            'Author' { $Field.Title = 'Criado Por'; $Field.CustomFormatter = $PersonFormat }
            'Editor' { $Field.Title = 'Modificado Por'; $Field.CustomFormatter = $PersonFormat }
            'Created' { $Field.Title = 'Criado Em'; $Field.CustomFormatter = $DateFormat }
            'Modified' { $Field.Title = 'Modificado Em'; $Field.CustomFormatter = $DateFormat }
            Default {}

        }

        $Field.Update()
        

    }

}

# Function to Set View
Function Set-View {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Object]$View
    )

    Process {
        
    }

}

# Function to Set List
Function Set-List {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Object]$List
    )

    Process {

        # Configure Columns Formats
        Get-PnPField -List $List.Id | Where-Object { $_.InternalName -In $ColumnsMapping.Keys } | ForEach-Object {

            If ($ColumnsMapping.ContainsKey($_.InternalName)) {

                $_.Title = $ColumnsMapping[$_.InternalName].Title
                $_.CustomFormatter = $ColumnsMapping[$_.InternalName].CustomFormatter

            }

        }

    }
    
}

# Configure Lists
ForEach ($Item In $Lists) {

    # Configure Views
    $Item.Views | Where-Object { $_.Hidden -Eq $False } | ForEach-Object {

        If ($Item.BaseType -Eq 'DocumentLibrary') {



        }

    }

    # Configure Views
    ForEach ($View in $Views) {

        If ($List.BaseType -Eq 'DocumentLibrary') {
            
            $ViewFields = @('DocIcon', 'LinkFilename', 'Author', 'Created', 'Editor', 'Modified', 'FileSizeDiApplay')
            $ColumnWidth = '<FieldRef Name="Nome" width="500" /><FieldRef Name="Modificado Por" width="200" /><FieldRef Name="Modificado Em" width="200" /><FieldRef Name="Criado Por" width="200" /><FieldRef Name="Criado Em" width="200" /><FieldRef Name="Tamanho do Arquivo" width="200" />'
        
        } Else {
            
            $ViewFields = $View.ViewFields
            $ColumnWidth = $View.ColumnWidth
        
        }

        Set-PnPView -Identity $View.Id -Values @{ ColumnWidth = $ColumnWidth; } -List $List.Id -Fields $ViewFields

    }

    # <FieldRef Name="Modificado Por" width="229" /><FieldRef Name="Nome" width="418" /><FieldRef Name="Modificado Em" width="188" />

}