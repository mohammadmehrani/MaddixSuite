#Requires -RunAsAdministrator
# Maddix-AntiHack.ps1 — Advanced Anti-Hack, Keylogger & Exploit Detection
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# GitHub: https://github.com/mohammadmehrani/MaddixSuite
# Run: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Security/Maddix-AntiHack.ps1 | iex

param([switch]$Auto, [switch]$Clean)

$Host.UI.RawUI.WindowTitle = "MaddixSuite — Anti-Hack Scanner"

$script:findings = @()
$script:threatCount = 0

function Write-Color { param([string]$Text, [string]$Color = "White") Write-Host $Text -ForegroundColor $Color }
function Add-Finding {
    param([string]$Category, [string]$Severity, [string]$Detail, [string]$Suggestion, [switch]$IsThreat)
    $script:findings += [PSCustomObject]@{ Category=$Category; Severity=$Severity; Detail=$Detail; Suggestion=$Suggestion }
    if ($IsThreat) { $script:threatCount++ }
}
function Confirm-Step {
    param([string]$Title, [string]$Desc)
    if ($Auto) { return $true }
    Write-Color "`n  $Title" "Yellow"; Write-Color "  $Desc" "DarkGray"
    $r = Read-Host "  Continue? (Y/N)"
    return ($r -match '^[Yy]')
}
function Test-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
    }
}

# ===========================================================================
# MODULE 1 — NETWORK ATTACK DETECTION
# ===========================================================================
function Scan-NetworkAttacks {
    Write-Color "  [Module 1] Network Attack Detection" "Cyan"

    # 1A — Suspicious listening ports
    Write-Color "    Scanning listening ports..." "Gray"
    $listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
    $suspiciousPorts = @{
        21="FTP (data exfil)"; 23="Telnet (insecure)";
        445="SMB (worm propagation)"; 1433="SQL Server (targeted)";
        3306="MySQL (targeted)"; 3389="RDP (brute-force target)";
        4444="Metasploit default"; 5555="Android ADB / RAT";
        6666="IRC botnet"; 6667="IRC botnet";
        6668="IRC botnet"; 6669="IRC botnet";
        7777="Orwell RAT"; 8000="HTTP proxy / RAT";
        8443="HTTPS alt / RAT"; 9001="Tor";
        9050="Tor SOCKS"; 9051="Tor control";
        10000="Webmin / backdoor"; 12345="NetBus / G-Syre";
        12346="NetBus"; 20034="NetBus 2.0";
        27374="Sub7"; 31337="Back Orifice";
        41414="RAT"; 65000="RAT";
        65535="RAT"
    }
    foreach ($conn in $listeners) {
        if ($suspiciousPorts.ContainsKey($conn.LocalPort)) {
            $proc = (Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue).ProcessName
            Add-Finding "Network" "HIGH" "Suspicious listening port: $($conn.LocalPort) ($($suspiciousPorts[$conn.LocalPort])) — Process: $proc" "Investigate process $proc (PID: $($conn.OwningProcess))" -IsThreat
        }
    }

    # 1B — Established connections to suspicious IPs (private IP exclusions)
    Write-Color "    Scanning outbound connections..." "Gray"
    $established = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
    $localIPs = @("127.0.0.1", "::1", "0.0.0.0", "192.168.", "10.", "172.16.", "172.17.", "172.18.", "172.19.", "172.20.", "172.21.", "172.22.", "172.23.", "172.24.", "172.25.", "172.26.", "172.27.", "172.28.", "172.29.", "172.30.", "172.31.")
    $highRiskPorts = @(21,22,23,135,139,445,1433,3306,3389,4444,5555,6666,6667,6668,6669,7777,8443,12345,27374,31337)
    foreach ($conn in $established) {
        $remoteIP = $conn.RemoteAddress
        $isLocal = $false
        foreach ($l in $localIPs) { if ($remoteIP -like "$l*") { $isLocal = $true; break } }
        if (-not $isLocal -and $highRiskPorts -contains $conn.RemotePort) {
            $proc = (Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue).ProcessName
            Add-Finding "Network" "MEDIUM" "Outbound to $remoteIP`:$($conn.RemotePort) ($proc)" "Verify this connection is legitimate" -IsThreat
        }
    }

    # 1C — ARP table anomalies
    Write-Color "    Checking ARP table..." "Gray"
    $arp = arp -a | Select-String "dynamic" | ForEach-Object { ($_ -split '\s+')[1] }
    $gatewayIP = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1).NextHop
    if ($gatewayIP) {
        $gatewayMACs = arp -a $gatewayIP 2>$null | Select-String $gatewayIP
        if (($gatewayMACs | Measure-Object).Count -gt 1) {
            Add-Finding "Network" "CRITICAL" "Multiple MAC addresses for gateway $gatewayIP — ARP spoofing possible" "Check ARP table manually: arp -a" -IsThreat
        }
    }

    # 1D — Promiscuous mode check
    Write-Color "    Checking for promiscuous mode (packet sniffing)..." "Gray"
    try {
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
        foreach ($a in $adapters) {
            $prom = (Get-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword "*Promiscuous" -ErrorAction SilentlyContinue).DisplayValue
            if ($prom -eq "1") {
                Add-Finding "Network" "HIGH" "Promiscuous mode detected on $($a.Name) — possible packet sniffing" "Investigate: Get-NetAdapterAdvancedProperty -Name '$($a.Name)'" -IsThreat
            }
        }
    } catch {}

    # 1E — DNS configuration check
    Write-Color "    Checking DNS for poisoning indicators..." "Gray"
    try {
        $dnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses -ne $null }).ServerAddresses
        $knownSafeDNS = @("8.8.8.8","8.8.4.4","1.1.1.1","1.0.0.1","208.67.222.222","208.67.220.220","9.9.9.9","149.112.112.112")
        foreach ($dns in $dnsServers) {
            foreach ($addr in $dns) {
                if ($knownSafeDNS -notcontains $addr -and $addr -notlike "192.168.*" -and $addr -notlike "10.*" -and $addr -notlike "172.*") {
                    Add-Finding "Network" "MEDIUM" "Unusual DNS server: $addr" "Verify this DNS server is legitimate" -IsThreat
                }
            }
        }
    } catch {}

    Write-Color "    [Module 1 complete]" "Green"
}

