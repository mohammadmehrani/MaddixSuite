Register-Tool @{
    ID          = 'CLN-002'
    Name        = 'Browser Cache Cleaner'
    Category    = 'CLN'
    Description = 'Clear Chrome/Firefox/Edge caches'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Clear browser caches for Chrome, Firefox, and Edge'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $cachePaths = @(
                @{Name='Chrome'; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"},
                @{Name='Chrome Code Cache'; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"},
                @{Name='Edge'; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"},
                @{Name='Edge Code Cache'; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"},
                @{Name='Firefox Cache'; Path="$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"},
                @{Name='Firefox Offline Cache'; Path="$env:APPDATA\Mozilla\Firefox\Profiles"}
            )
            $totalSize = 0
            foreach ($entry in $cachePaths) {
                $target = $entry.Path
                if ($entry.Name -like 'Firefox*' -and -not (Test-Path $target)) {
                    $ff = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue
                    if ($ff) {
                        $target = Join-Path $ff[0].FullName 'cache2'
                    }
                }
                if (Test-Path $target) {
                    $size = (Get-ChildItem -Path $target -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
                    $sizeMB = [math]::Round($size/1MB,2)
                    Write-Color "  [+] $($entry.Name): $sizeMB MB" "Cyan"
                    Remove-Item -Path "$target\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $totalSize += $size
                } else {
                    Write-Color "  [+] $($entry.Name): Not found, skipping" "Yellow"
                }
            }
            Write-Color "  [+] Total freed: $([math]::Round($totalSize/1MB,2)) MB" "Green"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
