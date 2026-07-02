BeforeAll {
    $script:ToolLibPath = "$PSScriptRoot/../../../../windows/ToolLib/SYS"
    $script:ToolInfo = $null
    function Register-Tool { param($Config) $script:TestTool = $Config }
}

Describe "SYS-001" {
    BeforeAll {
        . "$script:ToolLibPath/SYS-001.ps1"
    }

    It "Should register with ID SYS-001" {
        $script:TestTool.ID | Should -Be "SYS-001"
    }

    It "Should be in SYS category" {
        $script:TestTool.Category | Should -Be "SYS"
    }

    It "Should be Safe level" {
        $script:TestTool.DangerLevel | Should -Be "Safe"
    }

    It "Should not be ServerOnly" {
        $script:TestTool.ServerOnly | Should -Be $false
    }

    It "Should not be ClientOnly" {
        $script:TestTool.ClientOnly | Should -Be $false
    }

    It "Should have a description" {
        $script:TestTool.Description | Should -Not -BeNullOrEmpty
    }

    It "Should have a confirmation message" {
        $script:TestTool.ConfirmMessage | Should -Not -BeNullOrEmpty
    }

    It "Should have an Action scriptblock" {
        $script:TestTool.Action | Should -Not -BeNullOrEmpty
    }
}