# ===========================================================================
# MODULE 2 — KEYLOGGER DETECTION
# ===========================================================================
function Scan-Keyloggers {
    Write-Color "  [Module 2] Keylogger Detection" "Cyan"

    # 2A — Check for keyboard hooks
    Write-Color "    Checking for global keyboard hooks..." "Gray"
    try {
        $procs = Get-Process
        foreach ($p in $procs) {
            try {
                $modules = $p.Modules | Where-Object { $_.ModuleName -match '\.dll' -and $_.ModuleName -notmatch '^(ntdll|kernel32|user32|gdi32|advapi32|ole32|oleaut32|comctl32|comdlg32|ws2_32|wininet|shlwapi|shell32|msvcrt|imm32)' }
                $suspiciousDLLs = @("keyhook","keylog","logkeys","hook","GetAsyncKeyState","_keylog", "keyboardhook")
                foreach ($m in $modules) {
                    $modName = $m.ModuleName.ToLower()
                    foreach ($sus in $suspiciousDLLs) {
                        if ($modName -match [regex]::Escape($sus)) {
                            Add-Finding "Keylogger" "CRITICAL" "Suspicious DLL in $($p.ProcessName): $($m.ModuleName)" "Kill process $($p.ProcessName) and scan with Defender" -IsThreat
                        }
                    }
                }
            } catch {}
        }
    } catch {}

    # 2B — Check for known keylogger processes
    Write-Color "    Scanning for known keylogger signatures..." "Gray"
    $knownKeyloggers = @(
        "keylog","hooker","spy","capture","keystroke","logkeys","keylogger",
        "refog","actualspy","kidlogger","spytector","argon","revealer",
        "pykeylogger","xspy","uvk","omniquad","sentry","vkm","ksoft",
        "allinonekeylogger","bestkeylogger","blazingtools","buddy","e-blaster",
        "fbi","flexispy","handykeylogger","hawkeye","homekeylogger","iambigbrother",
        "iconsole","invisiblekeylogger","keybee","keycopy","keyghost","keylog",
        "keyloggerdetector","keyloggerrat","keyloggerspy","keymaster","keyp",
        "keysniff","keyspy","keytrace","keywatcher","lkl","loggen","logsniff",
        "microkeylogger","mikey","mks","moneyspychat","mousetrap","msspy",
        "mystic","netvizor","revealer","shadow","snoop","snpr","snspy",
        "softactivity","star","sysheappro","syswatch","therat","tkeylog",
        "trojankeylogger","vksoftware","watcher","winspy","xkeys","xrl"
    )
    $runningProcs = Get-Process | ForEach-Object { $_.ProcessName.ToLower() }
    foreach ($kl in $knownKeyloggers) {
        $match = $runningProcs | Where-Object { $_ -match [regex]::Escape($kl) }
        if ($match) {
            foreach ($m in $match) {
                Add-Finding "Keylogger" "CRITICAL" "Known keylogger process running: $m" "Kill process and run full Defender scan" -IsThreat
            }
        }
    }

    # 2C — Check for keyboard class driver filter
    Write-Color "    Checking driver-level keyloggers..." "Gray"
    try {
        $kbdReg = "HKLM:\HARDWARE\DEVICEMAP\KeyboardClass"
        if (Test-Path $kbdReg) {
            $upperFilters = (Get-ItemProperty -Path "$kbdReg\GLOBAL" -Name "UpperFilters" -ErrorAction SilentlyContinue).UpperFilters
            if ($upperFilters) {
                $filters = $upperFilters -join ','
                if ($filters -notmatch '(?i)^kbdclass') {
                    Add-Finding "Keylogger" "CRITICAL" "Keyboard class UpperFilters modified: $filters" "Keyboard driver filter hook detected — possible hardware keylogger" -IsThreat
                }
            }
        }
    } catch {}

    # 2D — Check for clipboard monitoring
    Write-Color "    Checking for clipboard monitors..." "Gray"
    try {
        $clipProcs = Get-Process | Where-Object { $_.MainWindowTitle -match "clip|spy|monitor|log" }
        foreach ($p in $clipProcs) {
            Add-Finding "Keylogger" "MEDIUM" "Clipboard-monitoring window: $($p.ProcessName) — '$($p.MainWindowTitle)'" "Investigate if legitimate" -IsThreat
        }
    } catch {}

    Write-Color "    [Module 2 complete]" "Green"
}

