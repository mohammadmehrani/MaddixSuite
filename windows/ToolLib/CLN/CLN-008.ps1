Register-Tool @{
    ID          = 'CLN-008'
    Name        = 'Recycle Bin Cleaner'
    Category    = 'CLN'
    Description = 'Empty all recycle bins'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Empty all Recycle Bins on all drives'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Emptying all Recycle Bins..." "Yellow"

            $shell = New-Object -ComObject Shell.Application
            $recycler = $shell.NameSpace(0xa)
            if ($recycler.Items().Count -gt 0) {
                Write-Color "    Found $($recycler.Items().Count) items in Recycle Bin" "Cyan"
            } else {
                Write-Color "    Recycle Bin is already empty" "Green"
            }

            $recycler.Items() | ForEach-Object { $_.InvokeVerb('delete') }

            $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
            foreach ($drive in $drives) {
                $driveLetter = $drive.DeviceID
                try {
                    $path = "C:`$Recycle.Bin"
                    if ($driveLetter -ne 'C:') {
                        $path = "$driveLetter`$Recycle.Bin"
                    }
                    if (Test-Path $path -ErrorAction SilentlyContinue) {
                        Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Color "    Drive $driveLetter cleaned" "Green"
                    }
                } catch {
                    Write-Color "    Drive $driveLetter: $($_.Exception.Message)" "Red"
                }
            }

            Write-Color "  [+] All Recycle Bins emptied" "Green"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
