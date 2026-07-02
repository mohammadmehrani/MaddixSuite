Register-Tool @{
    ID          = 'CLN-006'
    Name        = 'Empty Folder Remover'
    Category    = 'CLN'
    Description = 'Find and remove empty directories'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Find and optionally remove all empty directories'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $paths = @()
            $paths += Read-Host "  [+] Enter root path(s) to scan (comma-separated, blank for entire C:\)"
            if (-not $paths -or $paths -eq '') { $paths = @("$env:SystemDrive\") }
            else { $paths = $paths -split ',' | ForEach-Object { $_.Trim() } }

            Write-Color "  [+] Scanning for empty directories..." "Yellow"
            $emptyDirs = @()
            foreach ($scanPath in $paths) {
                if (-not (Test-Path $scanPath)) {
                    Write-Color "  [!] Path not found: $scanPath" "Red"
                    continue
                }
                $dirs = Get-ChildItem -Path $scanPath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -notmatch 'System32|WinSxS|winsxs|Assembly|Microsoft\.NET' }
                foreach ($dir in $dirs) {
                    $children = Get-ChildItem -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    if (-not $children) {
                        $emptyDirs += $dir.FullName
                    }
                }
            }

            if ($emptyDirs.Count -eq 0) {
                Write-Color "  [+] No empty directories found" "Green"
                Pause
                return
            }

            Write-Color "  [+] Found $($emptyDirs.Count) empty directories" "Yellow"
            $emptyDirs | ForEach-Object { Write-Color "    $_" "Cyan" }

            $confirm = Read-Host "`n  [+] Remove all empty directories? (y/N)"
            if ($confirm -eq 'y') {
                $removed = 0
                foreach ($dir in $emptyDirs) {
                    try {
                        if (Test-Path $dir) {
                            Remove-Item -Path $dir -Force -ErrorAction SilentlyContinue
                            $removed++
                        }
                    } catch {}
                }
                Write-Color "  [+] Removed $removed empty directories" "Green"
            } else {
                Write-Color "  [+] No directories removed" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
