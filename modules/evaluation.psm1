# This module evaluates the users and resolve the subgroups of the Maingroup.

function Get-GroupUserEvaluation {
    param (
       [Parameter(Mandatory)][string]$groupName,
       [Parameter(Mandatory)][string]$outputPath,
       [int]$maxDepth = 10
    )
    Write-Log "--------------------------------------------------------------------" INFO
    Write-Log ""
    Write-Log "Start user evaluation of group: $($groupName)" INFO

    $users = @{}

    function Resolve-Group {
        param (
            [string]$group,
            [int]$depth
        )
        
        if ($depth -gt $maxDepth) {
            Write-Log "Maximum depth reached $($group)" ERROR
            return
        }

        Write-Log "Investigate group: $($group) (Depth: $($depth))"

        $members = Get-ADGroupMember -Identity $group

        foreach ($member in $members) {
            switch ($member.objectClass) {
                "user" { 
                    if (-not $users.ContainsKey($member.samAccountName)) {
                        $users[$member.samAccountName] = [PSCustomObject]@{
                            samAccountName = $member.samAccountName
                            DisplayName = $member.Name
                        }
                    }
                 }
                "group" { 
                    Resolve-Group -group $member.samAccountName -depth ($depth + 1)
                 }
            }
        }
    }

    Resolve-Group -group $groupName -depth 0
    $resultFile = Join-Path $outputPath "$($groupName)_evaluation_result.json"

    $users.Values | 
    Sort-Object samAccountName | 
    Convertto-Json -Depth 3 | 
    Set-Content -Path $resultFile -Encoding UTF8

    Write-Log "User evaluation finished. Result: $($resultFile)" SUCCESS
    return $resultFile
}


Export-ModuleMember -Function Get-GroupUserEvaluation