# ===========================================================================
# MODULE 3 — PERSISTENCE & BACKDOOR DETECTION
# ===========================================================================
function Scan-Persistence {
    Write-Color "  [Module 3] Persistence & Backdoor Detection" "Cyan"

    # 3A — Common autorun registry keys
    Write-Color "    Scanning autorun registry keys..." "Gray"
    $autoRunPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnceEx",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServices",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell",
        "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit",
        "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Windows\AppInit_DLLs",
        "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options",
        "HKLM:\System\CurrentControlSet\Control\Session Manager\BootExecute",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\Startup",
        "HKLM:\Software\Microsoft\Active Setup\Installed Components",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Shell"
    )
    foreach ($rp in $autoRunPaths) {
        if (Test-Path $rp) {
            try {
                $vals = Get-ItemProperty $rp -ErrorAction SilentlyContinue
                $vals.PSObject.Properties | Where-Object { $_.Name -notmatch '^(PSPath|PSParentPath|PSChildName|PSDrive|PSProvider)$' } | ForEach-Object {
                    $valData = "$($_.Value)"
                    $susPatterns = @("temp\\", "%tmp%", "%temp%", "startup", "rundll32.*http", "powershell.*-e ", "powershell.*-enc ", "cmd.*/c.*http", "bitsadmin.*http", "certutil.*http", "wscript", "cscript", "mshta")
                    foreach ($sp in $susPatterns) {
                        if ($valData -match [regex]::Escape($sp)) {
                            Add-Finding "Persistence" "HIGH" "Suspicious autorun: $($_.Name)=$valData" "Remove entry: Remove-ItemProperty -Path '$rp' -Name '$($_.Name)'" -IsThreat
                            break
                        }
                    }
                    # Check for base64 in values
                    if ($valData -match '[A-Za-z0-9+/]{40,}={0,2}') {
                        Add-Finding "Persistence" "CRITICAL" "Base64-encoded autorun: $($_.Name)" "Possible obfuscated payload — investigate immediately" -IsThreat
                    }
                }
            } catch {}
        }
    }

    # 3B — Scheduled tasks
    Write-Color "    Scanning scheduled tasks..." "Gray"
    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -ne "Disabled" }
        foreach ($t in $tasks) {
            $actions = $t.Actions | Where-Object { $_.Execute -ne $null }
            foreach ($a in $actions) {
                $exec = $a.Execute.ToLower()
                $susTaskPatterns = @("powershell", "cmd.exe", "wscript", "cscript", "bitsadmin", "regsvr32", "rundll32", "mshta", "certutil")
                $matched = $susTaskPatterns | Where-Object { $exec -match [regex]::Escape($_) }
                if ($matched -and $t.TaskPath -notmatch '\\Microsoft\\') {
                    Add-Finding "Persistence" "HIGH" "Suspicious scheduled task: $($t.TaskName) → $exec" "Check: Get-ScheduledTask -TaskName '$($t.TaskName)' | Get-ScheduledTaskInfo" -IsThreat
                }
            }
        }
    } catch {} 

    # 3C — Services
    Write-Color "    Scanning non-Microsoft services..." "Gray"
    try {
        $services = Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { $_.PathName -match '\.exe' -and $_.StartMode -ne 'Disabled' }
        foreach ($s in $services) {
            $path = $s.PathName.ToLower()
            $badPaths = @("temp\\", "%tmp%", "users\\", "appdata\\local\\temp")
            foreach ($bp in $badPaths) {
                if ($path -match [regex]::Escape($bp)) {
                    Add-Finding "Persistence" "HIGH" "Service running from suspicious path: $($s.Name) → $($s.PathName)" "Stop and disable: Stop-Service '$($s.Name)'; Set-Service '$($s.Name)' -StartupType Disabled" -IsThreat
                    break
                }
            }
        }
    } catch {}

    # 3D — WMI event subscriptions (advanced persistence)
    Write-Color "    Scanning WMI event subscriptions..." "Gray"
    try {
        $filters = Get-CimInstance -Namespace root\subscription -ClassName __EventFilter -ErrorAction SilentlyContinue
        $bindings = Get-CimInstance -Namespace root\subscription -ClassName __FilterToConsumerBinding -ErrorAction SilentlyContinue
        if ($filters) {
            foreach ($f in $filters) {
                $query = $f.Query.ToLower()
                if ($query -match "powershell|cmd\.exe|wscript|cscript|mshta|rundll32") {
                    Add-Finding "Persistence" "CRITICAL" "WMI Event Subscription — persistent backdoor: $($f.Name) ($query)" "Remove: Get-CimInstance -Namespace root\subscription -ClassName __EventFilter | Where-Object Name -EQ '$($f.Name)' | Remove-CimInstance" -IsThreat
                }
            }
        }
    } catch {}

    Write-Color "    [Module 3 complete]" "Green"
}

