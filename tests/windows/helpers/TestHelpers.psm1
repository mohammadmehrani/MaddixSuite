# MaddixSuite Test Helpers Module
# Import: Import-Module "$PSScriptRoot\TestHelpers.psm1" -Force

function New-MockADDomain {
    param([string]$DNSRoot = "test.local", [string]$DomainMode = "WinThreshold")
    return [PSCustomObject]@{
        DNSRoot = $DNSRoot
        DomainMode = $DomainMode
        PDCEmulator = "DC01.test.local"
        RIDMaster = "DC01.test.local"
        InfrastructureMaster = "DC01.test.local"
        Forest = "test.local"
        Children = @()
    }
}

function New-MockADForest {
    param([string]$Name = "test.local", [string]$ForestMode = "WinThreshold")
    return [PSCustomObject]@{
        Name = $Name
        ForestMode = $ForestMode
        SchemaMaster = "DC01.test.local"
        DomainNamingMaster = "DC01.test.local"
        RootDomain = "test.local"
    }
}

function New-MockSystemInfo {
    return [PSCustomObject]@{
        OSName = "Windows 11 Pro"
        OSVersion = "10.0.22631"
        OSBuild = "22631"
        OSEdition = "Client"
        IsServer = $false
        CPUModel = "Intel(R) Core(TM) i7-7700HQ CPU @ 2.80GHz"
        CPUCores = 4
        CPUThreads = 8
        RAMTotal = 32.00
        RAMFree = 18.50
        DiskTotal = 475.00
        DiskFree = 320.00
        GPUName = "NVIDIA GeForce GTX 1050"
        GPUVRAM = "4096 MB"
        IP = "192.168.1.100"
        MAC = "AA:BB:CC:DD:EE:FF"
        DNS = "8.8.8.8, 1.1.1.1"
        Uptime = "5d 12h 30m"
        NETVersion = "4.8 or later"
        PSVersion = "7.4.0"
        Serial = "ABC123"
    }
}

function New-MockToolConfig {
    param(
        [string]$ID = "SYS-999",
        [string]$Name = "Mock Tool",
        [string]$Category = "SYS",
        [string]$Description = "Mock tool for testing",
        [string]$DangerLevel = "Safe",
        [string]$ConfirmMessage = "Mock confirmation",
        [bool]$ServerOnly = $false,
        [bool]$ClientOnly = $false,
        [scriptblock]$Action = { Write-Output "Mock action executed" }
    )
    return @{
        ID = $ID
        Name = $Name
        Category = $Category
        Description = $Description
        DangerLevel = $DangerLevel
        ConfirmMessage = $ConfirmMessage
        ServerOnly = $ServerOnly
        ClientOnly = $ClientOnly
        Action = $Action
    }
}

function Invoke-InPesterScope {
    param([scriptblock]$Script)
    & $Script
}

Export-ModuleMember -Function New-MockADDomain, New-MockADForest, New-MockSystemInfo, New-MockToolConfig, Invoke-InPesterScope
