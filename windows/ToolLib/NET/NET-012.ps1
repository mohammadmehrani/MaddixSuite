Register-Tool @{
    ID          = 'NET-012'
    Name        = 'Firewall Rule Manager'
    Category    = 'NET'
    Description = 'List, create, and remove Windows Firewall rules'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Modifies Windows Firewall rules — add or remove entries.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── FIREWALL RULE MANAGER ───" "Cyan"
        Write-Color "  1. List all active rules" "White"
        Write-Color "  2. List inbound rules" "White"
        Write-Color "  3. List outbound rules" "White"
        Write-Color "  4. Create new rule" "White"
        Write-Color "  5. Remove a rule" "White"
        Write-Color "  6. Enable/disable a rule" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                try {
                    $rules = Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction Stop | Sort-Object DisplayName
                    Write-Color "  Total rules: $($rules.Count)" "White"
                    $rules | Select-Object DisplayName, Direction, Action, Enabled, Profile | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "2" {
                try {
                    $rules = Get-NetFirewallRule -Direction Inbound -PolicyStore ActiveStore -ErrorAction Stop | Sort-Object DisplayName
                    Write-Color "  Total inbound rules: $($rules.Count)" "White"
                    $rules | Select-Object DisplayName, Action, Enabled, Profile | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "3" {
                try {
                    $rules = Get-NetFirewallRule -Direction Outbound -PolicyStore ActiveStore -ErrorAction Stop | Sort-Object DisplayName
                    Write-Color "  Total outbound rules: $($rules.Count)" "White"
                    $rules | Select-Object DisplayName, Action, Enabled, Profile | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "4" {
                try {
                    $name = Read-Host "  Rule name"
                    $dir = Read-Host "  Direction (Inbound/Outbound)"
                    $action = Read-Host "  Action (Allow/Block)"
                    $proto = Read-Host "  Protocol (TCP/UDP/Any) [default: Any]"
                    if ([string]::IsNullOrWhiteSpace($proto)) { $proto = "Any" }
                    $localPort = Read-Host "  Local port (leave blank for all)"
                    $remotePort = Read-Host "  Remote port (leave blank for all)"
                    $params = @{
                        DisplayName = $name
                        Direction = $dir
                        Action = $action
                    }
                    if ($proto -ne "Any") { $params.Protocol = $proto }
                    if ($localPort) { $params.LocalPort = $localPort }
                    if ($remotePort) { $params.RemotePort = $remotePort }
                    New-NetFirewallRule @params -ErrorAction Stop
                    Write-Color "  [+] Rule '$name' created" "Green"
                } catch { Write-Color "  [!] Failed to create rule: $_" "Red" }
            }
            "5" {
                try {
                    $rules = Get-NetFirewallRule -PolicyStore ActiveStore | Where-Object DisplayName -ne $null | Sort-Object DisplayName
                    $i = 1
                    $ruleList = @()
                    foreach ($r in $rules) {
                        Write-Color "  $i. $($r.DisplayName) [$($r.Direction)]" "White"
                        $ruleList += $r
                        $i++
                        if ($i -gt 50) { Write-Color "  ... (more than 50 rules)"; break }
                    }
                    $sel = Read-Host "`n  Select rule number to remove"
                    $target = $ruleList[[int]$sel - 1]
                    if ($target) {
                        Remove-NetFirewallRule -DisplayName $target.DisplayName -ErrorAction Stop
                        Write-Color "  [+] Rule '$($target.DisplayName)' removed" "Green"
                    }
                } catch { Write-Color "  [!] Failed to remove rule: $_" "Red" }
            }
            "6" {
                try {
                    $targetName = Read-Host "  Rule name to toggle"
                    $rule = Get-NetFirewallRule -DisplayName $targetName -ErrorAction Stop
                    $newState = if ($rule.Enabled -eq $true) { $false } else { $true }
                    Set-NetFirewallRule -DisplayName $targetName -Enabled ($newState ? "True" : "False") -ErrorAction Stop
                    Write-Color "  [+] Rule '$targetName' set to $(if ($newState) { 'Enabled' } else { 'Disabled' })" "Green"
                } catch { Write-Color "  [!] Rule not found or error: $_" "Red" }
            }
        }
        Pause
    }
}
