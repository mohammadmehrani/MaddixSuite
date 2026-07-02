BeforeAll {
    $script:ToolLibPath = "$PSScriptRoot/../../../../windows/ToolLib/SYS"
    $script:ToolInfo = $null
    function Register-Tool { param($Config) $script:TestTool = $Config }
}

Describe "SYS-002" {
    BeforeAll {
        . "$script:ToolLibPath/SYS-002.ps1"
    }

    It "Should register with ID SYS-002" {
        $script:TestTool.ID | Should -Be "SYS-002"
    }

    It "Should be Safe level" {
        $script:TestTool.DangerLevel | Should -Be "Safe"
    }

    It "Should create a restore point" {
        Mock Checkpoint-Computer { }
        & $script:TestTool.Action
        Should -Invoke Checkpoint-Computer -Times 1
    }
}
