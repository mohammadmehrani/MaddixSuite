BeforeAll {
    Mock Write-Host { }
    Mock Read-Host { return "quit" }
    Mock Start-Sleep { }
}

Describe "Maddix-Mystery" {
    Context "Script Loading" {
        It "Should load without errors" {
            { . "$PSScriptRoot/../../windows/Maddix-Mystery.ps1" } | Should -Not -Throw
        }

        It "Should define all game functions" {
            . "$PSScriptRoot/../../windows/Maddix-Mystery.ps1"
            $expected = @(
                "Show-Banner", "Build-World", "Show-Clues",
                "Check-Clue", "Show-Help", "Start-Mystery"
            )
            foreach ($f in $expected) {
                (Get-Command $f -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Game World" {
        BeforeAll {
            . "$PSScriptRoot/../../windows/Maddix-Mystery.ps1"
            $script:GameDir = "$env:TEMP\MaddixTest_$(Get-Random)"
            Build-World
        }

        It "Should create game directory structure" {
            Test-Path "$script:GameDir/etc" | Should -Be $true
            Test-Path "$script:GameDir/var/log" | Should -Be $true
            Test-Path "$script:GameDir/home/admin/.ssh" | Should -Be $true
            Test-Path "$script:GameDir/opt/backup" | Should -Be $true
            Test-Path "$script:GameDir/tmp" | Should -Be $true
            Test-Path "$script:GameDir/mnt/backup" | Should -Be $true
            Test-Path "$script:GameDir/usr/share" | Should -Be $true
        }

        It "Should create clue files" {
            Test-Path "$script:GameDir/home/admin/.ssh/authorized_keys" | Should -Be $true
            Test-Path "$script:GameDir/opt/backup/notes.txt" | Should -Be $true
            Test-Path "$script:GameDir/opt/backup/script.ps1" | Should -Be $true
            Test-Path "$script:GameDir/tmp/.hidden" | Should -Be $true
            Test-Path "$script:GameDir/mnt/backup/cracked.txt" | Should -Be $true
            Test-Path "$script:GameDir/usr/share/readme.txt" | Should -Be $true
        }

        It "Check-Clue should detect SSH key clue" {
            $script:FoundClues = @()
            $script:Score = 0
            Check-Clue -Path "$script:GameDir/home/admin/.ssh/authorized_keys"
            $script:FoundClues.Count | Should -Be 1
            $script:FoundClues[0] | Should -Match "SSH"
            $script:Score | Should -Be 20
        }

        It "Check-Clue should not duplicate clues" {
            $script:FoundClues = @("SSH key backdoor")
            $script:Score = 20
            Check-Clue -Path "$script:GameDir/home/admin/.ssh/authorized_keys"
            $script:FoundClues.Count | Should -Be 1
            $script:Score | Should -Be 20
        }

        AfterAll {
            Remove-Item -Path $script:GameDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Test Mode" {
        It "Start-Mystery -TestMode should build world only" {
            . "$PSScriptRoot/../../windows/Maddix-Mystery.ps1"
            $gameDir = "$env:TEMP\MaddixTest2_$(Get-Random)"
            $script:GameDir = $gameDir
            Start-Mystery -TestMode
            Test-Path $gameDir | Should -Be $true
            Remove-Item -Path $gameDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
