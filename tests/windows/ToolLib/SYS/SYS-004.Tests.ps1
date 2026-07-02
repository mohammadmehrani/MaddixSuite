BeforeAll {
    $script:ToolLibPath = "$PSScriptRoot/../../../../windows/ToolLib/SYS"
    function Register-Tool { param($Config) $script:TestTool = $Config }
}

Describe "SYS-004" {
    BeforeAll {
        . "$script:ToolLibPath/SYS-004.ps1"
    }

    It "Should register with ID SYS-004" {
        $script:TestTool.ID | Should -Be "SYS-004"
    }

    It "Should be in SYS category" {
        $script:TestTool.Category | Should -Be "SYS"
    }
}
