# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
<#
.SYNOPSIS
    MaddixSuite Backup & Restore Tool — Modular DB + File + Remote Backup
.DESCRIPTION
    Modules:
      1. System State (Registry, Drivers, BCD, Tasks, Network, Hosts)
      2. Database (SQL Server, MySQL, PostgreSQL)
      3. File Sync (Robocopy mirror, include/exclude patterns)
      4. Remote Upload (FTP, SFTP, Local folder)
      5. Auto-Purge (retention policy)
.NOTES
    GitHub: https://github.com/mohammadmehrani/MaddixSuite
    Website: https://iodeck.ir
#>

param([switch]$Auto)

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$Version = "2.0"
$script:BasePath = "$env:USERPROFILE\Desktop\MaddixSuite\Backups"
$script:ConfigFile = "$script:BasePath\BackupConfig.json"

function Write-Color { param([string]$Text, [string]$Color = "White") Write-Host $Text -ForegroundColor $Color }
function Confirm-Step {
    param([string]$Title, [string]$Desc)
    if ($Auto) { return $true }
    Write-Color "`n  $Title" "Yellow"; Write-Color "  $Desc" "DarkGray"
    $r = Read-Host "  Proceed? (Y/N)"
    return ($r -match '^[Yy]')
}

# ===========================================================================
# MODULE 1 — SYSTEM STATE BACKUP
# ===========================================================================
function Backup-SystemState {
    param([string]$Dest)
    if (-not (Confirm-Step "System State Backup" "Registry, Drivers, BCD, Tasks, Network, Hosts")) { return $null }

    $dir = "$Dest\SystemState"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    Write-Color "    [1] Registry..." "Gray"
    $hives = @("HKLM\Software","HKLM\System","HKLM\SAM","HKLM\Security","HKCU\Software")
    foreach ($h in $hives) { reg export $h "$dir\$($h -replace '\\','_').reg" /y 2>$null }

    Write-Color "    [2] Drivers..." "Gray"
    try { Export-WindowsDriver -Online -Destination "$dir\Drivers" -ErrorAction Stop } catch { Write-Color "    [!] Driver export: $_" "Yellow" }

    Write-Color "    [3] BCD..." "Gray"
    bcdedit /export "$dir\BCD.bak" 2>$null

    Write-Color "    [4] Task Scheduler..." "Gray"
    schtasks /query /XML /TN "*" > "$dir\Tasks.xml" 2>$null

    Write-Color "    [5] Network..." "Gray"
    netsh dump > "$dir\network.txt" 2>$null
    netsh wlan export profile folder="$dir\WiFi" key=clear 2>$null

    Write-Color "    [6] Hosts + Env..." "Gray"
    Copy-Item "$env:SystemRoot\System32\drivers\etc\hosts" "$dir\hosts.backup" -Force -ErrorAction SilentlyContinue
    Get-ChildItem Env: | Export-Clixml "$dir\EnvVars.xml" -Force -ErrorAction SilentlyContinue

    Write-Color "    [+] System State complete" "Green"
    return $dir
}

