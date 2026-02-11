<#
This module compares directly permitted users with indirectly permitted users and sets the new permissions. 
In addition, once users have been permitted, the subgroups are removed from the Maingroup.
#>

function Compare-AndFlattenGroupUsers {
    param(
        [Parameter(Mandatory)][string]$mainGroup,
        [Parameter(Mandatory)][string]$evaluationFile,
        [Parameter(Mandatory)][string]$outputPath
        
    )

    # Identify directly permitted Users
    $directUsers = Get-AdgroupMember -Identity $mainGroup | 
                   Where-Object objectClass -eq 'user' |
                   Select-Object -ExpandProperty samAccountName
    
    # Load all users from the created evaluation file.
    $evaluatedUsers = Get-Content $evaluationFile | ConvertFrom-Json

    # Identify only the indirectly permitted users.
    $indirectOnly  = $evaluatedUsers | Where-Object {$_.samAccountName -notin $directUsers}

    if (-not $indirectOnly ) {
        Write-Log "No indirectly permitted users found. (Duplicates excluded)" SUCCESS
        return
    }

    # OUtput all idirect permitted users.
    Write-Log "The following users have indirect permissions:" INFO
    Write-Log ""
    $indirectOnly | ForEach-Object { Write-Log "$($_.samAccountName) $($_.DisplayName)" INFO}
    Write-Log "" INFO

    Write-Log "$($indirectOnly.Count) indirectly permitted users were found." INPUT
    Write-Log "Should these be permitted directly under the group: $($mainGroup) ?" INPUT

    # Userimput 
    Add-Type -AssemblyName System.Windows.Forms
    $result = [System.Windows.Forms.Messagebox]::Show(
        "$($indirectOnly.Count) indirectly permitted users were found. `n" + 
        "Should these be permitted directly under the group: $($mainGroup) ?",
        "AD-Group-Flattening",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($result -ne 'Yes') {
        Write-Log "Selection: NO" INPUT
        Write-Log "Nothing will be changed."
        return
    }
    else {
        Write-Log "Selection: Yes" INPUT
        Write-Log "Start by assigning users to the group."
        Write-Log ""
    }

    $addedUsers = @()

    foreach ($user in $indirectOnly) {
        try {
            Add-ADGroupMember -Identity $mainGroup -Members $user.samAccountName
            Write-Log "User successfully permitted: $($user.samAccountName) $($user.DisplayName)" SUCCESS
            $addedUsers += [PSCustomObject]@{
                samAccountName  = $user.samAccountName
                Name     = $user.DisplayName
                Action         = "Added to $($mainGroup)"
            }
        }
        catch {
            Write-Log "Error on user: $($user.samAccountName):" ERROR
            Write-Log "User could not be permitted." ERROR
            Write-Log "Error: $($_.Exception.Message)" ERROR
            
        }
    }

    # Result file for all successfully added users.
    $csvFile = Join-Path $outputPath "$($mainGroup)_result_$(Get-Date -Format "dd-MM-yyyy").csv"
    $addedUsers | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

    Write-Log "Result file erstellt: $($csvFile)" SUCCESS



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
        Write-Log "No subgroups are found." SUCCESS
        return
    }

    Write-Log "The following subgroups were found: " INFO
    Write-Log ""
    $subGroups | ForEach-Object {
        Write-Log "$($_.Name)" INFO
    }
    Write-Log ""

    Write-Log "$($subGroups.Count) subgroups were found." INPUT
    Write-Log "Should these be removed from gorup: $($mainGroup)?" INPUT

    Add-Type -AssemblyName System.Windows.Forms
    $decision = [System.Windows.Forms.MessageBox]::Show(
        "$($subGroups.Count) subgroups were found. `n" +
        "Should these be removed from gorup: $($mainGroup)?",
        "AD-Group-Flattening",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageboxIcon]::Question
    )

    if ($decision -ne 'Yes') {
        Write-Log "Selection: No" INPUT
        Write-Log "No subgroups will be removed." INFO
        return
    }
    else {
        Write-Log "Selection: Yes" INPUT
        Write-Log "Start by removing the subgroups:"
        Write-Log ""
    }

    $removedGroups = @()

    foreach ($group in $subGroups) {
        try {
            Remove-ADGroupMember `
                -Identity $mainGroup `
                -Members $group.SamAccountName `
                -Confirm:$false

            Write-Log "U $($group.Name)" SUCCESS
            $removedGroups += [PSCustomObject]@{
                samAccountName  = $group.SamAccountName
                Name            = $group.Name
                Action          = "Removed from $($mainGroup)" 
            }
        }
        catch {
            Write-Log "Error on subgroup: $($group.Name):" ERROR
            Write-Log "Subgroup could not be removed." ERROR
            Write-Log "Error: $($_.Exception.Message)" ERROR
            
        }
    }

    $csvFile = Join-Path $outputPath "$($mainGroup)_result_$(Get-Date -Format "dd-MM-yyyy").csv"
    $removedGroups | Export-Csv -Path $csvFile -Append -NoTypeInformation -Encoding UTF8 -Delimiter ";"

    Write-Log "Result appended to file: $($csvFile)" SUCCESS
    
}


Export-ModuleMember -Function Compare-AndFlattenGroupUsers, Compare-AndRemoveSubGroups
