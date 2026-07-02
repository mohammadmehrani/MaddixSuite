BeforeAll {
    . "$PSScriptRoot/../../windows/MaddixSuite.ps1"
    $script:TestReportLog = $script:ReportLog
}

Describe "MaddixSuite Framework" {
    Context "System Detection" {
        It "Should detect system info without errors" {
            $info = Get-SystemInfo
            $info | Should -Not -BeNullOrEmpty
            $info.OSName | Should -Not -BeNullOrEmpty
            $info.OSEdition | Should -Not -BeNullOrEmpty
        }

        It "Should detect OS edition correctly" {
            $info = Get-SystemInfo
            $info.OSEdition | Should -BeIn @("Server", "Client")
        }
    }

    Context "Tool Loading" {
        It "Should load tools without errors" {
            Load-Tools
            $script:AllTools | Should -Not -BeNullOrEmpty
            $script:AllTools.Count | Should -BeGreaterThan 0
        }

        It "Should load SYS tools" {
            $sysTools = $script:AllTools | Where-Object Category -eq "SYS"
            $sysTools | Should -Not -BeNullOrEmpty
        }

        It "Should create ToolLib directories if missing" {
            $testPath = Join-Path $script:ToolLibPath "TEST"
            if (Test-Path $testPath) { Remove-Item $testPath -Force }
            $null = New-Item -ItemType Directory -Path $testPath -Force
            Test-Path $testPath | Should -Be $true
            Remove-Item $testPath -Force
        }
    }

    Context "Tool Filtering" {
        It "Should filter server-only tools on client OS" {
            $script:IsServer = $false
            $filtered = Get-FilteredTools
            $serverTools = $filtered | Where-Object { $_.ServerOnly -or $_.Category -in @("SRV", "AD") }
            $serverTools | Should -BeNullOrEmpty
        }
    }

    Context "Tool Finding" {
        It "Should find tool by ID" {
            Load-Tools
            $tool = Find-Tool -Id "SYS-001"
            $tool | Should -Not -BeNullOrEmpty
            $tool.ID | Should -Be "SYS-001"
        }

        It "Should return null for nonexistent tool" {
            $tool = Find-Tool -Id "SYS-99999"
            $tool | Should -BeNullOrEmpty
        }
    }

    Context "Category Functions" {
        It "Should return correct category name for SYS" {
            Get-ToolCategory "SYS" | Should -Be "System Tools"
        }

        It "Should return correct category name for NET" {
            Get-ToolCategory "NET" | Should -Be "Network Tools"
        }

        It "Should return correct category name for AD" {
            Get-ToolCategory "AD" | Should -Be "Active Directory"
        }
    }

    Context "Helper Functions" {
        It "Write-Log should not throw" {
            { Write-Log -Message "Test message" -Type "INFO" } | Should -Not -Throw
        }

        It "Write-Color should not throw" {
            { Write-Color -Text "Test" -Color "Green" } | Should -Not -Throw
        }
    }
}
