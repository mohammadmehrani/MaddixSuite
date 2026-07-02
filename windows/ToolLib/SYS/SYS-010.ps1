Register-Tool @{
    ID          = 'SYS-010'
    Name        = 'Disk Space Analyzer'
    Category    = 'SYS'
    Description = 'Show disk usage by directory and file type, find large files'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Scans disk space usage.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        $drive = Read-Host "  Drive to analyze (Enter for C:)"
        if (-not $drive) { $drive = "C:" }
        Write-Color "  Analyzing $drive..." "Cyan"
        $logical = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$drive'" -ErrorAction SilentlyContinue
        if ($logical) {
            Write-Color "  $($logical.DeviceID) - $([math]::Round($logical.Size/1GB,1)) GB total" "White"
            Write-Color "  Used: $([math]::Round(($logical.Size - $logical.FreeSpace)/1GB,1)) GB" "Yellow"
            Write-Color "  Free: $([math]::Round($logical.FreeSpace/1GB,1)) GB" "Green"
            Write-Color "  Usage: $([math]::Round(($logical.Size - $logical.FreeSpace)/$logical.Size*100,1))%" "Gray"
        }
        Write-Color "`n  Top 15 directories on $drive:" "Cyan"
        $topDir = Get-ChildItem "$drive\" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{ Name = $_.Name; Size = [math]::Round($size/1MB,1) }
        } | Sort-Object Size -Descending | Select-Object -First 15
        $topDir | Format-Table Name, @{N="Size (MB)";E={$_.Size}} -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
        Pause
    }
}