# ===========================================================================
# MODULE 2 — DATABASE BACKUP
# ===========================================================================
function Backup-Database {
    param([string]$Dest)
    if (-not (Confirm-Step "Database Backup" "SQL Server, MySQL/MariaDB, or PostgreSQL. Select which databases to back up.")) { return $null }

    $dir = "$Dest\Database"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    # SQL Server
    $sqlBackup = $false
    if (Confirm-Step "  SQL Server" "Backup all SQL Server databases? Requires SQL Server Management Objects or sqlcmd.") {
        try {
            $sqlServers = @("localhost", $env:COMPUTERNAME)
            foreach ($svr in $sqlServers) {
                $exists = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
                if ($exists -and $exists.Status -eq "Running") {
                    $dbs = Invoke-Sqlcmd -ServerInstance $svr -Query "SELECT name FROM sys.databases WHERE state=0" -ErrorAction SilentlyContinue
                    if ($dbs) {
                        New-Item -ItemType Directory -Path "$dir\SQL" -Force | Out-Null
                        foreach ($db in $dbs) {
                            $bakFile = "$dir\SQL\$($db.name)_$(Get-Date -Format 'yyyyMMdd').bak"
                            $query = "BACKUP DATABASE [$($db.name)] TO DISK='$bakFile' WITH FORMAT, COMPRESSION"
                            try { Invoke-Sqlcmd -ServerInstance $svr -Query $query -ErrorAction Stop; Write-Color "      SQL: $($db.name)" "Green" } catch { }
                        }
                        $sqlBackup = $true
                    }
                }
            }
            if (-not $sqlBackup) { Write-Color "    [!] No SQL Server instance accessible" "Yellow" }
        } catch { Write-Color "    [!] SQL Server backup error: $_" "Yellow" }
    }

    # MySQL / MariaDB
    if (Confirm-Step "  MySQL/MariaDB" "Backup MySQL databases? Requires mysqldump (via WSL or MySQL tools).") {
        $mysqlExe = if (Get-Command "mysqldump" -ErrorAction SilentlyContinue) { "mysqldump" }
                    elseif (Test-Path "$env:ProgramFiles\MySQL\MySQL Server 8.0\bin\mysqldump.exe") { "$env:ProgramFiles\MySQL\MySQL Server 8.0\bin\mysqldump.exe" }
                    else { $null }
        if ($mysqlExe) {
            Write-Color "      Setting up MySQL config..." "Gray"
            $myUser = Read-Host "      MySQL user (or empty to skip)"
            if ($myUser) {
                $myPass = Read-Host "      MySQL password (or empty for no password)"
                New-Item -ItemType Directory -Path "$dir\MySQL" -Force | Out-Null
                $mpFile = "$env:TEMP\mysql_backup.ps1"
                $cmd = "& `"$mysqlExe`" -u $myUser"
                if ($myPass) { $cmd += " -p`"$myPass`"" }
                $cmd += " --all-databases --routines --events | gzip -c > `"$dir\MySQL\full_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql.gz`""
                try { Invoke-Expression $cmd; Write-Color "      MySQL backup complete" "Green" } catch { Write-Color "    [!] MySQL error: $_" "Yellow" }
            }
        } else {
            Write-Color "    [!] mysqldump not found. Install MySQL tools or use WSL." "Yellow"
        }
    }

    # PostgreSQL
    if (Confirm-Step "  PostgreSQL" "Backup PostgreSQL databases? Requires pg_dumpall via WSL or native pg tools.") {
        $pgDump = if (Get-Command "pg_dumpall" -ErrorAction SilentlyContinue) { "pg_dumpall" }
                  elseif (Test-Path "$env:ProgramFiles\PostgreSQL\*\bin\pg_dumpall.exe") { Resolve-Path "$env:ProgramFiles\PostgreSQL\*\bin\pg_dumpall.exe" | Select-Object -First 1 }
                  else { $null }
        if ($pgDump) {
            New-Item -ItemType Directory -Path "$dir\PostgreSQL" -Force | Out-Null
            $pgUser = Read-Host "      PostgreSQL user (or empty to skip)"
            if ($pgUser) {
                try {
                    & $pgDump -U $pgUser -h localhost | gzip -c > "$dir\PostgreSQL\full_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').psql.gz"
                    Write-Color "      PostgreSQL backup complete" "Green"
                } catch { Write-Color "    [!] PostgreSQL error: $_" "Yellow" }
            }
        } else {
            Write-Color "    [!] pg_dumpall not found." "Yellow"
        }
    }

    return $dir
}

# ===========================================================================
# MODULE 3 — FILE BACKUP (Robocopy mirror)
# ===========================================================================
function Backup-Files {
    param([string]$Dest)
    if (-not (Confirm-Step "File Backup (Robocopy Mirror)" "Mirror selected directories using robocopy. Supports include/exclude patterns.")) { return $null }

    $dirsFile = "$dest\file_include.txt"
    $include = @()
    Write-Color "    Enter paths to backup (one per line, empty line to finish):" "Gray"
    while ($true) {
        $p = Read-Host "    Path"
        if (-not $p) { break }
        if (Test-Path $p) {
            $include += $p
            Write-Color "      Added: $p" "Green"
        } else { Write-Color "      Not found: $p" "Yellow" }
    }

    if ($include.Count -eq 0) { Write-Color "    No paths selected." "Yellow"; return $null }

    $fileDir = "$Dest\Files"
    New-Item -ItemType Directory -Path $fileDir -Force | Out-Null
    $include | Out-File "$fileDir\includes.txt" -Encoding UTF8

    foreach ($src in $include) {
        $name = $src -replace '[:\\/]', '_'
        $logFile = "$fileDir\robocopy_$name.log"
        Write-Color "    Mirroring $src..." "Gray"
        try {
            robocopy $src "$fileDir\$name" /MIR /Z /R:2 /W:3 /NP /NDL /LOG:$logFile
            Write-Color "      Done: $name" "Green"
        } catch { Write-Color "    [!] Robocopy error: $_" "Yellow" }
    }

    Write-Color "    [+] File backup complete" "Green"
    return $fileDir
}

# ===========================================================================
# MODULE 4 — COMPRESSION & ENCRYPTION
# ===========================================================================
function Compress-Backup {
    param([string]$SourceDir)
    if (-not (Confirm-Step "Compress Backup" "Archive all backup data into a single compressed file. Optionally encrypt with password.")) { return $SourceDir }

    $archiveDir = "$script:CurrentBackup\Archives"
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    $archiveFile = "$archiveDir\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').tar.gz"

    Write-Color "    Compressing..." "Gray"
    try {
        if (Get-Command "tar.exe" -ErrorAction SilentlyContinue) {
            tar -czf $archiveFile -C $script:CurrentBackup (Get-ChildItem $script:CurrentBackup -Directory | Select-Object -ExpandProperty Name)
            Write-Color "    [+] Compressed to: $archiveFile" "Green"

            $encPass = Read-Host "    Encrypt with password? (empty to skip)"
            if ($encPass) {
                $encFile = "$archiveDir\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').7z"
                if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
                    7z a -p"$encPass" -mhe "$encFile" $archiveFile -bd
                    Write-Color "    [+] Encrypted: $encFile" "Green"
                    Remove-Item $archiveFile -Force
                } else {
                    Write-Color "    [!] 7z not found for encryption" "Yellow"
                }
            }
        }
    } catch { Write-Color "    [!] Compression error: $_" "Yellow" }

    return $archiveDir
}

# ===========================================================================
# MODULE 5 — REMOTE UPLOAD
# ===========================================================================
function Upload-Remote {
    param([string]$SourceDir)
    if (-not (Confirm-Step "Remote Upload" "Upload backup to FTP, SFTP, or copy to a network/local folder.")) { return }

    Write-Color "    Upload Method:" "Gray"
    Write-Color "      [1] Local/Network folder copy" "Gray"
    Write-Color "      [2] FTP upload" "Gray"
    Write-Color "      [3] Skip" "Gray"
    $um = Read-Host "    Select (1-3)"
    if ($um -eq "3") { return }

    if ($um -eq "1") {
        $target = Read-Host "    Destination folder path"
        if ($target) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            try {
                robocopy $SourceDir $target /MIR /Z /R:2 /W:3 /NP /NDL
                Write-Color "    [+] Copied to $target" "Green"
                # Save to config
                $config = @{Destination=$target; Method="Local"} | ConvertTo-Json
                $config | Out-File "$script:CurrentBackup\upload_config.json" -Encoding UTF8
            } catch { Write-Color "    [!] Copy error: $_" "Yellow" }
        }
    }
    elseif ($um -eq "2") {
        $ftpServer = Read-Host "    FTP server (e.g., ftp.example.com)"
        $ftpUser = Read-Host "    FTP username"
        $ftpPass = Read-Host "    FTP password"
        $ftpPath = Read-Host "    Remote path (e.g., /backups)"
        if ($ftpServer -and $ftpUser) {
            $archiveFiles = Get-ChildItem $SourceDir -Filter "*.gz" -ErrorAction SilentlyContinue
            if (-not $archiveFiles) { $archiveFiles = Get-ChildItem $SourceDir -File -ErrorAction SilentlyContinue }
            $wc = New-Object System.Net.WebClient
            $wc.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)
            foreach ($f in $archiveFiles) {
                try {
                    $uri = "ftp://$ftpServer$ftpPath/$($f.Name)"
                    $wc.UploadFile($uri, $f.FullName)
                    Write-Color "    [+] Uploaded: $($f.Name)" "Green"
                } catch { Write-Color "    [!] Upload failed for $($f.Name): $_" "Yellow" }
            }
            $wc.Dispose()
        }
    }
}

# ===========================================================================
# MODULE 6 — RETENTION & PURGE
# ===========================================================================
function Purge-OldBackups {
    if (-not (Confirm-Step "Auto-Purge Old Backups" "Delete backups older than N days. Default: 30.")) { return }

    $days = Read-Host "    Keep backups newer than how many days? (30)"
    if (-not $days) { $days = 30 }
    $cutoff = (Get-Date).AddDays(-[int]$days)
    $old = Get-ChildItem $script:BasePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.CreationTime -lt $cutoff -and $_.Name -ne $script:CurrentBackup.Split('\')[-1] }

    if ($old) {
        Write-Color "    Found $($old.Count) old backup(s) to purge:" "Yellow"
        foreach ($o in $old) {
            Write-Color "      $($o.Name) ($($o.CreationTime))" "DarkYellow"
            Remove-Item -Path $o.FullName -Recurse -Force -ErrorAction SilentlyContinue
            Write-Color "      Deleted." "Green"
        }
    } else { Write-Color "    No old backups to purge." "Green" }
}

# ===========================================================================
# FULL BACKUP
# ===========================================================================
function Do-Backup {
    $script:CurrentBackup = "$script:BasePath\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $script:CurrentBackup -Force | Out-Null

    Write-Color "╔════════════════════════════════════════════╗" "Cyan"
    Write-Color "║     Running All Backup Modules              ║" "Cyan"
    Write-Color "╚════════════════════════════════════════════╝" "Cyan"

    Backup-SystemState -Dest $script:CurrentBackup
    Backup-Database -Dest $script:CurrentBackup
    Backup-Files -Dest $script:CurrentBackup
    Compress-Backup -SourceDir $script:CurrentBackup
    Upload-Remote -SourceDir "$script:CurrentBackup\Archives"
    Purge-OldBackups

    # Summary
    $size = [math]::Round(((Get-ChildItem $script:CurrentBackup -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB), 2)
    Write-Color "`n========================================" "Cyan"
    Write-Color "  BACKUP COMPLETED" "Green"
    Write-Color "  Location: $script:CurrentBackup" "Yellow"
    Write-Color "  Size: $size MB" "Yellow"
    Write-Color "========================================" "Cyan"

    # Checksums
    Get-ChildItem $script:CurrentBackup -Recurse -File | ForEach-Object {
        "$((Get-FileHash $_.FullName -Algorithm MD5).Hash)  $($_.Name)" | Out-File "$script:CurrentBackup\checksums.md5" -Append
    }

    Pause
}

# ===========================================================================
# RESTORE
# ===========================================================================
function List-Backups {
    $backups = Get-ChildItem $script:BasePath -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $backups) { Write-Color "  No backups found." "Yellow"; return $null }
    $i = 1
    foreach ($b in $backups) {
        $size = "{0:N2}" -f ((Get-ChildItem $b.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Color "  $i. $($b.Name)  ($size MB)" "White"
        $i++
    }
    return $backups
}

function Do-Restore {
    Write-Color "╔════════════════════════════════════════════╗" "Cyan"
    Write-Color "║          RESTORE BACKUP                     ║" "Cyan"
    Write-Color "╚════════════════════════════════════════════╝" "Cyan"
    $backups = List-Backups
    if (-not $backups) { Pause; return }

    $sel = Read-Host "`n  Select backup number"
    $idx = [int]$sel - 1
    if ($idx -lt 0 -or $idx -ge $backups.Count) { Write-Color "  Invalid." "Red"; Pause; return }
    $src = $backups[$idx].FullName

    Write-Color "  What to restore?" "Cyan"
    Write-Color "    1. System State (Registry, Drivers, BCD, etc.)" "White"
    Write-Color "    2. Files only" "White"
    Write-Color "    3. Everything" "White"
    $r = Read-Host "  Select (1-3)"

    if ($r -in @("1","3")) {
        $regDir = "$src\SystemState"
        if (Test-Path $regDir) {
            if (Confirm-Step "  Restore Registry" "This can destabilize your system. Type YES to confirm.") {
                Get-ChildItem $regDir -Filter "*.reg" | ForEach-Object { reg import $_.FullName 2>$null; Write-Color "    $($_.Name)" "Gray" }
            }
            if (Confirm-Step "  Restore Drivers" "Reinstall drivers from backup.") {
                $drvDir = "$regDir\Drivers"
                if (Test-Path $drvDir) { Get-ChildItem $drvDir -Filter "*.inf" -Recurse | ForEach-Object { Add-WindowsDriver -Online -Driver $_.FullName -ErrorAction SilentlyContinue } }
            }
            $bcdFile = "$regDir\BCD.bak"
            if (Test-Path $bcdFile -and (Confirm-Step "  Restore BCD" "Restore boot configuration.")) { bcdedit /import $bcdFile 2>$null }
            if (Test-Path "$regDir\hosts.backup") { Copy-Item "$regDir\hosts.backup" "$env:SystemRoot\System32\drivers\etc\hosts" -Force }
        }
    }

    if ($r -in @("2","3")) {
        $fileDir = "$src\Files"
        if (Test-Path $fileDir) {
            $includes = Get-Content "$fileDir\includes.txt" -ErrorAction SilentlyContinue
            foreach ($inc in $includes) {
                $name = $inc -replace '[:\\/]', '_'
                $srcPath = "$fileDir\$name"
                if (Test-Path $srcPath) {
                    if (Confirm-Step "  Restore $inc" "Restore files to original location?") {
                        robocopy $srcPath $inc /MIR /Z /R:2 /W:3 /NP /NDL
                        Write-Color "    Restored: $inc" "Green"
                    }
                }
            }
        }
    }

    Write-Color "  [+] Restore complete" "Green"
    Pause
}

# ===========================================================================
# CONFIG
# ===========================================================================
function Edit-Config {
    Write-Color "╔════════════════════════════════════════════╗" "Cyan"
    Write-Color "║          BACKUP CONFIGURATION               ║" "Cyan"
    Write-Color "╚════════════════════════════════════════════╝" "Cyan"

    $config = if (Test-Path $script:ConfigFile) { Get-Content $script:ConfigFile -Raw | ConvertFrom-Json } else { $null }

    Write-Color "  Current settings:" "Gray"
    Write-Color "    Base path: $script:BasePath" "Gray"
    Write-Color "    Retention: $($config.RetentionDays) days" "Gray"
    if ($config.Remote) { Write-Color "    Remote: $($config.Remote.Method) → $($config.Remote.Destination)" "Gray" }

    $newDays = Read-Host "`n  Retention days ($($config.RetentionDays))"
    if (-not $newDays) { $newDays = $config.RetentionDays ?? 30 }

    $conf = @{
        BasePath = $script:BasePath
        RetentionDays = [int]$newDays
        Remote = $config.Remote
        Includes = $config.Includes
        Databases = $config.Databases
    } | ConvertTo-Json
    $conf | Out-File $script:ConfigFile -Encoding UTF8
    Write-Color "  [+] Config saved" "Green"
    Pause
}

# ===========================================================================
# MENU
# ===========================================================================
function Show-Menu {
    Clear-Host
    Write-Color "╔═══════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║  MaddixSuite — Backup & Restore v$Version                    ║" "Cyan"
    Write-Color "║  GitHub: https://github.com/mohammadmehrani/MaddixSuite   ║" "DarkGray"
    Write-Color "║  Website: https://iodeck.ir                              ║" "DarkGray"
    Write-Color "╚═══════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color ""
    Write-Color "  1. Full Backup (System + DB + Files + Remote)" "White"
    Write-Color "  2. Restore from Backup" "White"
    Write-Color "  3. List Backups" "White"
    Write-Color "  4. Configuration" "White"
    Write-Color "  0. Exit" "White"
    Write-Color ""
    $c = Read-Host "  Select option"
    switch ($c) {
        "1" { Do-Backup }
        "2" { Do-Restore }
        "3" { Clear-Host; List-Backups; Pause }
        "4" { Edit-Config }
        "0" { exit }
    }
}

function Invoke-BackupRestore {
    while ($true) { Show-Menu }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-BackupRestore
}
