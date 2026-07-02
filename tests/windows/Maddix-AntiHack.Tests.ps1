BeforeAll {
    Mock Write-Host { }
    Mock Start-Sleep { }
    Mock Pause { }
}

Describe "Maddix-AntiHack" {
    Context "Script Loading" {
        It "Should load without errors" {
            { . "$PSScriptRoot/../../windows/Security/Maddix-AntiHack.ps1" } | Should -Not -Throw
        }

        It "Should define all security scanner functions" {
            . "$PSScriptRoot/../../windows/Security/Maddix-AntiHack.ps1"
            $expected = @(
                "Confirm-Step", "Test-Admin", "Add-Finding",
                "Scan-NetworkAttacks", "Scan-Keyloggers",
                "Scan-Persistence", "Scan-ProcessMemory",
                "Scan-BrowserCreds", "Scan-FirewallExploits",
                "Show-Report", "Invoke-Cleanup"
            )
            foreach ($f in $expected) {
                (Get-Command $f -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Parameters" {
        It "Should have -Auto parameter" {
            . "$PSScriptRoot/../../windows/Security/Maddix-AntiHack.ps1"
            $params = (Get-Command "$PSScriptRoot/../../windows/Security/Maddix-AntiHack.ps1").Parameters
            $params.ContainsKey("Auto") | Should -Be $true
        }

        It "Should have -Clean parameter" {
            $params = (Get-Command "$PSScriptRoot/../../windows/Security/Maddix-AntiHack.ps1").Parameters
            $params.ContainsKey("Clean") | Should -Be $true
        }
    }
}
