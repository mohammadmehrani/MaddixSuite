BeforeAll {
    function Register-Tool { param($Config) $script:TestTool = $Config }
}

Describe "AD-001" {
    BeforeAll {
        . "$PSScriptRoot/../../../../windows/ToolLib/AD/AD-001.ps1"
    }

    It "Should register with ID AD-001" {
        $script:TestTool.ID | Should -Be "AD-001"
    }

    It "Should be ServerOnly" {
        $script:TestTool.ServerOnly | Should -Be $true
    }

    It "Should be in AD category" {
        $script:TestTool.Category | Should -Be "AD"
    }
}

Describe "AD-006" {
    BeforeAll {
        . "$PSScriptRoot/../../../../windows/ToolLib/AD/AD-006.ps1"
    }

    It "Should register with ID AD-006" {
        $script:TestTool.ID | Should -Be "AD-006"
    }

    It "Should be ServerOnly" {
        $script:TestTool.ServerOnly | Should -Be $true
    }
}

Describe "AD-016" {
    BeforeAll {
        . "$PSScriptRoot/../../../../windows/ToolLib/AD/AD-016.ps1"
    }

    It "Should register with ID AD-016" {
        $script:TestTool.ID | Should -Be "AD-016"
    }

    It "Should be ServerOnly" {
        $script:TestTool.ServerOnly | Should -Be $true
    }
}

Describe "AD-025" {
    BeforeAll {
        . "$PSScriptRoot/../../../../windows/ToolLib/AD/AD-025.ps1"
    }

    It "Should register with ID AD-025" {
        $script:TestTool.ID | Should -Be "AD-025"
    }
}

Describe "AD-035" {
    BeforeAll {
        . "$PSScriptRoot/../../../../windows/ToolLib/AD/AD-035.ps1"
    }

    It "Should register with ID AD-035" {
        $script:TestTool.ID | Should -Be "AD-035"
    }
}

Describe "AD-041" {
    BeforeAll {
        . "$PSScriptRoot/../../../../windows/ToolLib/AD/AD-041.ps1"
    }

    It "Should register with ID AD-041" {
        $script:TestTool.ID | Should -Be "AD-041"
    }
}

Describe "AD-051" {
    BeforeAll {
        . "$PSScriptRoot/../../../../windows/ToolLib/AD/AD-051.ps1"
    }

    It "Should register with ID AD-051" {
        $script:TestTool.ID | Should -Be "AD-051"
    }
}
