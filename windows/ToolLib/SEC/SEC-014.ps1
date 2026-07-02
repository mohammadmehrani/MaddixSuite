Register-Tool @{
    ID          = 'SEC-014'
    Name        = 'Full Anti-Hack Scan'
    Category    = 'SEC'
    Description = 'Calls Maddix-AntiHack.ps1 scan'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Run the full Maddix Anti-Hack scan'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Maddix-AntiHack.ps1' -ErrorAction SilentlyContinue
            if (-not (Test-Path $scriptPath)) {
                $scriptPath = Join-Path -Path $env:USERPROFILE -ChildPath 'Documents\GitHub\MaddixSuite\Maddix-AntiHack.ps1'
            }
            if (-not (Test-Path $scriptPath)) {
                $scriptPath = Join-Path -Path $env:ProgramData -ChildPath 'MaddixSuite\Maddix-AntiHack.ps1'
            }
            $search = Get-ChildItem -Path $env:USERPROFILE -Filter 'Maddix-AntiHack.ps1' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($search) { $scriptPath = $search.FullName }

            if (Test-Path $scriptPath) {
                Write-Color "  [+] Found Maddix-AntiHack.ps1 at:" "Green"
                Write-Color "      $scriptPath" "Cyan"
                Write-Color "`n  [+] Launching Full Anti-Hack Scan..." "Yellow"
                & $scriptPath
                Write-Color "`n  [+] Scan completed" "Green"
            } else {
                Write-Color "  [!] Maddix-AntiHack.ps1 not found." "Red"
                Write-Color "  [!] Searched locations:" "Red"
                Write-Color "      - ..\..\Maddix-AntiHack.ps1 (relative to tool)" "Red"
                Write-Color "      - Documents\GitHub\MaddixSuite\Maddix-AntiHack.ps1" "Red"
                Write-Color "      - %ProgramData%\MaddixSuite\Maddix-AntiHack.ps1" "Red"
                Write-Color "      - Recursive search under $env:USERPROFILE" "Red"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
