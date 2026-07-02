Register-Tool @{
    ID          = 'DEV-007'
    Name        = 'Dev Environment Check'
    Category    = 'DEV'
    Description = 'Check available dev tools and versions'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Scan for installed developer tools?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Developer Environment Report" "Cyan"
            Write-Color "  " ""

            $tools = @(
                @{Cmd='git'; Label='Git'},
                @{Cmd='node'; Label='Node.js'},
                @{Cmd='npm'; Label='npm'},
                @{Cmd='python'; Label='Python'},
                @{Cmd='pip'; Label='pip'},
                @{Cmd='dotnet'; Label='.NET SDK'},
                @{Cmd='code'; Label='VS Code'},
                @{Cmd='docker'; Label='Docker'},
                @{Cmd='wsl'; Label='WSL'},
                @{Cmd='nvm'; Label='nvm-windows'},
                @{Cmd='go'; Label='Go'},
                @{Cmd='rustc'; Label='Rust'},
                @{Cmd='java'; Label='Java'},
                @{Cmd='mvn'; Label='Maven'},
                @{Cmd='choco'; Label='Chocolatey'},
                @{Cmd='winget'; Label='winget'},
                @{Cmd='psversiontable'; Label='PowerShell'},
                @{Cmd='nuget'; Label='NuGet'},
                @{Cmd='rg'; Label='ripgrep'},
                @{Cmd='fd'; Label='fd'},
                @{Cmd='curl'; Label='curl'},
                @{Cmd='7z'; Label='7-Zip'}
            )

            $results = @()
            foreach ($tool in $tools) {
                $result = [PSCustomObject]@{ Tool = $tool.Label; Status = 'Not found'; Version = '' }

                if ($tool.Cmd -eq 'psversiontable') {
                    $result.Status = 'Found'
                    $result.Version = $PSVersionTable.PSVersion.ToString()
                } else {
                    $cmd = Get-Command $tool.Cmd -ErrorAction SilentlyContinue
                    if ($cmd) {
                        $result.Status = 'Found'
                        try {
                            switch ($tool.Cmd) {
                                'node' { $ver = & $tool.Cmd --version 2>$null }
                                'npm' { $ver = & $tool.Cmd --version 2>$null }
                                'python' { $ver = & $tool.Cmd --version 2>&1 }
                                'dotnet' { $ver = & $tool.Cmd --version 2>$null }
                                'java' { $ver = (& $tool.Cmd -version 2>&1)[0] }
                                'rustc' { $ver = & $tool.Cmd --version 2>$null }
                                'go' { $ver = & $tool.Cmd version 2>$null }
                                default { $ver = & $tool.Cmd --version 2>$null }
                            }
                            if ($ver) { $result.Version = $ver.Trim() }
                        } catch { }
                    }
                }
                $results += $result
            }

            $results | Format-Table -Property @{N='Tool';E={$_.Tool.PadRight(15)}},
                @{N='Status';E={$_.Status.PadRight(10)}},
                @{N='Version';E={$_.Version}} -AutoSize -Wrap | Out-String | ForEach-Object { Write-Host $_ }

            $found = ($results | Where-Object { $_.Status -eq 'Found' } | Measure-Object).Count
            $total = $results.Count
            Write-Color "  [+] $found of $total developer tools found" "Green"

            if ($found -lt $total) {
                Write-Color "  [i] Missing tools can be installed via DEV tools (DEV-001 to DEV-010)" "Cyan"
            }
        } catch {
            Write-Color "  [!] Environment check failed: $_" "Red"
        }
        Pause
    }
}
