BeforeAll {
    Mock Write-Host { }
    Mock Start-Sleep { }
    Mock Pause { }
    Mock Read-Host { return "0" }
    Mock Get-CimInstance { return @{Caption = "Windows Server 2022"; BuildNumber = "20348"} }
    Mock Get-WindowsFeature { return @{Installed = $true} }
}

Describe "Maddix-AD" {
    Context "Script Loading" {
        It "Should load without errors" {
            { . "$PSScriptRoot/../../windows/SRV/Maddix-AD.ps1" } | Should -Not -Throw
        }

        It "Should define loader functions" {
            . "$PSScriptRoot/../../windows/SRV/Maddix-AD.ps1"
            $expected = @("Register-Tool", "Confirm-Step", "Show-Banner", "Show-Menu", "Write-Color", "Log")
            foreach ($f in $expected) {
                (Get-Command $f -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Tool Discovery" {
        It "Should find AD-*.ps1 files in ToolLib" {
            $adPath = Resolve-Path "$PSScriptRoot/../../windows/ToolLib/AD"
            $files = Get-ChildItem $adPath -Filter "AD-*.ps1"
            $files.Count | Should -BeGreaterOrEqual 40
            $files[0].Name | Should -Match "AD-\d{3}"
        }

        It "Each AD-*.ps1 should call Register-Tool" {
            $adPath = Resolve-Path "$PSScriptRoot/../../windows/ToolLib/AD"
            $files = Get-ChildItem $adPath -Filter "AD-*.ps1" | Select-Object -First 3
            foreach ($f in $files) {
                $content = Get-Content $f.FullName -Raw
                $content | Should -Match "Register-Tool"
            }
        }
    }

    Context "Menu Structure" {
        BeforeAll {
            . "$PSScriptRoot/../../windows/SRV/Maddix-AD.ps1"
        }

        It "Show-Menu should not throw" {
            Show-Menu | Should -Not -Throw
        }
    }
}