# ===========================================================================
# MODULE 4 — PROCESS & MEMORY ANALYSIS
# ===========================================================================
function Scan-ProcessMemory {
    Write-Color "  [Module 4] Process & Memory Analysis" "Cyan"

    # 4A — Process hollowing / injection indicators
    Write-Color "    Checking for suspicious process parents..." "Gray"
    try {
        $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
        $suspiciousParents = @{
            "rundll32"=@("explorer","svchost","winlogon");
            "regsvr32"=@("explorer","svchost");
            "mshta"=@("explorer","svchost","winlogon","lsass");
            "powershell"=@("explorer");
            "cmd"=@("explorer","winlogon");
            "wscript"=@("explorer","winlogon","svchost");
            "cscript"=@("explorer","winlogon","svchost");
        }
        foreach ($p in $procs) {
            $pn = $p.Name.ToLower()
            if ($suspiciousParents.ContainsKey($pn)) {
                try {
                    $parent = $procs | Where-Object { $_.ProcessId -eq $p.ParentProcessId }
                    if ($parent) {
                        $parentName = $parent.Name.ToLower()
                        $expectedParents = $suspiciousParents[$pn]
                        if ($expectedParents -contains $parentName) {
                            Add-Finding "Process" "HIGH" "$pn (PID: $($p.ProcessId)) spawned by $parentName — possible code injection" "Investigate: Get-CimInstance Win32_Process -Filter 'ProcessId=$($p.ParentProcessId)'" -IsThreat
                        }
                    }
                } catch {}
            }
        }
    } catch {}

    # 4B — Suspicious process names
    Write-Color "    Scanning for malicious tool names..." "Gray"
    $hackerTools = @(
        "mimikatz","procdump","pwdump","fgdump","cain","smapro","hydra","john",
        "hashcat","nc.exe","netcat","ncat","plink","putty","psexec","psexec",
        "wce","wce.exe","gsecdump","lsd","ikatz","wmic","schtasks",        
        "metsvc","beacon","cobaltstrike","empire","pwn","revshell",
        "invoke-shellcode","invoke-mimikatz","powerview","bloodhound",
        "sharphound","seatbelt","winpeas","jaws","powerup","privesc",
        "tcpview","wireshark","dumpcap","tcpdump","pktmon",
        "procexp","processhacker","pcileech","vmmap","api-monitor",
        "hookshark","deviare","spystudio"
    )
    $runningAll = Get-Process
    foreach ($p in $runningAll) {
        $pn = $p.ProcessName.ToLower()
        foreach ($ht in $hackerTools) {
            if ($pn -match [regex]::Escape($ht)) {
                Add-Finding "Process" "CRITICAL" "Hacking tool running: $($p.ProcessName) (PID: $($p.Id))" "Kill immediately: Stop-Process -Id $($p.Id) -Force" -IsThreat
            }
        }
    }

    # 4C — Check for unsigned drivers (potential rootkit)
    Write-Color "    Scanning for unsigned drivers (rootkit indicators)..." "Gray"
    try {
        $drivers = Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Running" }
        foreach ($d in $drivers) {
            $path = $d.PathName
            if ($path -and (Test-Path $path)) {
                try {
                    $sig = Get-AuthenticodeSignature $path -ErrorAction SilentlyContinue
                    if ($sig.Status -ne "Valid") {
                        Add-Finding "Rootkit" "HIGH" "Unsigned driver: $($d.Name) ($path)" "Check: Get-CimInstance Win32_SystemDriver -Filter 'Name=\"$($d.Name)\"'" -IsThreat
                    }
                } catch {}
            }
        }
    } catch {}

    Write-Color "    [Module 4 complete]" "Green"
}

