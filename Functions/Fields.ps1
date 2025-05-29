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
        
        $Field = Get-Fields $List | Where-Object { $_.Id -Like $Identity -Or $_.InternalName -Like $Identity -Or $_.Title -Like $Identity }
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
        $DateFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","children":[{"elmType":"span","style":{"padding-left":"8px","padding-right":"8px","padding-bottom":"4px","font-size":"16px","visibility":"=if(@currentField, ''visible'', ''hidden'')"},"attributes":{"iconName":"Calendar"}},{"elmType":"span","txtContent":"@currentField.displayValue","style":{"padding-bottom":"6px"}}]}'
        $ValidDateFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","style":{"box-sizing":"border-box","padding":"0 2px","overflow":"hidden","text-overflow":"ellipsis"},"attributes":{"class":""},"children":[{"elmType":"span","style":{"padding-left":"8px","padding-right":"8px","padding-bottom":"4px","font-size":"16px","display":{"operator":":","operands":[{"operator":"==","operands":["@currentField",""]},"none",{"operator":":","operands":[{"operator":"<","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"inherit",{"operator":":","operands":[{"operator":"==","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"inherit",{"operator":":","operands":[{"operator":">","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"inherit","none"]}]}]}]}},"attributes":{"iconName":{"operator":":","operands":[{"operator":"==","operands":["@currentField",""]},"",{"operator":":","operands":[{"operator":"<","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"ErrorBadge",{"operator":":","operands":[{"operator":"==","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"Error",{"operator":":","operands":[{"operator":">","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"Calendar",""]}]}]}]},"class":{"operator":":","operands":[{"operator":"==","operands":["@currentField",""]},"",{"operator":":","operands":[{"operator":"<","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"sp-css-color-DarkRedText",{"operator":":","operands":[{"operator":"==","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"sp-css-color-BrownText",{"operator":":","operands":[{"operator":">","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"sp-css-color-GreenText",""]}]}]}]}}},{"elmType":"span","style":{"overflow":"hidden","text-overflow":"ellipsis","padding-bottom":"6px"},"txtContent":"@currentField.displayValue","attributes":{"class":{"operator":":","operands":[{"operator":"==","operands":["@currentField",""]},"",{"operator":":","operands":[{"operator":"<","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"sp-field-fontSizeSmall sp-css-color-DarkRedText",{"operator":":","operands":[{"operator":"==","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"sp-field-fontSizeSmall sp-css-color-BrownText",{"operator":":","operands":[{"operator":">","operands":[{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@currentField"]}]},{"operator":"Date()","operands":[{"operator":"toDateString()","operands":["@now"]}]}]},"sp-field-fontSizeSmall sp-css-color-GreenText",""]}]}]}]}}}]}'
        $PersonFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","style":{"display":"flex","flex-wrap":"wrap","overflow":"hidden"},"children":[{"elmType":"div","forEach":"person in @currentField","defaultHoverField":"[$person]","attributes":{"class":"ms-bgColor-neutralLighter ms-fontColor-neutralSecondary"},"style":{"display":"flex","overflow":"hidden","align-items":"center","border-radius":"28px","margin":"4px 8px 4px 8px","min-width":"28px","height":"28px"},"children":[{"elmType":"img","attributes":{"src":"=''/_layouts/15/userphoto.aspx?size=S&accountname='' + [$person.email]","title":"[$person.title]"},"style":{"width":"28px","height":"28px","display":"block","border-radius":"50%"}},{"elmType":"div","style":{"overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis","padding":"0px 12px 2px 6px","display":"=if(length(@currentField) > 1, ''none'', ''flex'')","flex-direction":"column"},"children":[{"elmType":"span","txtContent":"[$person.title]","style":{"display":"inline","overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis","font-size":"12px","height":"15px"}},{"elmType":"span","txtContent":"[$person.department]","style":{"display":"inline","overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis","font-size":"9px"}}]}]}]}'
        $ModerationFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","style":{"flex-wrap":"wrap","display":"flex"},"children":[{"elmType":"div","style":{"box-sizing":"border-box","padding":"4px 8px 5px 8px","overflow":"hidden","text-overflow":"ellipsis","display":"flex","border-radius":"16px","height":"24px","align-items":"center","white-space":"nowrap","margin":"4px 4px 4px 4px"},"attributes":{"class":{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",3]},"sp-css-backgroundColor-BgLightGray sp-css-borderColor-LightGrayFont sp-field-fontSizeSmall sp-css-color-LightGrayFont",{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",2]},"sp-css-backgroundColor-BgGold sp-field-fontSizeSmall sp-css-color-GoldFont",{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",4]},"sp-css-backgroundColor-BgCornflowerBlue sp-css-borderColor-CornflowerBlueFont sp-field-fontSizeSmall sp-css-color-CornflowerBlueFont",{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",0]},"sp-css-backgroundColor-BgMintGreen sp-field-fontSizeSmall sp-css-color-MintGreenFont",{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",1]},"sp-css-backgroundColor-BgCoral sp-field-fontSizeSmall sp-css-color-CoralFont","sp-field-borderAllRegular sp-field-borderAllSolid sp-css-borderColor-neutralSecondary"]}]}]}]}]}},"txtContent":{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",3]},"Rascunho",{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",2]},"Pendente",{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",4]},"Agendado",{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",0]},"Publicado",{"operator":":","operands":[{"operator":"==","operands":["[$_ModerationStatus]",1]},"Reprovado","Desconhecido"]}]}]}]}]}}]}'
        $NoLinkFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","children":[{"elmType":"span","style":{"overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis","padding-left":"12px","padding-bottom":"4px"},"txtContent":"@currentField.lookupValue"}]}'
        $UnknownFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","children":[{"elmType":"span","style":{"overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis","padding-left":"12px","padding-bottom":"4px"},"txtContent":"=if(@currentField, @currentField, ''Indefinido''"}]}'
        $LevelFormat = '{"$schema":"https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json","elmType":"div","style":{"padding-left":"12px","padding-bottom":"4px","box-sizing":"border-box"},"children":[{"elmType":"span","style":{"overflow":"hidden","white-space":"nowrap","text-overflow":"ellipsis"},"txtContent":"=if(@currentField,''Nível '' + @currentField,'''')"}]}'
    
    }

    Process {

        Switch ($Field.InternalName) {
            
            'Author' { $FieldParams = @{Title = "Criado Por"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }
            'Editor' { $FieldParams = @{Title = "Modificado Por"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }
            'Created' { $FieldParams = @{Title = "Criado Em"; CustomFormatter = $DateFormat }; Break }
            'Modified' { $FieldParams = @{Title = "Modificado Em"; CustomFormatter = $DateFormat }; Break }

            'ElaboradoPor' { $FieldParams = @{Title = "Elaborado Por"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }
            'VerificadoPor' { $FieldParams = @{Title = "Verificado Por"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }
            'AprovadoPor' { $FieldParams = @{Title = "Aprovado Por"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }
            'PublicadoPor' { $FieldParams = @{Title = "Publicado Por"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }
            'RevisadoPor' { $FieldParams = @{Title = "Revisado Por"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }
            'InativadoPor' { $FieldParams = @{Title = "Inativado Por"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }

            'ElaboradoEm' { $FieldParams = @{Title = "Elaborado Em"; CustomFormatter = $DateFormat }; Break }
            'VerificadoEm' { $FieldParams = @{Title = "Verificado Em"; CustomFormatter = $DateFormat }; Break }
            'AprovadoEm' { $FieldParams = @{Title = "Aprovado Em"; CustomFormatter = $DateFormat }; Break }
            'PublicadoEm' { $FieldParams = @{Title = "Publicado Em"; CustomFormatter = $DateFormat }; Break }
            'RevisadoEm' { $FieldParams = @{Title = "Revisado Em"; CustomFormatter = $DateFormat }; Break }
            'InativadoEm' { $FieldParams = @{Title = "Inativado Em"; CustomFormatter = $DateFormat }; Break }
            'Validade' { $FieldParams = @{Title = "Válido Até"; CustomFormatter = $ValidDateFormat }; Break }

            'Origem' { $FieldParams = @{Title = "Origem"; CustomFormatter = $Null }; Break }
            'AreaDocumento' { $FieldParams = @{Title = "Área"; CustomFormatter = $NoLinkFormat }; Break }
            'CategoriaDocumento' { $FieldParams = @{Title = "Categoria"; CustomFormatter = $NoLinkFormat }; Break }
            '_ModerationStatus' { $FieldParams = @{Title = "Estado"; CustomFormatter = $ModerationFormat }; Break }
            '_ComplianceTag' { $FieldParams = @{Title = "Retenção"; CustomFormatter = $UnknownFormat }; Break }
            '_DisplayName' { $FieldParams = @{Title = "Confidencialidade"; CustomFormatter = $UnknownFormat }; Break }
            'Categoria_x003a_N_x00ed_vel' { $FieldParams = @{Title = "Nível"; CustomFormatter = $LevelFormat }; Break }
            'CheckoutUser' { $FieldParams = @{Title = "Check-Out"; CustomFormatter = $PersonFormat; UserDisplayOptions = "NamePhoto" }; Break }

            Default { $FieldParams = $Null }

        }

        If ($FieldParams) {

            Invoke-Operation -Message "Setting parameters to field: $($Field.ParentList.ParentSite.Title) - $($Field.ParentList.Title) - $($Field.InternalName)" -DisplayInfos:$DisplayInfos -SuppressErrors:$SuppressErrors -Silent:$Silent -Operation {
            
                $Connection = Connect-Site $Field.ParentList.ParentSite -Return -Silent
                If ($Field.ParentList.ParentSite.Url -Match "/personal/") { $FieldParams.CustomFormatter = $Null }
                Set-PnPField -Identity $Field.Id -List $Field.ParentList.Id -Values $FieldParams -Connection $Connection
            
            }

        }

    }
    
}
