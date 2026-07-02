Register-Tool @{
    ID          = 'CLN-005'
    Name        = 'Duplicate File Finder'
    Category    = 'CLN'
    Description = 'Find duplicate files by hash'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Search for and report duplicate files in specified paths'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $paths = @()
            $paths += Read-Host "  [+] Enter paths to scan (comma-separated, or leave blank for C:\Users)"

            if (-not $paths -or $paths -eq '') { $paths = @("$env:USERPROFILE") }
            else { $paths = $paths -split ',' | ForEach-Object { $_.Trim() } }

            foreach ($scanPath in $paths) {
                if (-not (Test-Path $scanPath)) {
                    Write-Color "  [!] Path not found: $scanPath" "Red"
                    continue
                }
            }

            Write-Color "  [+] Scanning for duplicates (this may take a while)..." "Yellow"
            $hashTable = @{}
            $duplicates = @()
            $extensions = @('*.exe','*.dll','*.msi','*.zip','*.rar','*.7z','*.iso','*.mp4','*.avi','*.mkv','*.mp3','*.flac','*.jpg','*.png','*.gif','*.pdf','*.doc*','*.xls*','*.ppt*','*.txt','*.log','*.bak','*.old')

            foreach ($scanPath in $paths) {
                if (-not (Test-Path $scanPath)) { continue }
                $files = Get-ChildItem -Path $scanPath -Recurse -Force -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Length -gt 1024 -and $_.Length -lt 1GB }
                $count = 0
                foreach ($file in $files) {
                    try {
                        $hash = Get-FileHash -Path $file.FullName -Algorithm MD5 -ErrorAction SilentlyContinue
                        if ($hash) {
                            if ($hashTable.ContainsKey($hash.Hash)) {
                                $duplicates += [PSCustomObject]@{
                                    Hash = $hash.Hash
                                    File1 = $hashTable[$hash.Hash]
                                    File2 = $file.FullName
                                    SizeMB = [math]::Round($file.Length/1MB,2)
                                }
                            } else {
                                $hashTable[$hash.Hash] = $file.FullName
                            }
                        }
                    } catch {}
                    $count++
                    if ($count % 500 -eq 0) { Write-Color "    Scanned $count files..." "Cyan" }
                }
            }

            if ($duplicates.Count -gt 0) {
                $totalWaste = ($duplicates | Measure-Object -Property SizeMB -Sum).Sum
                Write-Color "`n  [+] Found $($duplicates.Count) duplicate groups ($([math]::Round($totalWaste,2)) MB wasted)" "Yellow"
                $duplicates | Group-Object Hash | ForEach-Object {
                    Write-Color "  --- Duplicate Group (Hash: $($_.Name)) ---" "Magenta"
                    $_.Group | Format-Table File1, File2, SizeMB -AutoSize
                }
                $export = Read-Host "`n  [+] Export results to CSV? (y/N)"
                if ($export -eq 'y') {
                    $csvPath = "$env:USERPROFILE\Desktop\Duplicates_$(Get-Date -Format yyyyMMdd).csv"
                    $duplicates | Export-Csv -Path $csvPath -NoTypeInformation
                    Write-Color "  [+] Exported to $csvPath" "Green"
                }
            } else {
                Write-Color "  [+] No duplicates found" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
