# FAQ & Troubleshooting

Frequently asked questions and solutions to common issues.

---

## General

### Q: Do I need to be an administrator?
**A:** Yes. All Windows scripts require **Administrator** privileges. Linux scripts require **sudo** for most operations.

### Q: Will these scripts damage my system?
**A:** Designed with safety first:
- `SafeDiag.ps1` is read-only in Phase 1 — it only reads logs
- All scripts create a **Restore Point** before making changes
- Every action shows consequences before asking for confirmation
- You can always undo changes via System Restore

### Q: Where are reports saved?
**A:**
- **Windows:** `%USERPROFILE%\Desktop\MaddixSuite\`
- **Linux:** `~/MaddixSuite/`

### Q: How do I update the scripts?
**A:** Just re-run the one-liner from GitHub. The scripts always load the latest version.

---

## Windows Issues

### Q: Script says "Execution Policy" error
**A:** The script auto-bypasses this, but if it fails:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
Then run the script again.

### Q: BSOD / Freeze after running a script
**A:** Run `SafeDiag.ps1` immediately — it will:
1. Read the minidump files
2. Check Event Logs for the crash cause
3. Suggest targeted fixes with consequences explained

Common causes:
- Recently installed VPN/antivirus drivers conflicting
- Faulty hardware (RAM, disk)
- Corrupted system files

### Q: Restore Point creation failed
**A:** Enable System Restore manually:
1. Press Win + R, type `SystemPropertiesProtection.exe`
2. Select your drive → **Configure**
3. Enable System Restore

### Q: DISM / SFC fails
**A:** Run these in order:
```powershell
dism /online /cleanup-image /startcomponentcleanup
dism /online /cleanup-image /restorehealth
sfc /scannow
```
Then reboot and run again.

### Q: Can I undo the registry tweaks?
**A:** Yes. The `Maddix-RegistryTool.ps1` option **2 (Restore)** lets you import a previous backup. Option **4 (Optimize)** also backs up before applying changes.

### Q: Docker Desktop install fails
**A:** Ensure:
1. Virtualization is enabled in BIOS
2. WSL2 is properly installed (run option 2 in DockerSetup)
3. Your CPU supports SLAT (check with `systeminfo`)

---

## Linux Issues

### Q: "Command not found" for package manager
**A:** The script auto-detects your distro. If it fails, check:
```bash
cat /etc/os-release
```
Then manually install: `apt` (Debian/Ubuntu), `dnf` (Fedora), `pacman` (Arch), `zypper` (openSUSE).

### Q: Firewall blocked my SSH
**A:** If you enabled the server profile and locked yourself out:
1. Boot into recovery mode or use a VNC console
2. Run: `iptables -P INPUT ACCEPT && iptables -F`
3. Check SSH port: the server profile leaves port 22 open with brute-force protection

### Q: Docker install script failed
**A:** Try the official method:
```bash
curl -fsSL https://get.docker.com | sh
```

### Q: ClamAV scan is too slow
**A:** Limit the scan scope:
```bash
clamscan -r --quiet /home/$USER
```
Or increase scan timeout in the hardener script.

### Q: How to restore packages from backup?
**A:** Run `SysAdminSuite.sh` → option **14 (Restore Packages)**. The script will list available backups and prompt for selection.

---

## Error Codes

| Error | Likely Cause | Solution |
|-------|-------------|----------|
| BSOD 0xD1 | Faulty driver (VPN, network) | Run SafeDiag → check minidumps → disable driver |
| BSOD 0x1A | Memory issue | Run Memory Diagnostic (SysAdminSuite option 33) |
| BSOD 0x7E | System file corruption | Run SFC + DISM (options 3-5) |
| Linux "Kernel panic" | Hardware / driver | Check dmesg, run fsck |
| Docker "Cannot connect" | Docker not running | `sudo systemctl start docker` |

---

## Still having issues?

1. Run `SafeDiag.ps1` and share the generated HTML report
2. Check the Event Viewer: `eventvwr.msc` → Windows Logs → System (filter by Critical)
3. Open an issue on [GitHub](https://github.com/mohammadmehrani/MaddixSuite/issues)
