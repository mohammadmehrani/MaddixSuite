Register-Tool @{
    ID          = 'AD-024'
    Name        = 'AD Cleanup (Orphaned Objects)'
    Category    = 'AD'
    Description = 'Find and permanently remove orphaned/deleted AD objects'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Find and permanently remove all orphaned AD objects?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Scanning for orphaned AD objects..." "Cyan"
            $orphans = Get-ADObject -Filter 'isDeleted -eq $true' -IncludeDeletedObjects -ErrorAction SilentlyContinue
            if ($orphans) {
                Write-Color "  [!] Found $($orphans.Count) deleted objects" "Yellow"
                $orphans | Select-Object -First 20 | Format-Table Name, ObjectClass, Deleted -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
                if ($orphans.Count -gt 20) {
                    Write-Color "  [i] ... and $($orphans.Count - 20) more" "Gray"
                }
                $choice = Read-Host "  [?] Permanently remove all deleted objects? (y/N)"
                if ($choice -eq 'y') {
                    $orphans | Remove-ADObject -IncludeDeletedObjects -Confirm:$false
                    Write-Color "  [+] Cleaned up $($orphans.Count) objects" "Green"
                }
            } else {
                Write-Color "  [+] No orphaned objects found" "Green"
            }
        } catch {
            Write-Color "  [!] Cleanup failed: $_" "Red"
        }
        Pause
    }
}