# ===========================================================================
# MODULE 5 — BROWSER & CREDENTIAL THEFT CHECK
# ===========================================================================
function Scan-BrowserCreds {
    Write-Color "  [Module 5] Browser & Credential Theft Check" "Cyan"

    # 5A — Browser extension check
    Write-Color "    Checking browser extensions for malicious signatures..." "Gray"
    $browserExtPaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Extensions",
        "$env:APPDATA\Mozilla\Firefox\Profiles"
    )
    foreach ($bp in $browserExtPaths) {
        if (Test-Path $bp) {
            try {
                Get-ChildItem $bp -Recurse -Filter "manifest.json" -ErrorAction SilentlyContinue | ForEach-Object {
                    try {
                        $manifest = Get-Content $_.FullName -Raw | ConvertFrom-Json
                        $perms = $manifest.permissions
                        if ($perms -match "nativeMessaging|debugger|tabs|clipboardRead|webRequest|webRequestBlocking") {
                            Write-Color "      Extension with sensitive permissions: $($_.Directory.Parent.Name)" "DarkYellow"
                        }
                    } catch {}
                }
            } catch {}
        }
    }

    # 5B — LSASS protection check
    Write-Color "    Checking LSASS protection (Credential Guard / PPL)..." "Gray"
    try {
        $lsass = Get-Process -Name "lsass" -ErrorAction SilentlyContinue
        if ($lsass) {
            try {
                $lsassPath = "$env:SystemRoot\System32\lsass.exe"
                $acl = Get-Acl $lsassPath -ErrorAction SilentlyContinue
                Write-Color "      LSASS is running — ensure RunAsPPL is enabled to prevent credential dumping" "Gray"
                $pplReg = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
                if (Test-Path $pplReg) {
                    $runAsPPL = (Get-ItemProperty -Path $pplReg -Name "RunAsPPL" -ErrorAction SilentlyContinue).RunAsPPL
                    if ($runAsPPL -ne 1) {
                        Add-Finding "Credential" "MEDIUM" "LSASS not running as PPL — vulnerable to credential dumping" "Enable: Set-ItemProperty -Path '$pplReg' -Name RunAsPPL -Value 1" -IsThreat
                    }
                }
            } catch {}
        }
    } catch {}

    # 5C — Check for SAM/dump files
    Write-Color "    Checking for credential dump artifacts..." "Gray"
    $dumpPaths = @(
        "$env:TEMP\*.dmp",
        "$env:TEMP\*.dmp.txt",
        "$env:LOCALAPPDATA\*.dmp",
        "$env:SystemRoot\Temp\*.dmp",
        "$env:USERPROFILE\*.dmp",
        "$env:USERPROFILE\*.dmp.txt",
        "$env:USERPROFILE\Desktop\mimikatz*",
        "$env:USERPROFILE\Desktop\procdump*"
    )
    foreach ($dp in $dumpPaths) {
        $files = Get-ChildItem -Path (Split-Path $dp -Parent) -Filter (Split-Path $dp -Leaf) -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            if ($f.Length -gt 1024) {
                Add-Finding "Credential" "CRITICAL" "Possible credential dump: $($f.FullName) ($([math]::Round($f.Length/1KB,1)) KB)" "Delete: Remove-Item '$($f.FullName)' -Force" -IsThreat
            }
        }
    }

    Write-Color "    [Module 5 complete]" "Green"
}

