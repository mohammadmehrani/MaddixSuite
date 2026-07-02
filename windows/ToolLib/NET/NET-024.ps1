Register-Tool @{
    ID          = 'NET-024'
    Name        = 'SMB Share Browser'
    Category    = 'NET'
    Description = 'Browse network SMB shares and list shared resources'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Browses SMB shares on the network.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── SMB SHARE BROWSER ───" "Cyan"
        Write-Color "  1. List local SMB shares" "White"
        Write-Color "  2. Browse network computers (NetView)" "White"
        Write-Color "  3. List shares on remote computer" "White"
        Write-Color "  4. Browse share contents" "White"
        Write-Color "  5. Map network drive" "White"
        Write-Color "  6. List mapped drives" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                try {
                    $shares = Get-SmbShare -ErrorAction Stop
                    if (-not $shares) { Write-Color "  No local SMB shares." "Yellow"; break }
                    $shares | Select-Object Name, Path, Description, ShareType | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                    Write-Color "  Total shares: $($shares.Count)" "White"
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "2" {
                try {
                    Write-Color "  Scanning network for computers..." "Yellow"
                    $netview = net view
                    Write-Color "$netview" "Gray"
                } catch { Write-Color "  [!] NetView failed: $_" "Red" }
            }
            "3" {
                $remote = Read-Host "  Remote computer name or IP"
                try {
                    $shares = Get-SmbShare -CimSession $remote -ErrorAction Stop
                    $shares | Select-Object Name, Path, Description | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                } catch {
                    Write-Color "  [!] Failed to connect: $_" "Red"
                    Write-Color "  Trying net view..." "Yellow"
                    try {
                        $nv = net view "\\$remote"
                        Write-Color "$nv" "Gray"
                    } catch { Write-Color "  [!] Net view failed: $_" "Red" }
                }
            }
            "4" {
                $path = Read-Host "  UNC path (e.g. \\server\share)"
                try {
                    $items = Get-ChildItem -Path $path -ErrorAction Stop
                    if (-not $items) { Write-Color "  Share is empty." "Yellow"; break }
                    $items | Select-Object Name, Length, LastWriteTime, Mode | Format-Table -AutoSize -Wrap | Out-String | ForEach-Result { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "5" {
                $drive = Read-Host "  Drive letter (e.g. Z)"
                $path = Read-Host "  UNC path (e.g. \\server\share)"
                $persist = Read-Host "  Persistent? (y/N)"
                $persistFlag = if ($persist -eq "y") { "/persistent:yes" } else { "/persistent:no" }
                try {
                    net use "${drive}:" $path $persistFlag
                    Write-Color "  [+] Drive $drive mapped to $path" "Green"
                } catch { Write-Color "  [!] Failed to map drive: $_" "Red" }
            }
            "6" {
                try {
                    $mapped = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -and $_.DisplayRoot -match '^\\\\' }
                    if (-not $mapped) { Write-Color "  No mapped network drives." "Yellow"; break }
                    $mapped | Select-Object Name, Root, DisplayRoot, Used, Free | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
        }
        Pause
    }
}
