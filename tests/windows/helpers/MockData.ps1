# Mock data for MaddixSuite tests
$script:MockUsers = @(
    @{Name = "admin"; SamAccountName = "admin"; Enabled = $true; LastLogonDate = "2026-06-15"; PasswordLastSet = "2026-01-10"}
    @{Name = "user1"; SamAccountName = "user1"; Enabled = $true; LastLogonDate = "2026-06-28"; PasswordLastSet = "2026-03-20"}
    @{Name = "disabled_user"; SamAccountName = "olduser"; Enabled = $false; LastLogonDate = "2025-12-01"; PasswordLastSet = "2025-01-01"}
)

$script:MockGroups = @(
    @{Name = "Domain Admins"; SamAccountName = "Domain Admins"; GroupCategory = "Security"; GroupScope = "Global"}
    @{Name = "Domain Users"; SamAccountName = "Domain Users"; GroupCategory = "Security"; GroupScope = "Global"}
    @{Name = "Enterprise Admins"; SamAccountName = "Enterprise Admins"; GroupCategory = "Security"; GroupScope = "Universal"}
)

$script:MockServices = @(
    @{Name = "Spooler"; DisplayName = "Print Spooler"; Status = "Running"; StartType = "Automatic"}
    @{Name = "WSearch"; DisplayName = "Windows Search"; Status = "Stopped"; StartType = "Disabled"}
    @{Name = "wuauserv"; DisplayName = "Windows Update"; Status = "Running"; StartType = "Automatic"}
)

$script:MockEventLogs = @(
    @{Id = 41; Level = "Critical"; Provider = "Microsoft-Windows-Kernel-Power"; Message = "System has rebooted without cleanly shutting down first"; Time = "2026-06-30 14:30:00"}
    @{Id = 1001; Level = "Error"; Provider = "Microsoft-Windows-WER"; Message = "Windows Error Reporting: Fault bucket"; Time = "2026-06-30 14:25:00"}
    @{Id = 6008; Level = "Error"; Provider = "EventLog"; Message = "The previous system shutdown at 14:20:00 was unexpected"; Time = "2026-06-30 14:22:00"}
)
