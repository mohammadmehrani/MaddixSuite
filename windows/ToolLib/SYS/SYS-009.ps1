Register-Tool @{
    ID          = 'SYS-009'
    Name        = 'Windows Update Manager'
    Category    = 'SYS'
    Description = 'Check Windows Update status, install updates, view update history'
    DangerLevel = 'Caution'
    ConfirmMessage = 'May install Windows updates. System reboot may be required.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0")
            Write-Color "  Available updates: $($searchResult.Updates.Count)" "White"
            if ($searchResult.Updates.Count -gt 0) {
                foreach ($u in $searchResult.Updates) {
                    Write-Color "    [$($u.IsDownloaded ? 'Downloaded' : 'Pending')] $($u.Title)" "Gray"
                }
                if ((Read-Host "  Install all pending updates? (Y/N)") -match '^[Yy]') {
                    $updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
                    $searchResult.Updates | ForEach-Object { $updatesToDownload.Add($_) | Out-Null }
                    $updateSession.CreateUpdateDownloader().Downloads = $updatesToDownload
                    $updateSession.CreateUpdateDownloader().Download()
                    Write-Color "  Updates downloaded. Installing..." "Cyan"
                    $installer = $updateSession.CreateUpdateInstaller()
                    $installResult = $installer.Install()
                    Write-Color "  Installation result: $($installResult.ResultCode)" "Green"
                    if ($installResult.RebootRequired) { Write-Color "  ⚠ Reboot required" "Yellow"; $script:PendingReboot = $true }
                }
            }
        } catch { Write-Color "  [!] Update check failed: $_" "Red" }
        Pause
    }
}
