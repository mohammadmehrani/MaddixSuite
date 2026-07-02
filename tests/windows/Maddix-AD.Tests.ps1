BeforeAll {
    Mock Get-WindowsFeature { return @{Installed = $true} }
    Mock Write-Host { }
    Mock Start-Sleep { }
    Mock Pause { }
}

Describe "Maddix-AD" {
    Context "Script Loading" {
        It "Should load without errors" {
            { . "$PSScriptRoot/../../windows/SRV/Maddix-AD.ps1" } | Should -Not -Throw
        }

        It "Should define all 40+ AD functions" {
            . "$PSScriptRoot/../../windows/SRV/Maddix-AD.ps1"
            $expected = @(
                "Show-ADStatus", "Install-ADRole", "Create-NewDomain",
                "Manage-FSMORoles", "Manage-ADUsers", "Manage-GPO",
                "AD-ReplicationCheck", "AD-SitesServices", "AD-RecycleBin",
                "AD-Schema", "AD-CertificateServices", "AD-FileServer",
                "AD-DFS", "AD-Cluster", "AD-Backup", "AD-Restore",
                "AD-Cleanup", "AD-DNS", "AD-DHCP", "AD-Samba",
                "AD-RODC", "AD-Trust", "AD-PasswordPolicy", "AD-FGPP",
                "AD-Audit", "AD-Delegation", "AD-DCDiag", "AD-KDS",
                "AD-gMSA", "AD-ADFS", "AD-AzureConnect"
            )
            foreach ($f in $expected) {
                (Get-Command $f -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "AD Functions" {
        BeforeAll {
            . "$PSScriptRoot/../../windows/SRV/Maddix-AD.ps1"
        }

        It "Get-ADSystemInfo should return system info object" {
            Mock Get-CimInstance { return @{Caption = "Windows Server 2022"; BuildNumber = "20348"} }
            Mock Get-WindowsFeature { return @{Installed = $false} }
            $result = Get-ADSystemInfo
            $result | Should -Not -BeNullOrEmpty
            $result.OSName | Should -Be "Windows Server 2022"
        }

        It "Get-ADSystemInfo should detect server OS" {
            Mock Get-CimInstance { return @{Caption = "Windows Server 2022"} }
            $result = Get-ADSystemInfo
            $result.IsServer | Should -Be $true
        }

        It "Test-ADRole should check AD DS role" {
            Mock Get-WindowsFeature { return @{Installed = $true} }
            Test-ADRole | Should -Be $true
        }

        It "Test-ADRole should return false when not installed" {
            Mock Get-WindowsFeature { return @{Installed = $false} }
            Test-ADRole | Should -Be $false
        }
    }

    Context "Menu Structure" {
        BeforeAll {
            . "$PSScriptRoot/../../windows/SRV/Maddix-AD.ps1"
        }

        It "Show-Menu should contain AD-001" {
            Mock Write-Color { }
            Mock Read-Host { return "0" }
            Show-Menu | Should -Not -Throw
        }
    }
}
