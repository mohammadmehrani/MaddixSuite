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

        It "Should define all module functions" {
            . "$PSScriptRoot/../../windows/Security/Maddix-AntiHack.ps1"
            $modules = @(
                "Invoke-Module1", "Invoke-Module2", "Invoke-Module3",
                "Invoke-Module4", "Invoke-Module5", "Invoke-Module6",
                "Show-Report", "Invoke-Cleanup", "Start-AntiHackScan"
            )
            foreach ($m in $modules) {
                (Get-Command $m -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
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
