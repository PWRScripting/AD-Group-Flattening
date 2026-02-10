function Get-GroupTreeInternal {
    param(
        [Parameter(Mandatory)][string]$groupDN,
        [int]$depth = 0,
        [int]$maxDepth = 10,
        [System.Collections.Generic.HashSet[string]]$path
    )


    # MaxDepth Schutz
    if ($depth -ge $maxDepth) {
        return [PSCustomObject]@{
            Name = "Maximale erlaubte Ebene erreicht: $($maxDepth)"
            Members = @()
        }
    }

    # Zyklusprüfung nur innerhalb des aktuellen Pfads
    if ($path.Contains($groupDN)) {
        return [PSCustomObject]@{
            Name    = "[SCHLEIFE erkannt]"
            DN      = $groupDN
            Members = @()
        }
    }

    # Pfad-Kopie für diesen Zweig
    $currentPath = [System.Collections.Generic.HashSet[string]]::new($Path)
    $null = $currentPath.Add($groupDN)

    try {
        $group = Get-ADGroup -Identity $groupDN -Properties DisplayName -ErrorAction Stop
    }
    catch {
        return [PSCustomObject]@{
            Name = "UNBEKANNTE GRUPPE"
            Error = $_.Exception.Message
            Members = @()
        }
    }

    $groupName = IF ($group.DisplayName) {
        $group.DisplayName
    } 
    else {
        $group.Name
    }

    try {
        $groupMembers = Get-ADGroupMember -Identity $groupDN -ErrorAction Stop
    }
    catch {
        return [PSCustomObject]@{
            Name = $groupName
            Error = "Mitglieder konnten nicht aufgelöst werden"
            Members = @()
        }
    }

    $members = foreach ($member in $groupMembers) {
        switch ($member.objectClass) {
            "user" {
                $member.Name
              }

            "group" {
                Get-GroupTreeInternal `
                -groupDN $member.DistinguishedName `
                -depth  ($depth +1 ) `
                -maxDepth $maxDepth `
                -path $currentPath
              }
            Default {
                [PSCustomObject]@{
                    Name = $member.Name
                    Type = $member.objectClass
                }
            }
        }
    }

    [PSCustomObject]@{
        Name = $groupName
        Members = $members
    }
}

function Get-GroupTree {
    param (
        [Parameter(Mandatory)][string]$groupIdentity,
        [int]$maxDepth = 10
    )

    try {
        $grp = Get-ADGroup -Identity $groupIdentity -ErrorAction Stop
    }
    catch {
        Write-Log "Gruppe '$($groupIdentity)' konnte nicht gefunden werden" ERROR
        Write-Log "Fehler: $($_.Exception.Message)"
        Rename-Logfile -groupName $Global:mainGroupName
        throw
    }

    $initalPath = [System.Collections.Generic.HashSet[string]]::new()

    Write-Log "Lese die aktuelle Gruppenstruktur: '$($grp.Name)'"

    $tree = Get-GroupTreeInternal `
        -groupDN $grp.DistinguishedName `
        -depth 0 `
        -maxDepth $maxDepth `
        -path $initalPath

    return $tree
    
}

function New-GroupBackup {
    param (
        [Parameter(Mandatory)][string]$groupIdentity,
        [Parameter(Mandatory)][string]$outputDirectory,
        [int]$maxDepth = 10
    )

    try {
        if (-not (Test-Path -LiteralPath $outputDirectory)) {
            New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
            Write-Log "Backup-Ordner erstellt: $($outputDirectory)" SUCCESS
        }

        $tree = Get-GroupTree -groupIdentity $groupIdentity -maxDepth $maxDepth

        $displayName = $tree.Name
        $safeFileName = $displayName -replace '[\\/:*?"<>|]', '_'
        $file = Join-Path $outputDirectory ("$($safeFileName)_$(Get-Date -format 'dd-MM-yyyy').json")

        $tree | ConvertTo-Json -Depth 50 | Out-File -FilePath $file -Encoding utf8

        Write-Log "Backup der Gruppe wurde geschrieben." SUCCESS
        return $file
    }
    catch {

        Write-Log "Fehler beim erstellen des Backups:" ERROR
        Write-Log "Fehler: $($_.Exception.Message)" ERROR
        Rename-Logfile -groupName $Global:mainGroupName
        throw
        
    }

    Export-ModuleMember -Function Get-GroupTree, New-GroupBackup
    
}
