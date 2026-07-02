# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# Tool: SYS-001 — System Information

Register-Tool @{
    ID          = 'SYS-001'
    Name        = 'System Information'
    Category    = 'SYS'
    Description = 'Display complete hardware, OS, and software information'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Displays all system details without modifications.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        $info = Get-SystemInfo
        Write-Color "`n  ═══════════════════════════════════════════" "Cyan"
        Write-Color "   SYSTEM INFORMATION" "Cyan"
        Write-Color "  ═══════════════════════════════════════════" "Cyan"
        $info.PSObject.Properties | Sort-Object Name | ForEach-Object {
            Write-Color "  $($_.Name): $($_.Value)" "White"
        }
        Write-Color "  ===========================================" "Cyan"
    }
}
