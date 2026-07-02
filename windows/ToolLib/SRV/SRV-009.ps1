Register-Tool @{
    ID          = 'SRV-009'
    Name        = 'Storage Spaces Config'
    Category    = 'SRV'
    Description = 'Check/create storage pools'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check storage spaces and pools configuration?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Storage Spaces configuration..." "Cyan"

            $storageModule = Get-Module -ListAvailable Storage -ErrorAction SilentlyContinue
            if (-not $storageModule) {
                Write-Color "  [!] Storage module not available" "Red"
                Pause
                return
            }
            Import-Module Storage -ErrorAction SilentlyContinue

            $pools = Get-StoragePool -ErrorAction SilentlyContinue
            if ($pools) {
                Write-Color "  [+] Storage Pools ($($pools.Count)):" "Cyan"
                $pools | Select-Object FriendlyName, OperationalStatus, HealthStatus,
                    @{N='Size';E={[math]::Round($_.Size/1TB,2)}},
                    @{N='Allocated';E={[math]::Round($_.AllocatedSize/1TB,2)}} |
                    Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }

                foreach ($pool in $pools) {
                    $disks = Get-PhysicalDisk -StoragePool $pool -ErrorAction SilentlyContinue
                    if ($disks) {
                        Write-Color "      Disks in '$($pool.FriendlyName)':" "Gray"
                        $disks | Select-Object FriendlyName, MediaType, BusType, Size, HealthStatus |
                            Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
                    }

                    $spaces = Get-VirtualDisk -StoragePool $pool -ErrorAction SilentlyContinue
                    if ($spaces) {
                        Write-Color "      Virtual Disks in '$($pool.FriendlyName)':" "Gray"
                        $spaces | Select-Object FriendlyName, ResilienceSettingName, OperationalStatus,
                            @{N='Size';E={[math]::Round($_.Size/1TB,2)}},
                            @{N='Provisioned';E={[math]::Round($_.ProvisionedSize/1TB,2)}} |
                            Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
                    }
                }
            } else {
                Write-Color "  [i] No storage pools found" "Yellow"
            }

            $physicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.CanPool -eq $true }
            if ($physicalDisks) {
                Write-Color "  [+] Available disks that can be pooled ($($physicalDisks.Count)):" "Cyan"
                $physicalDisks | Select-Object FriendlyName, MediaType, Size, BusType |
                    Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
            }

            $choice = Read-Host "  [?] Create a new storage pool? (y/N)"
            if ($choice -eq 'y') {
                $poolName = Read-Host "  [?] Pool name"
                if (-not $poolName) { $poolName = "MaddixSuite_Pool" }

                $disksToPool = $physicalDisks | Select-Object -First 10
                if ($disksToPool.Count -ge 2) {
                    Write-Color "  [*] Creating storage pool '$poolName'..." "Cyan"
                    $pool = New-StoragePool -FriendlyName $poolName -StorageSubSystemFriendlyName "*" `
                        -PhysicalDisks $disksToPool

                    $spaceName = Read-Host "  [?] Virtual disk name (default: MaddixSuite_Disk)"
                    if (-not $spaceName) { $spaceName = "MaddixSuite_Disk" }

                    Write-Color "  [*] Creating virtual disk '$spaceName'..." "Cyan"
                    $space = New-VirtualDisk -StoragePool $pool -FriendlyName $spaceName `
                        -ResiliencySettingName Simple -UseMaximumSize -ProvisioningType Fixed

                    $space | Get-Disk | Initialize-Disk -PartitionStyle GPT
                    $space | Get-Disk | New-Partition -UseMaximumSize -DriveLetter M
                    $space | Get-Disk | Get-Partition | Format-Volume -FileSystem NTFS `
                        -NewFileSystemLabel $spaceName -Confirm:$false

                    Write-Color "  [+] Storage pool '$poolName' created with virtual disk '$spaceName' (drive M:)" "Green"
                } else {
                    Write-Color "  [!] Need at least 2 physical disks to create a pool" "Yellow"
                }
            }

            $choice2 = Read-Host "  [?] Show storage tier summary? (y/N)"
            if ($choice2 -eq 'y') {
                $volumes = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 'Fixed' }
                Write-Color "  [+] Volume Summary:" "Cyan"
                $volumes | Select-Object DriveLetter, FileSystem, FileSystemLabel,
                    @{N='SizeGB';E={[math]::Round($_.Size/1GB,1)}},
                    @{N='FreeGB';E={[math]::Round($_.SizeRemaining/1GB,1)}},
                    @{N='Used%';E={if($_.Size -gt 0){[math]::Round(($_.Size-$_.SizeRemaining)/$_.Size*100,1)}else{0}}} |
                    Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
            }
        } catch {
            Write-Color "  [!] Storage Spaces check failed: $_" "Red"
        }
        Pause
    }
}
