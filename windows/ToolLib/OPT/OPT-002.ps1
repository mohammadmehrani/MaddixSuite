Register-Tool @{
    ID          = 'OPT-002'
    Name        = 'RAM Optimizer'
    Category    = 'OPT'
    Description = 'Memory compression, Superfetch, pagefile config'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Apply RAM and memory optimizations'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] RAM Optimization Settings:" "Green"

            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            $totalGB = [math]::Round($os.TotalVisibleMemorySize/1MB,1)
            $freeGB = [math]::Round($os.FreePhysicalMemory/1MB,1)
            Write-Color "    Total RAM: $totalGB GB, Free: $freeGB GB ($([math]::Round($freeGB/$totalGB*100,1))% free)" "Cyan"

            Write-Color "`n  [*] Memory Compression:" "Yellow"
            $mmAgent = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'DisablePagingExecutive' -ErrorAction SilentlyContinue
            $compress = Get-MMAgent -ErrorAction SilentlyContinue
            if ($compress) {
                Write-Color "    Memory Compression: $($compress.MemoryCompression)" "Cyan"
            }

            Write-Color "`n  [*] SysMain (Superfetch):" "Yellow"
            $sysmain = Get-Service -Name 'SysMain' -ErrorAction SilentlyContinue
            if ($sysmain) {
                Write-Color "    Status: $($sysmain.Status), StartType: $($sysmain.StartType)" "Cyan"
                $disable = Read-Host "  [+] Disable SysMain (Superfetch)? Recommended for SSD. (y/N)"
                if ($disable -eq 'y') {
                    Stop-Service -Name 'SysMain' -Force -ErrorAction SilentlyContinue
                    Set-Service -Name 'SysMain' -StartupType Disabled
                    Write-Color "  [+] SysMain disabled" "Green"
                }
            }

            Write-Color "`n  [*] Pagefile Configuration:" "Yellow"
            $pagefile = Get-CimInstance -ClassName Win32_PageFileUsage
            if ($pagefile) {
                $pfSize = [math]::Round($pagefile.AllocatedBaseSize/1MB,1)
                Write-Color "    Current pagefile: $pfSize GB (Drive: $($pagefile.Name))" "Cyan"
            }

            Write-Color "`n  [*] Large System Cache:" "Yellow"
            $lsc = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'LargeSystemCache' -ErrorAction SilentlyContinue
            Write-Color "    Large System Cache: $(if($lsc.LargeSystemCache -eq 1){'Enabled'}else{'Disabled'})" "Cyan"

            Write-Color "`n  [*] Clear Working Set:" "Yellow"
            $clear = Read-Host "  [+] Clear system working set (flush standby list)? (y/N)"
            if ($clear -eq 'y') {
                $sig = @'
[DllImport("kernel32.dll")]
public static extern void SetLastError(uint dwErr);
public static extern bool EmptyWorkingSet(IntPtr hProcess);
'@
                Add-Type -TypeDefinition $sig -Name Mem -Namespace Win32
                $procs = Get-Process
                foreach ($p in $procs) {
                    try { [Win32.Mem]::EmptyWorkingSet($p.Handle) } catch {}
                }
                Write-Color "  [+] Working set flushed" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
