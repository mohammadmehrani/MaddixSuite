Register-Tool @{
    ID          = 'OPT-005'
    Name        = 'Power Plan Tuner'
    Category    = 'OPT'
    Description = 'Set high performance / balanced / power saver'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Change Windows power plan'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Current Power Plans:" "Green"
            powercfg /list | ForEach-Object { Write-Color "    $_" "Cyan" }

            $active = powercfg /getactivescheme
            Write-Color "`n  [+] Active: $active" "Yellow"

            Write-Color "`n  [?] Select a power plan:" "Yellow"
            Write-Color "      1 - High Performance" "Cyan"
            Write-Color "      2 - Balanced (Recommended)" "Cyan"
            Write-Color "      3 - Power Saver" "Cyan"
            Write-Color "      4 - Ultimate Performance (if available)" "Cyan"
            $choice = Read-Host "  [+] Enter choice (1-4)"

            $guids = @{
                "1" = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
                "2" = "381b4222-f694-41f0-9685-ff5bb260df2e"
                "3" = "a1841308-3541-4fab-bc81-f71556f20b4a"
                "4" = "e9a42b02-d5df-448d-aa00-03f14749eb61"
            }

            if ($guids.ContainsKey($choice)) {
                $name = switch ($choice) {
                    "1" { "High Performance" }
                    "2" { "Balanced" }
                    "3" { "Power Saver" }
                    "4" { "Ultimate Performance" }
                }
                Write-Color "  [+] Setting $name..." "Yellow"
                powercfg /setactive $guids[$choice]
                Write-Color "  [+] Power plan changed to $name" "Green"

                Write-Color "`n  [*] Sub-settings for current plan:" "Yellow"
                powercfg /query | Select-String -SimpleMatch 'SUB_' | ForEach-Object { Write-Color "    $_" "Cyan" }
            } else {
                Write-Color "  [!] Invalid choice" "Red"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
