@{
    Run = @{
        Path = @(
            'tests/windows/'
        )
        Exit = $true
        PassThru = $true
    }
    Output = @{
        Verbosity = 'Detailed'
        StackTrace = $true
        CIFormat = 'Auto'
    }
    CodeCoverage = @{
        Enabled = $true
        Path = @(
            'windows/ToolLib/SYS/SYS-*.ps1',
            'windows/MaddixSuite.ps1',
            'windows/SRV/Maddix-AD.ps1'
        )
        OutputFormat = 'JaCoCo'
        OutputPath = 'coverage/windows/jacoco.xml'
    }
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = 'tests/windows/test-results.xml'
    }
}
