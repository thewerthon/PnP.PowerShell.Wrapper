Function Test-Field {

    Param(
        [Parameter(ValueFromPipeline = $True)][Object]$Field,
        [Switch]$Silent
    )

    Try {

        If (-Not ((Test-SingleObject $View -Silent:$Silent) -And (Test-Properties $View Id, InternalName, Title -Silent:$Silent))) {

            Write-Message "Invalid field." -Color "Red" -Silent:$Silent
            Return $False

        } Else {

            Return $True

        }

    } Catch {

        Write-Message $_.Exception.Message -Color "Red" -Silent:$Silent
        Return $False

    }

}

Function Get-Fields {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$List
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        
    }

    Process {

        $Connection = Connect-Site $List.ParentSite -Return -Silent
        $Fields = Get-PnPField -List $List.Id -Connection $Connection | Where-Object { $_.Hidden -Eq $False }

        Return $Fields | ForEach-Object {

            $_
            | Add-Member -NotePropertyName "ParentList" -NotePropertyValue $List -PassThru

        }

    }

}

Function Get-Field {

    Param(
        [Parameter(Mandatory = $True)][String]$Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$List
    )

    Process {
        
        $Field = Get-Fields $List | Where-Object { $_.Id -Eq $Identity -Or $_.InternalName -EQ $Identity -Or $_.Title -EQ $Identity }
        If ($Field) { Return $Field[0] }

    }

}

Function Set-Field {

    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)][Object]$Field,
        [Switch]$DisplayInfos,
        [Switch]$SuppressErrors,
        [Switch]$Silent
    )

    Begin {

        If (-Not (Test-TenantConnection -Silent:$Silent)) { Return }
        $DateFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","children":[{"elmType":"span","style":{"padding-left":"8px","padding-right":"8px","padding-bottom":"4px","font-size":"16px"},"attributes":{"iconName":"Calendar"}},{"elmType":"span","txtContent":"@currentField.displayValue","style":{"padding-bottom":"6px"}}]}'
        $PersonFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","style":{"display":"flex","flex-wrap":"wrap","overflow":"hidden"},"children":[{"elmType":"div","forEach":"person in @currentField","defaultHoverField":"[$person]","attributes":{"class":"ms-bgColor-neutralLighter ms-fontColor-neutralSecondary"},"style":{"display":"flex","overflow":"hidden","align-items":"center","border-radius":"28px","margin":"4px 8px 4px 8px","min-width":"28px","height":"28px"},"children":[{"elmType":"img","attributes":{"src":"=''/_layouts/15/userphoto.aspx?size=S&accountname='' + [$person.email]","title":"[$person.title]"},"style":{"width":"28px","height":"28px","display":"block","border-radius":"50%"}},{"elmType":"div","style":{"overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis","padding":"0px 12px 2px 6px","display":"=if(length(@currentField) > 1, ''none'', ''flex'')","flex-direction":"column"},"children":[{"elmType":"span","txtContent":"[$person.title]","style":{"display":"inline","overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis","font-size":"12px","height":"15px"}},{"elmType":"span","txtContent":"[$person.department]","style":{"display":"inline","overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis","font-size":"9px"}}]}]}]}'

    }

    Process {

        Switch ($Field.InternalName) {
            
            'Author' { $FieldParams = @{Title = "Criado Por"; CustomFormatter = $PersonFormat }; Break }
            'Editor' { $FieldParams = @{Title = "Modificado Por"; CustomFormatter = $PersonFormat }; Break }
            'Created' { $FieldParams = @{Title = "Criado Em"; CustomFormatter = $DateFormat }; Break }
            'Modified' { $FieldParams = @{Title = "Modificado Em"; CustomFormatter = $DateFormat }; Break }
            Default { $FieldParams = $Null }

        }

        If ($FieldParams) {

            Invoke-Operation -Message "Setting parameters to field: $($Field.ParentList.ParentSite.Title) - $($Field.ParentList.Title) - $($Field.InternalName)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
                $Connection = Connect-Site $Field.ParentList.ParentSite -Return -Silent
                Set-PnPField -Identity $Field.Id -List $Field.ParentList.Id -Values $FieldParams -Connection $Connection
            
            }

        }

    }
    
}
