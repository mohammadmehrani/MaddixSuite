BeforeAll {
    $script:ToolLibPath = "$PSScriptRoot/../../../../windows/ToolLib/SYS"
    function Register-Tool { param($Config) $script:TestTool = $Config }
}

Describe "SYS-005" {
    BeforeAll {
        . "$script:ToolLibPath/SYS-005.ps1"
    }

    It "Should register with ID SYS-005" {
        $script:TestTool.ID | Should -Be "SYS-005"
    }

    It "Should have a disk check action" {
        $script:TestTool.Description | Should -Match "disk"
    }
}
