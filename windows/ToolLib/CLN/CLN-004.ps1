Register-Tool @{
    ID          = 'CLN-004'
    Name        = 'Old Windows Versions'
    Category    = 'CLN'
    Description = 'Remove Windows.old and previous installations'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Permanently remove Windows.old and previous installation files'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $winOld = "$env:SystemDrive\Windows.old"
            if (-not (Test-Path $winOld)) {
                Write-Color "  [!] Windows.old not found on $env:SystemDrive" "Yellow"
                $altPaths = Get-ChildItem -Path "$env:SystemDrive\" -Directory -Filter 'Windows.*' -ErrorAction SilentlyContinue
                if ($altPaths) {
                    Write-Color "  [+] Found alternate old installations:" "Cyan"
                    $altPaths | ForEach-Object { Write-Color "      $($_.FullName)" "Cyan" }
                }
                Pause
                return
            }

            $size = (Get-ChildItem -Path $winOld -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
            Write-Color "  [+] Windows.old found: $([math]::Round($size/1GB,2)) GB" "Yellow"

            $confirm = Read-Host "  [!] This action is irreversible. Proceed? (y/N)"
            if ($confirm -ne 'y') {
                Write-Color "  [+] Aborted" "Green"
                Pause
                return
            }

            Write-Color "  [+] Taking ownership..." "Yellow"
            takeown /F "$winOld\*" /R /A /D Y 2>$null | Out-Null
            icacls "$winOld\*" /grant Administrators:F /T /Q 2>$null | Out-Null

            Write-Color "  [+] Removing Windows.old..." "Yellow"
            Remove-Item -Path "$winOld\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $winOld -Recurse -Force -ErrorAction SilentlyContinue

            if (-not (Test-Path $winOld)) {
                Write-Color "  [+] Windows.old removed successfully" "Green"
            } else {
                Write-Color "  [!] Some files could not be removed. Try using Disk Cleanup instead." "Red"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
