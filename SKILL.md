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

Run the bundled script:

```powershell
scripts\performance-check.ps1          # REPORT - read-only, changes nothing
scripts\performance-check.ps1 -Tune    # report + offer safe fixes, Y/N each
```

Or double-click `Report.bat` / `TuneUp.bat` (right-click → *Run as
administrator* to unlock `sfc /scannow` and DISM repair offers).

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
