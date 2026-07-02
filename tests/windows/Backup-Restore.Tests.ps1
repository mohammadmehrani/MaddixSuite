BeforeAll {
    Mock Write-Host { }
    Mock Start-Sleep { }
}

Describe "Backup-Restore" {
    Context "Script Loading" {
        It "Should load without errors" {
            { . "$PSScriptRoot/../../windows/Backup-Restore.ps1" } | Should -Not -Throw
        }

        It "Should define core functions" {
            . "$PSScriptRoot/../../windows/Backup-Restore.ps1"
            $expected = @(
                "Write-Color", "Confirm-Step", "Do-Backup",
                "Do-Restore", "List-Backups", "Edit-Config",
                "Invoke-BackupRestore"
            )
            foreach ($f in $expected) {
                (Get-Command $f -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            }
        }
    }
}
