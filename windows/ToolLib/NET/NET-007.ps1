Register-Tool @{
    ID          = 'NET-007'
    Name        = 'Speed Test'
    Category    = 'NET'
    Description = 'Download speed estimation using BITS transfer'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Downloads a test file via BITS to estimate network speed.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── SPEED TEST ───" "Cyan"
        Write-Color "  Estimating download speed using BITS transfer..." "Yellow"
        Write-Color "  Downloading test file (~10 MB)" "White"
        $testUrl = "http://speedtest.tele2.net/10MB.zip"
        $tempFile = "$env:TEMP\speedtest_10MB.zip"
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        try {
            $startTime = Get-Date
            $job = Start-BitsTransfer -Source $testUrl -Destination $tempFile -Asynchronous -Priority High
            do {
                Start-Sleep -Milliseconds 500
                $job = Get-BitsTransfer -JobId $job.JobId
                $percent = $job.BytesTransferred / $job.BytesTotal * 100
                Write-Progress -Activity "Downloading test file..." -Status "$([math]::Round($percent, 0))% Complete" -PercentComplete $percent
            } while ($job.JobState -eq "Transferring")
            Get-BitsTransfer -JobId $job.JobId | Complete-BitsTransfer
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            $fileSize = (Get-Item $tempFile).Length
            $speedBps = $fileSize / $duration
            $speedKbps = $speedBps / 1000
            $speedMbps = $speedKbps / 1000
            Write-Color "`n  ┌──────────────────────────────────────┐" "Cyan"
            Write-Color "  │ File Size:     $('{0:N2}' -f ($fileSize / 1MB)) MB".PadRight(39) + "│" "White"
            Write-Color "  │ Duration:      $('{0:N2}' -f $duration) sec".PadRight(39) + "│" "White"
            Write-Color "  │ Speed:         $('{0:N2}' -f $speedMbps) Mbps".PadRight(39) + "│" "Green"
            Write-Color "  │ Speed:         $('{0:N2}' -f $speedKbps) Kbps".PadRight(39) + "│" "Yellow"
            Write-Color "  └──────────────────────────────────────┘" "Cyan"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Color "  [!] Speed test failed: $_" "Red"
            Write-Color "  Try using a different test URL or check connectivity." "Yellow"
        }
        Pause
    }
}
