# Active Directory Management Guide

Active Directory (AD) tools are available only on **Windows Server** editions. They require:

- Windows Server 2012 R2 / 2016 / 2019 / 2022 / 2025
- Active Directory Domain Services (AD DS) role installed
- Administrator privileges

---

## Quick Start

```powershell
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SRV/Maddix-AD.ps1 | iex
```

This loads the AD Management Menu with all 60+ tools.

---

## Tool Reference

### AD-001 to AD-010: Domain & Forest

| ID | Name | Description |
|----|------|-------------|
| AD-001 | Domain Info | View domain/forest details, FSMO roles, sites |
| AD-002 | User Report | Export all users with attributes (last logon, disabled, etc.) |
| AD-003 | Group Report | List all security/distribution groups with members |
| AD-004 | Computer Report | View all domain-joined computers, OS, last logon |
| AD-005 | DNS Audit | Check DNS zones, records, and dynamic updates |
| AD-006 | Replication Status | Check AD replication health between domain controllers |
| AD-007 | GPO Report | List all Group Policies with links and settings |
| AD-008 | OU Structure | Export Organizational Unit hierarchy |
| AD-009 | Trust Relationships | View and manage domain/forest trusts |
| AD-010 | Schema Info | Display AD schema version and attributes |

### AD-011 to AD-020: User Management

| ID | Name | Description |
|----|------|-------------|
| AD-011 | Create User | Bulk create users from CSV |
| AD-012 | Disable Users | Mass disable stale/inactive users |
| AD-013 | Unlock Users | Unlock locked-out accounts |
| AD-014 | Reset Password | Batch password reset with force change |
| AD-015 | Move Users | Move users between OUs |
| AD-016 | Expired Accounts | Find and disable expired accounts |
| AD-017 | Password Report | Check password age, expiry, and strength |
| AD-018 | Last Logon Report | Identify stale accounts by last logon date |
| AD-019 | Group Membership | Add/remove users from groups in bulk |
| AD-020 | Manager Assignment | Set manager field from CSV |

### AD-021 to AD-030: Group Policy

| ID | Name | Description |
|----|------|-------------|
| AD-021 | GPO Backup | Backup all GPOs to a file share |
| AD-022 | GPO Restore | Restore GPOs from backup |
| AD-023 | GPO Permissions | Audit and fix GPO permission inheritance |
| AD-024 | WMI Filter | Apply WMI filters to GPOs for targeted application |
| AD-025 | GPO Report | Generate HTML report of all GPO settings |
| AD-026 | GPO Difference | Compare two GPOs side by side |
| AD-027 | Block Inheritance | Set block inheritance on OUs |
| AD-028 | Enforced GPOs | Mark GPOs as enforced/enforced |
| AD-029 | GPO Delegation | Delegate GPO management to non-admins |
| AD-030 | Starter GPOs | Import/export starter GPOs |

### AD-031 to AD-040: Security & Delegation

| ID | Name | Description |
|----|------|-------------|
| AD-031 | Delegation Wizard | Delegate control for common tasks (reset password, join domain) |
| AD-032 | Admin Count Check | Find users with adminCount > 0 (protected accounts) |
| AD-033 | Kerberos Health | Check Kerberos ticket expiry and encryption types |
| AD-034 | Password Policy | View and configure domain password policy |
| AD-035 | Fine-Grained Passwords | Create and apply PSOs (Password Settings Objects) |
| AD-036 | Lockout Analysis | Find source of account lockouts |
| AD-037 | Privileged Groups | Audit members of Domain Admins, Enterprise Admins, Schema Admins |
| AD-038 | LAPS Status | Check Windows LAPS configuration and password expiry |
| AD-039 | BitLocker Recovery | Query AD for BitLocker recovery passwords |
| AD-040 | Certificate Auto-Enroll | Configure certificate auto-enrollment via GPO |

### AD-041 to AD-050: Health & Monitoring

| ID | Name | Description |
|----|------|-------------|
| AD-041 | Health Dashboard | Overall domain health score with recommendations |
| AD-042 | Permission Analyzer | Analyze effective permissions on OUs |
| AD-043 | Group Membership Report | Comprehensive group membership analysis across domains |
| AD-044 | Last Logon Report | Detailed last logon report with trend analysis |
| AD-045 | Tombstone Lifecycle | Monitor tombstone lifetime and replication backlog |
| AD-046 | PAM Trust | Configure Privileged Access Management trust |
| AD-047 | DNS Zone Migration | Migrate DNS zones between servers |
| AD-048 | DR Plan | Generate disaster recovery plan documentation |
| AD-049 | Schema Extensions | View and manage schema extensions |
| AD-050 | Azure AD Connect | Check Azure AD Connect sync status and errors |

### AD-051 to AD-060: Advanced

| ID | Name | Description |
|----|------|-------------|
| AD-051 | Cross-Forest Migration | Prepare and execute cross-forest user migration |
| AD-052 | Privileged Groups Monitor | Real-time monitoring of privileged group changes |
| AD-053 | gMSA Setup | Create and manage Group Managed Service Accounts |
| AD-054 | AD-ADFS | Manage Active Directory Federation Services |
| AD-055 | AD-FSMO | Transfer or seize FSMO roles |
| AD-056 | AD-Sites | Manage sites, subnets, and site links |
| AD-057 | AD-Cluster | Configure AD-backed failover clustering |
| AD-058 | AD-RODC | Deploy Read-Only Domain Controllers |
| AD-059 | AD-KDS | Configure Key Distribution Service for gMSA |
| AD-060 | Test Lab Builder | Build a test AD lab in Hyper-V |

---

## Architecture

Maddix-AD.ps1 is a **loader** that discovers and registers AD tools from `windows/ToolLib/AD/AD-*.ps1`. Each tool file calls `Register-Tool` with its configuration:

```powershell
Register-Tool @{
    ID = "AD-001"
    Name = "Domain Info"
    Category = "AD"
    ServerOnly = $true
    DangerLevel = "Safe"
    Description = "Displays domain/forest details..."
    Action = {
        # tool implementation
    }
}
```

This modular design allows adding new tools without modifying the loader.
