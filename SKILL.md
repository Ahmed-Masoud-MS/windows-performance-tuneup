---
name: windows-performance-tuneup
description: >-
  Diagnose why a Windows PC feels slow and apply only safe, consented fixes.
  Produces a read-only health report (RAM pressure, disk type/health, free
  space, startup load, power plan, pending reboot, crash history) with
  prioritized recommendations; -Tune offers reversible official actions one
  by one. Use when a user or client says their PC is slow, freezing, or they
  want a health check. Never disables, uninstalls, or tweaks anything on its
  own.
---

# Windows performance tune-up (diagnose first, fix with consent)

Run the bundled scripts:

```powershell
scripts\performance-check.ps1          # REPORT - read-only, changes nothing
scripts\performance-check.ps1 -Tune    # report + offer safe fixes, Y/N each

scripts\debloat-assistant.ps1          # ASSESS apps & startup - read-only
scripts\debloat-assistant.ps1 -Apply   # remove bloat per-category + trim startup, all consented
```

Or double-click `Report.bat` / `TuneUp.bat` / `Debloat.bat` (right-click → *Run as
administrator* to unlock `sfc /scannow`, DISM repair, and the restore-point offer).

## Hard rules — especially on a client's computer

1. **Diagnose before changing anything.** The report is the deliverable;
   share it and the recommendation list first.
2. **Every change asks individually** and is official + reversible:
   DNS flush, power-plan switch, `sfc /scannow`, `DISM /RestoreHealth`.
3. **Never auto-disable startup items or services.** The report lists them
   with counts and guidance — disabling is a human decision in Task Manager,
   and security/backup/management agents on client machines are off-limits.
4. **No registry "performance tweaks", no third-party optimizers, no
   uninstalls, no debloat scripts.** These cause the support tickets they
   claim to prevent.
5. **Never touch user or client files.** This tool reads system state only.
6. **Escalate hardware findings, don't work around them**: unhealthy disk →
   back up now and replace; HDD → recommend SSD; constant RAM ≥85% →
   close/upgrade. Software tweaks cannot fix hardware bottlenecks.

## How to read the report (priority order)

1. **Disk health not Healthy** → stop, back up, replace. Nothing else matters.
2. **HDD as system disk** → SSD upgrade beats every software fix combined.
3. **Free space < 15%** → clean up first (see windows-storage-cleanup);
   Windows degrades badly when nearly full.
4. **RAM ≥ 85% used** → identify the top consumers in the report; close,
   reconfigure, or add RAM.
5. **Pending reboot / uptime > 14 days** → restart properly (Restart, not
   Shut down — Fast Startup makes "shut down" skip the cleanup).
6. **Blue-screen history** → driver/hardware issue; check Reliability
   Monitor (`perfmon /rel`) before any tuning.
7. **Startup list long** → biggest cause of "slow since I got it" — review
   in Task Manager → Startup apps.
8. **Power saver plan** → CPU is being throttled; Balanced/High performance.

## Debloat assistant — methodology (when removal IS wanted)

The report tool never removes anything. When the user explicitly wants to remove
bloat or trim startup, use `debloat-assistant.ps1` and follow these rules:

1. **Assess first (read-only), present the categorised list, then ask.** Never
   remove an app the user has not seen grouped and approved.
2. **The PROTECTED allowlist is absolute.** Email/Outlook, Teams, Office, OneDrive,
   SharePoint, PowerApps, Power Automate, Store, Terminal, Notepad, Calculator,
   Photos, Camera, Edge, security & Xbox *dependency* apps, codec extensions, and
   all non-Microsoft apps are never offered for removal — even if the user says
   "remove everything". This is the email/work-data guarantee.
3. **Ask per category, not all-at-once:** bloat/discontinued, games, Xbox overlays,
   OEM (HP/Dell/Lenovo), third-party promo apps. The user may keep some categories.
4. **Xbox nuance:** the gaming front-ends (GamingApp, GamingServices, Xbox*Overlay,
   GameAssist) are removable; `XboxIdentityProvider`, `Xbox.TCUI` and
   `XboxGameCallableUI` are protected because Store/Photos and some apps depend on them.
5. **Startup ≠ uninstall.** Disabling a startup entry only stops auto-launch; the app
   still opens manually. Always back up the `HKCU\...\Run` key to a `.reg` file before
   editing, and never disable security/backup/sync/management agents on client machines.
6. **Distinguish startup locations.** Per-user `Run` keys are safe to edit; entries
   under `HKU\S-1-5-18` / `.DEFAULT` are system/default-profile and often *orphaned
   stubs* pointing at uninstalled apps — verify the target exe exists before acting.
7. **Cache-sweep gotcha:** "new" Teams `LocalCache` and Edge `Service Worker` storage
   are NOT pure throwaway cache — deleting them while the app/PWA runs can sign the
   user out. Only clear with the app closed, and prefer leaving them on a healthy disk.
8. **Reversibility:** offer a System Restore Point (admin) before removals; removed
   Store apps reinstall from the Microsoft Store; startup restores from the `.reg` backup.
