# Testing & CI/CD

MaddixSuite has automated testing for both Windows (PowerShell/Pester) and Linux (Bash/BATS) platforms. Tests run on every push to `main`.

---

## CI/CD Pipelines

| Workflow | Platform | Tool | Status |
|----------|----------|------|--------|
| `lint.yml` | Both | PSScriptAnalyzer, ShellCheck, yamllint | ✅ |
| `test-linux.yml` | Linux | BATS (Bash Automated Testing System) | ✅ |
| `test-windows.yml` | Windows | Pester 5 | ❌ (in progress) |
| `security.yml` | Both | Gitleaks, Trivy | ✅ |
| `release.yml` | Both | Checksums + GitHub Release | ⏸️ (tag only) |

---

## Linux Tests (BATS)

### Test Files

```
tests/linux/
├── MaddixSuite.Tests.bats       (18 tests)
├── SysAdminSuite.Tests.bats      (3 tests)
├── maddix-antihack.Tests.bats    (11 tests)
├── maddix-devsetup.Tests.bats    (3 tests)
├── maddix-docker.Tests.bats      (3 tests)
├── maddix-hardener.Tests.bats    (5 tests)
├── maddix-iptables.Tests.bats    (4 tests)
└── helpers/
    ├── setup.bash                (mock functions + path exports)
    └── sample-*.csv              (fixtures)
```

### Run Locally

```bash
bats tests/linux/
```

### Test Coverage

- **47 tests total** across 7 script modules
- Tests verify: script loading, function existence, output formatting, array manipulation
- Mock functions prevent side effects (no actual sudo, apt, ping, etc.)

---

## Windows Tests (Pester)

### Test Files

```
tests/windows/
├── Backup-Restore.Tests.ps1         (2 tests)
├── Maddix-AD.Tests.ps1              (6 tests)
├── Maddix-AntiHack.Tests.ps1        (4 tests)
├── Maddix-Mystery.Tests.ps1         (10 tests)
├── MaddixSuite.Tests.ps1            (17 tests)
├── SafeDiag.Tests.ps1               (7 tests)
├── ToolLib/
│   ├── AD/AD-001.Tests.ps1          (7 describes for AD-001..051)
│   └── SYS/SYS-001.Tests.ps1        (8 tests for SYS-001..005)
└── helpers/
    ├── TestHelpers.psm1             (mock factories)
    ├── MockData.ps1                 (sample AD data)
    └── Pester.config.psd1           (test configuration)
```

### Run Locally

```powershell
# From repo root:
Import-Module Pester -PassThru
Invoke-Pester tests/windows/ -Output Detailed
```

### Test Coverage

- **66 tests total** across 12 files
- Covers: framework loading, system detection, tool filtering, parameter validation, module functions, game mechanics
- `BeforeAll` blocks mock console/cmdlets (`Write-Host`, `Read-Host`, `Clear-Host`, `Start-Sleep`)
- ToolLib tests use a stub `Register-Tool` to capture tool metadata

---

## Writing Tests

### BATS (Linux)

```bash
setup() {
    source "${MADDIX_ROOT}/linux/MaddixSuite.sh"
}

@test "function should do something" {
    run some_function
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected text" ]]
}
```

### Pester (Windows)

```powershell
BeforeAll {
    . "$PSScriptRoot/../../windows/TargetScript.ps1"
    Mock Write-Host { }
}

Describe "Module Name" {
    It "should work" {
        $result = Get-Something
        $result | Should -Not -BeNullOrEmpty
    }
}
```

---

## Common Pitfalls

| Issue | Fix |
|-------|-----|
| `Clear-Host` fails in CI | Wrap in `try { Clear-Host } catch { }` |
| Main loop hangs on dot-source | Guard with `if ($MyInvocation.InvocationName -ne '.')` |
| Variables lost in `run` | Call function directly instead of `run` |
| `rm -rf /tmp/*` destroys BATS temp | Guard with `if [[ -z "$MADDIX_TEST_MODE" ]]` |
| `[math]::Min(120, Get-ConsoleWidth)` | Use `(Get-ConsoleWidth)` |
| `"  Clue $i: $c"` parse error | Use `"  Clue $($i): $c"` |
