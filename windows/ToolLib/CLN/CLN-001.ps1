Register-Tool @{
    ID          = 'CLN-001'
    Name        = 'Temp Files Cleaner'
    Category    = 'CLN'
    Description = 'Clean Windows temp, user temp, prefetch, recent'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Clean temporary files from system and user locations'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $paths = @(
                "$env:WINDIR\Temp",
                "$env:TEMP",
                "$env:WINDIR\Prefetch",
                "$env:USERPROFILE\Recent"
            )
            $totalSize = 0; $totalFiles = 0
            foreach ($path in $paths) {
                if (Test-Path $path) {
                    $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    $fileCount = ($items | Where-Object { -not $_.PSIsContainer }).Count
                    $size = ($items | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
                    Write-Color "    $path - $fileCount files, $([math]::Round($size/1MB,2)) MB" "Cyan"
                    Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $totalSize += $size
                    $totalFiles += $fileCount
                }
            }
            Write-Color "  [+] Cleaned $totalFiles files, $([math]::Round($totalSize/1MB,2)) MB freed" "Green"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
