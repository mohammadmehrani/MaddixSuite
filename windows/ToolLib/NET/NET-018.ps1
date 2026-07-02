Register-Tool @{
    ID          = 'NET-018'
    Name        = 'SSL Certificate Check'
    Category    = 'NET'
    Description = 'Check SSL certificate expiry and details for a URL'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Checks SSL certificate information for a remote host.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── SSL CERTIFICATE CHECK ───" "Cyan"
        $url = Read-Host "  Target URL (e.g. example.com or https://example.com)"
        $url = $url -replace '^https?://', ''
        $port = Read-Host "  Port [default: 443]"
        if ([string]::IsNullOrWhiteSpace($port)) { $port = 443 } else { $port = [int]$port }
        try {
            Write-Color "  Connecting to $url`:$port..." "Yellow"
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($url, $port)
            $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, { $true })
            $ssl.AuthenticateAsClient($url)
            $cert = $ssl.RemoteCertificate
            $cert2 = [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert
            $ssl.Close()
            $tcp.Close()
            $now = Get-Date
            $expiry = $cert2.NotAfter
            $remaining = ($expiry - $now).Days
            $issuedBy = $cert2.Issuer
            $issuedTo = $cert2.Subject
            $thumbprint = $cert2.Thumbprint
            $serial = $cert2.SerialNumber
            $sigAlgo = $cert2.SignatureAlgorithm.FriendlyName
            $keySize = if ($cert2.PublicKey.Key) { $cert2.PublicKey.Key.KeySize } else { "N/A" }
            $dnsNames = @()
            try {
                $extensions = $cert2.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Subject Alternative Name" }
                foreach ($ext in $extensions) {
                    $str = $ext.Format($false)
                    $dnsNames += $str -split ', ' | ForEach-Object { $_ -replace 'DNS Name=', '' }
                }
            } catch { }
            Write-Color "`n  ┌──────────────────────────────────────┐" "Cyan"
            Write-Color "  │         SSL CERTIFICATE INFO          │" "Cyan"
            Write-Color "  ├──────────────────────────────────────┤" "Cyan"
            Write-Color "  │ Host: $url".PadRight(39) + "│" "White"
            Write-Color "  │ Issued To: $($issuedTo.Substring(0, [Math]::Min(30, $issuedTo.Length)))".PadRight(39) + "│" "White"
            Write-Color "  │ Issuer: $($issuedBy.Substring(0, [Math]::Min(30, $issuedBy.Length)))".PadRight(39) + "│" "White"
            Write-Color "  │ Subject: $($issuedTo.Substring(0, [Math]::Min(30, $issuedTo.Length)))".PadRight(39) + "│" "White"
            Write-Color "  │ Valid From: $($cert2.NotBefore.ToString('yyyy-MM-dd'))".PadRight(39) + "│" "Gray"
            Write-Color "  │ Expires:  $($expiry.ToString('yyyy-MM-dd'))".PadRight(39) + "│" ($remaining -le 30 ? "Red" : "Green")
            Write-Color "  │ Days Left: $remaining days".PadRight(39) + "│" ($remaining -le 30 ? "Red" : ($remaining -le 90 ? "Yellow" : "Green"))
            Write-Color "  │ Algorithm: $sigAlgo".PadRight(39) + "│" "Gray"
            Write-Color "  │ Key Size: $keySize bits".PadRight(39) + "│" "Gray"
            Write-Color "  │ Serial: $($serial.Substring(0, [Math]::Min(20, $serial.Length)))...".PadRight(39) + "│" "Gray"
            Write-Color "  │ Thumbprint: $($thumbprint.Substring(0, [Math]::Min(20, $thumbprint.Length)))...".PadRight(39) + "│" "Gray"
            Write-Color "  └──────────────────────────────────────┘" "Cyan"
            if ($dnsNames.Count -gt 0) {
                Write-Color "`n  SAN DNS Names: $($dnsNames -join ', ')" "Gray"
            }
            if ($remaining -le 0) {
                Write-Color "`n  [!] CERTIFICATE EXPIRED!" "Red"
            } elseif ($remaining -le 30) {
                Write-Color "`n  [!] Certificate expires in less than 30 days!" "Yellow"
            }
        } catch {
            Write-Color "  [!] SSL check failed: $_" "Red"
        }
        Pause
    }
}
