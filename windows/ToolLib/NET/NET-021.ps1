Register-Tool @{
    ID          = 'NET-021'
    Name        = 'WireShark Mini'
    Category    = 'NET'
    Description = 'Packet capture helper using netsh trace'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Captures network packets using netsh trace (requires admin).'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── PACKET CAPTURE (NETSH TRACE) ───" "Cyan"
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Color "  [!] Administrator privileges required for packet capture." "Red"
            Write-Color "  Please run as Administrator." "Yellow"
            Pause
            return
        }
        Write-Color "  1. Start capture (all traffic)" "White"
        Write-Color "  2. Start capture (HTTP only)" "White"
        Write-Color "  3. Start capture (DNS only)" "White"
        Write-Color "  4. Stop capture and generate report" "White"
        Write-Color "  5. Show capture status" "White"
        Write-Color "  6. List capture providers" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                $output = "$env:TEMP\NetCapture_$(Get-Date -Format 'yyyyMMdd_HHmmss').etl"
                try {
                    netsh trace start capture=yes report=no tracefile=$output maxsize=256
                    Write-Color "  [+] Capture started -> $output" "Green"
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "2" {
                $output = "$env:TEMP\NetCapture_HTTP_$(Get-Date -Format 'yyyyMMdd_HHmmss').etl"
                try {
                    netsh trace start provider=Microsoft-Windows-HttpService capture=yes tracefile=$output maxsize=128
                    Write-Color "  [+] HTTP capture started -> $output" "Green"
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "3" {
                $output = "$env:TEMP\NetCapture_DNS_$(Get-Date -Format 'yyyyMMdd_HHmmss').etl"
                try {
                    netsh trace start provider=Microsoft-Windows-DNS-Client capture=yes tracefile=$output maxsize=128
                    Write-Color "  [+] DNS capture started -> $output" "Green"
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "4" {
                try {
                    netsh trace stop
                    Write-Color "  [+] Capture stopped" "Green"
                    $etlFiles = Get-ChildItem "$env:TEMP\*.etl" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                    if ($etlFiles) {
                        Write-Color "  Last capture: $($etlFiles.FullName) ($('{0:N2}' -f ($etlFiles.Length / 1MB)) MB)" "White"
                        $convert = Read-Host "  Convert to text report? (y/N)"
                        if ($convert -eq "y") {
                            $report = $etlFiles.FullName -replace '\.etl$', '.txt'
                            netsh trace convert input=$($etlFiles.FullName) output=$report
                            Write-Color "  [+] Report generated: $report" "Green"
                        }
                    }
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "5" {
                try {
                    $status = netsh trace show status
                    Write-Color "$status" "Gray"
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "6" {
                try {
                    $providers = netsh trace show providers
                    Write-Color "$providers" "Gray"
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
        }
        Pause
    }
}
