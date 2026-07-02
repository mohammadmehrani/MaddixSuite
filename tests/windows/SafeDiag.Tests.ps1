BeforeAll {
    Mock Write-Host { }
    Mock Start-Sleep { }
    Mock Pause { }
}

Describe "SafeDiag" {
    Context "Script Loading" {
        It "Should load without errors" {
            { . "$PSScriptRoot/../../windows/SafeDiag.ps1" } | Should -Not -Throw
        }

        It "Should define all phase functions" {
            . "$PSScriptRoot/../../windows/SafeDiag.ps1"
            $functions = @(
                "Phase1-Diagnostic", "Phase2-Report", "Phase3-Fixes",
                "Phase4-Optimizations", "Phase5-Report", "Invoke-SafeDiag"
            )
            foreach ($f in $functions) {
                (Get-Command $f -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Helper Functions" {
        BeforeAll {
            . "$PSScriptRoot/../../windows/SafeDiag.ps1"
        }

        It "Write-Log should append to report" {
            $testPath = "$env:TEMP\SafeDiag_Test.log"
            $script:ReportTXT = $testPath
            Write-Log -Message "Test entry" -Type "INFO"
            Test-Path $testPath | Should -Be $true
            $content = Get-Content $testPath
            $content | Should -Match "Test entry"
            Remove-Item $testPath -Force
        }

        It "Add-Issue should add to issues array" {
            $script:Issues = @()
            Add-Issue -Level "WARNING" -Category "Test" -Description "Test issue" -Suggestion "Fix it" -Consequence "None"
            $script:Issues.Count | Should -Be 1
            $script:Issues[0].Level | Should -Be "WARNING"
            $script:Issues[0].Description | Should -Be "Test issue"
        }
    }

    Context "Parameters" {
        It "Should have -Auto parameter" {
            $params = (Get-Command "$PSScriptRoot/../../windows/SafeDiag.ps1").Parameters
            $params.ContainsKey("Auto") | Should -Be $true
        }

        It "Should have -ReportOnly parameter" {
            $params = (Get-Command "$PSScriptRoot/../../windows/SafeDiag.ps1").Parameters
            $params.ContainsKey("ReportOnly") | Should -Be $true
        }

        It "Should have -Fix parameter" {
            $params = (Get-Command "$PSScriptRoot/../../windows/SafeDiag.ps1").Parameters
            $params.ContainsKey("Fix") | Should -Be $true
        }
    }
}
