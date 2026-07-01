# SysAdminSuite Usage Guide

## Quick Start

### Option A: Run Directly from GitHub (No Download)

1. Open **PowerShell as Administrator**
2. Paste and run:
   ```powershell
   irm https://raw.githubusercontent.com/maddix/MaddixSuite/main/windows%20os/SysAdminSuite.ps1 | iex
   ```

### Option B: Download & Run

1. Download the script:
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/maddix/MaddixSuite/main/windows%20os/SysAdminSuite.ps1" -OutFile "$env:USERPROFILE\Desktop\SysAdminSuite.ps1"
   ```
2. Right-click `SysAdminSuite.ps1` → **Run with PowerShell** (as Admin)

### Option C: Using the Batch Files

- Double-click `run.cmd` (runs local script)
- Double-click `run-online.cmd` (runs from GitHub)

---

## Menu Options Explained

### 1. Create System Restore Point
Creates a Windows restore point so you can revert changes if needed.

### 2. Run Full Diagnostic
Executes SFC, DISM, CHKDSK, and analyzes Event Logs for critical errors.

### 3. Repair System Files (SFC)
Scans all protected system files and replaces corrupted versions.

### 4. Repair System Image (DISM)
Repairs the Windows system image using Windows Update.

### 5. Check Disk (CHKDSK)
Scans the system drive for file system errors and bad sectors.

### 6. Repair Boot Records
Fixes MBR (Master Boot Record), BCD (Boot Configuration Data), and rebuilds boot entries.

### 7. Reset Windows Update
Stops WU services, clears the SoftwareDistribution cache, and restarts services.

### 8-10. Driver Management
List all installed drivers, scan for updates, and remove problematic ones.

### 11. Clean System Caches
Clears temp files, prefetch, logs, DNS cache, and Windows Update cache.

### 12. Performance Optimization
Disables visual effects, Xbox services, reduces service timeout, sets High Performance power plan.

### 13. Generate Report
Creates HTML and TXT diagnostic reports on your desktop.

### 14. Run All
Executes every repair and optimization in sequence (recommended for full maintenance).

---

## Reports

After running diagnostics, reports are saved to:
```
%USERPROFILE%\Desktop\MaddixSuite_Report_YYYYMMDD_HHmmss\
├── Report.txt
└── Report.html
```

Open `Report.html` in any browser for colored, formatted results.