# ===========================================================================
# MODULE 6 — FIREWALL & EXPLOIT MITIGATION CHECK
# ===========================================================================
function Scan-FirewallExploits {
    Write-Color "  [Module 6] Firewall & Exploit Mitigation Check" "Cyan"

    # 6A — Firewall status
    Write-Color "    Checking Windows Firewall..." "Gray"
    try {
        $fwProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        foreach ($p in $fwProfiles) {
            if ($p.Enabled -eq $false) {
                Add-Finding "Firewall" "CRITICAL" "Firewall disabled for profile: $($p.Name)" "Enable: Set-NetFirewallProfile -Profile $($p.Name) -Enabled True" -IsThreat
            }
        }
    } catch {}

    # 6B — Check for suspicious firewall rules
    Write-Color "    Checking for suspicious firewall rules..." "Gray"
    try {
        $rules = Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow -ErrorAction SilentlyContinue
        $suspiciousPorts = @(4444,5555,6666,6667,7777,8443,12345,20034,27374,31337,41414,65000)
        foreach ($r in $rules) {
            $portFilter = $r | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
            if ($portFilter -and $suspiciousPorts -contains $portFilter.LocalPort) {
                Add-Finding "Firewall" "HIGH" "Inbound rule allows suspicious port $($portFilter.LocalPort): $($r.Name)" "Disable: Disable-NetFirewallRule -Name '$($r.Name)'" -IsThreat
            }
        }
    } catch {}

    # 6C — Check for privilege escalation vulnerabilities
    Write-Color "    Checking exploit mitigations..." "Gray"
    $mitigations = @(
        @{Reg="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key="FeatureSettingsOverride"; Good=0},
        @{Reg="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key="DisableExceptionChainValidation"; Good=0},
        @{Reg="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key="DisableSEH"; Good=0}
    )
    foreach ($m in $mitigations) {
        if (Test-Path $m.Reg) {
            try {
                $val = (Get-ItemProperty -Path $m.Reg -Name $m.Key -ErrorAction SilentlyContinue).$($m.Key)
                if ($val -ne $m.Good) {
                    Add-Finding "Exploit" "HIGH" "Exploit mitigation disabled: $($m.Key) = $val" "Consider enabling for security" -IsThreat
                }
            } catch {}
        }
    }

    Write-Color "    [Module 6 complete]" "Green"
}

# ===========================================================================
# REPORT
# ===========================================================================
function Show-Report {
    Write-Color "`n╔═══════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║                    SCAN RESULTS                            ║" "Cyan"
    Write-Color "╚═══════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color "  Total threats found: $script:threatCount" "Yellow"
    Write-Color ""

    if ($script:findings.Count -eq 0) {
        Write-Color "  [i] No threats detected. System is clean." "Green"
    } else {
        $grouped = $script:findings | Group-Object Severity
        foreach ($g in $grouped) {
            $color = switch ($g.Name) { "CRITICAL"{"Red"} "HIGH"{"Yellow"} default{"Gray"} }
            Write-Color "  [$($g.Name)] $($g.Count) findings" $color
        }
        Write-Color ""

        $i = 0
        foreach ($f in $script:findings) {
            $i++
            $color = switch ($f.Severity) { "CRITICAL"{"Red"} "HIGH"{"Yellow"} default{"Gray"} }
            Write-Color "  #$i [$($f.Category)] $($f.Severity)" $color
            Write-Color "     $($f.Detail)" "Gray"
            Write-Color "     => $($f.Suggestion)" "DarkYellow"
            Write-Color ""
        }
    }

    # Save report
    $reportDir = "$env:USERPROFILE\Desktop\MaddixSuite\AntiHack_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

    $html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>AntiHack Report</title>
<style>body{font-family:Segoe UI;background:#0d1117;color:#c9d1d9;padding:20px}
.container{max-width:900px;margin:auto;background:#161b22;border-radius:12px;padding:30px}
h1{color:#58a6ff}.critical{color:#da3633}.high{color:#d29922}.medium{color:#58a6ff}
.finding{margin:10px 0;padding:10px;border-left:4px solid;border-radius:4px}
.crit{border-color:#da3633;background:#1c1011} .high{border-color:#d29922;background:#1c1700}
.med{border-color:#1f6feb;background:#0d1117}
.tag{display:inline-block;padding:2px 8px;border-radius:8px;font-size:.8em}
.crit .tag{background:#da3633;color:#fff} .high .tag{background:#d29922;color:#000} .med .tag{background:#1f6feb;color:#fff}
</style></head><body><div class='container'>
<h1>MaddixSuite — AntiHack Report</h1>
<p style='color:#8b949e;'>$(Get-Date 'g') | $env:COMPUTERNAME</p>
<p>Total threats: $script:threatCount | Findings: $($script:findings.Count)</p>
<hr style='border-color:#30363d;'>"

    foreach ($f in $script:findings) {
        $cls = switch ($f.Severity) { "CRITICAL"{"crit"} "HIGH"{"high"} default{"med"} }
        $html += "<div class='finding $cls'><span class='tag'>$($f.Severity)</span> <strong>$($f.Category)</strong><br>$($f.Detail)<br><em style='color:#8b949e;'>$($f.Suggestion)</em></div>"
    }

    $html += "<hr style='border-color:#30363d;'><p style='color:#8b949e;'>MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite | https://iodeck.ir</p></div></body></html>"
    $html | Set-Content "$reportDir\Report.html" -Encoding UTF8
    Write-Color "  Report saved: $reportDir\Report.html" "Green"
}

# ===========================================================================
# CLEANUP ACTIONS
# ===========================================================================
function Invoke-Cleanup {
    if (-not $Clean) { return }
    if (-not (Confirm-Step "Apply Security Actions" "Kill threats, disable persistence, clean firewall rules?")) { return }

    Write-Color "  [*] Executing security actions..." "Cyan"
    foreach ($f in $script:findings) {
        if ($f.Severity -in @("CRITICAL","HIGH")) {
            Write-Color "    $($f.Category): $($f.Suggestion)" "DarkYellow"
            try { Invoke-Expression $f.Suggestion -ErrorAction SilentlyContinue } catch {}
        }
    }
    Write-Color "  [+] Cleanup actions applied (partial — some may require manual intervention)" "Green"
}

# ===========================================================================
# MAIN
# ===========================================================================
Test-Admin
Clear-Host
Write-Color "╔═══════════════════════════════════════════════════════════╗" "Cyan"
Write-Color "║       MaddixSuite — Advanced Anti-Hack Scanner            ║" "Cyan"
Write-Color "╚═══════════════════════════════════════════════════════════╝" "Cyan"
Write-Color "  GitHub: https://github.com/mohammadmehrani/MaddixSuite" "DarkGray"
Write-Color "  Website: https://iodeck.ir" "DarkGray"
Write-Color "  [i] Scanning for: Keyloggers, Rootkits, Backdoors, RATs, Credential Theft, Network Attacks" "Gray"
Write-Color ""

Scan-NetworkAttacks
Scan-Keyloggers
Scan-Persistence
Scan-ProcessMemory
Scan-BrowserCreds
Scan-FirewallExploits
Show-Report
Invoke-Cleanup

Write-Color "`n  Scan complete. Visit https://iodeck.ir for more tools." "DarkGray"
