BeforeAll {
    $script:ToolLibPath = "$PSScriptRoot/../../../../windows/ToolLib/SYS"
    function Register-Tool { param($Config) $script:TestTool = $Config }
}

Describe "SYS-003" {
    BeforeAll {
        . "$script:ToolLibPath/SYS-003.ps1"
    }

    It "Should register with ID SYS-003" {
        $script:TestTool.ID | Should -Be "SYS-003"
    }

    It "Should be Caution level" {
        $script:TestTool.DangerLevel | Should -Be "Caution"
    }
}
