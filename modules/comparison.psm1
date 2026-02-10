function Compare-AndFlattenGroupUsers {
    param(
        [Parameter(Mandatory)][string]$mainGroup,
        [Parameter(Mandatory)][string]$evaluationFile,
        [Parameter(Mandatory)][string]$outputPath
        
    )

    # direkte User ermitteln
    $directUsers = Get-AdgroupMember -Identity $mainGroup | 
                   Where-Object objectClass -eq 'user' |
                   Select-Object -ExpandProperty samAccountName
    
    # alle User aus der vorherigen Auswertung laden
    $evaluatedUsers = Get-Content $evaluationFile | ConvertFrom-Json

    # Nur die User ermitteln welche indirekt sind.
    $indirectOnly  = $evaluatedUsers | Where-Object {$_.samAccountName -notin $directUsers}

    if (-not $indirectOnly ) {
        Write-Log "Keine Indirekt berechtigten User gefunden.(Duplikate ausgeschlossen)" SUCCESS
        return
    }

    # Gib alle User aus welche indirekt Berechtigt sind.
    Write-Log "Folgende User sind indirekt berechtigt: " INFO
    Write-Log ""
    $indirectOnly | ForEach-Object { Write-Log "$($_.samAccountName) $($_.DisplayName)" INFO}
    Write-Log "" INFO

    Write-Log "Es wurden $($indirectOnly.Count) indirekt berechtigte User gefunden." INPUT
    Write-Log "Sollen diese direkt in $($mainGroup) berechtigt werden?" INPUT

    # Userimput 
    Add-Type -AssemblyName System.Windows.Forms
    $result = [System.Windows.Forms.Messagebox]::Show(
        "Es wurden $($indirectOnly.Count) indirekt berechtigte User gefunden `n" + 
        "Sollen diese direkt in $($mainGroup) berechtigt werden?",
        "AD Gruppen-Bereinigen",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($result -ne 'Yes') {
        Write-Log "Auswahl: Nein" INPUT
        Write-Log "Es wird nichts angepasst."
        return
    }
    else {
        Write-Log "Auswahl: Ja" INPUT
        Write-Log "Beginne mit der Anpassung der User zur Gruppe."
        Write-Log ""
    }

    $addedUsers = @()

    foreach ($user in $indirectOnly) {
        try {
            Add-ADGroupMember -Identity $mainGroup -Members $user.samAccountName
            Write-Log "User erfolgreich berechtigt: $($user.samAccountName) $($user.DisplayName)" SUCCESS
            $addedUsers += [PSCustomObject]@{
                samAccountName  = $user.samAccountName
                Name     = $user.DisplayName
                Action         = "Added to $($mainGroup)"
            }
        }
        catch {
            Write-Log "Fehler beim User: $($user.samAccountName):" ERROR
            Write-Log "User konnte nicht berechtigt werden" ERROR
            Write-Log "Fehler: $($_.Exception.Message)" ERROR
            
        }
    }

    # Ergebnis in einer Result.csv Datei ausgeben welche User konnten erfolreich hinzugefügt werden.
    $csvFile = Join-Path $outputPath "$($mainGroup)_result_$(Get-Date -Format "dd-MM-yyyy").csv"
    $addedUsers | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

    Write-Log "Ergebnisdatei erstellt: $($csvFile)" SUCCESS



}


function Compare-AndRemoveSubGroups {
    param (
        [Parameter(Mandatory)][string]$mainGroup,
        [Parameter(Mandatory)][string]$outputPath
    )

    $subGroups = @(Get-ADGroupMember -Identity $mainGroup | 
                 Where-Object objectClass -eq 'group'
    )

    if (-not $subGroups) {
        Write-Log "Keine Untergruppen gefunden" SUCCESS
        return
    }

    Write-Log "Folgende Untergruppen wurden gefunden: " INFO
    Write-Log ""
    $subGroups | ForEach-Object {
        Write-Log "$($_.Name)" INFO
    }
    Write-Log ""

    Write-Log "Es wurden $($subGroups.Count) Untergruppen gefunden." INPUT
    Write-Log "Sollen diese aus $($mainGroup) entfernt werden?" INPUT

    Add-Type -AssemblyName System.Windows.Forms
    $decision = [System.Windows.Forms.MessageBox]::Show(
        "Es wurden $($subGroups.Count) Untergruppen gefunden. `n" +
        "Sollen diese aus $($mainGroup) entfernt werden?",
        "AD Gruppen-Bereinigung",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageboxIcon]::Question
    )

    if ($decision -ne 'Yes') {
        Write-Log "Auswahl: Nein" INPUT
        Write-Log "Es werden keine Gruppen entfernt." INFO
        return
    }
    else {
        Write-Log "Auswahl: Ja" INPUT
        Write-Log "Beginne mit dem entfernen der Gruppen:"
        Write-Log ""
    }

    $removedGroups = @()

    foreach ($group in $subGroups) {
        try {
            Remove-ADGroupMember `
                -Identity $mainGroup `
                -Members $group.SamAccountName `
                -Confirm:$false

            Write-Log "Untergruppe entfernt $($group.Name)" SUCCESS
            $removedGroups += [PSCustomObject]@{
                samAccountName  = $group.SamAccountName
                Name            = $group.Name
                Action          = "Removed from $($mainGroup)" 
            }
        }
        catch {
            Write-Log "Fehler bei Gruppe: $($group.Name):" ERROR
            Write-Log "Untergruppe konnte nicht entfnert werden." ERROR
            Write-Log "Fehler: $($_.Exception.Message)" ERROR
            
        }
    }

    $csvFile = Join-Path $outputPath "$($mainGroup)_result_$(Get-Date -Format "dd-MM-yyyy").csv"
    $removedGroups | Export-Csv -Path $csvFile -Append -NoTypeInformation -Encoding UTF8 -Delimiter ";"

    Write-Log "CSV-Datei erstellt: $($csvFile)" SUCCESS
    
}


Export-ModuleMember -Function Compare-AndFlattenGroupUsers, Compare-AndRemoveSubGroups
