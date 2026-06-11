# ⚡ Windows Performance Tune-Up

Find out **why** a Windows PC feels slow — then fix it with consent, not guesswork.

Most "optimizer" tools apply blind registry tweaks and break things. This tool works like a good technician: **diagnose first** with a read-only health report, then offer only safe, official, reversible fixes — each one asking Y/N. Safe enough to run on a client's computer.

## Quick start (no terminal needed)

1. Download or clone this repo onto the PC
2. Double-click **`Report.bat`** → read-only health report + prioritized recommendations
3. Double-click **`TuneUp.bat`** → same report, then guided fixes (each asks first)
4. Double-click **`Debloat.bat`** → assess installed apps & startup, then remove bloat **per category, with consent** (protected apps are never touched)

Right-click → **Run as administrator** to unlock the system repair offers
(`sfc /scannow`, `DISM /RestoreHealth`) and the optional System Restore Point in Debloat.

Prefer a terminal?

```powershell
.\scripts\performance-check.ps1          # report only
.\scripts\performance-check.ps1 -Tune    # report + guided fixes

.\scripts\debloat-assistant.ps1          # assess apps & startup (read-only)
.\scripts\debloat-assistant.ps1 -Apply   # remove bloat per-category + manage startup, all consented
```

## What the report covers

| Check | Why it matters |
|-------|----------------|
| **RAM pressure + top 8 consumers** | ≥85% sustained → everything swaps and crawls |
| **Disk type (SSD/HDD) + health** | HDD = biggest upgrade win; unhealthy disk = back up *now* |
| **Free space on C:** | Below ~15% Windows degrades badly |
| **Startup programs** | The #1 cause of slow logons and background drag |
| **Power plan** | Power saver silently throttles the CPU |
| **Pending reboot + uptime** | Updates half-installed for weeks hurt stability |
| **System errors + blue-screens** | 30-day crash history points to driver/hardware issues |

It ends with a **numbered, prioritized recommendation list** — hardware truths first
(an SSD upgrade beats every software tweak combined), then the free wins.

## What `-Tune` can do (each asks Y/N)

- Flush the DNS cache
- Switch power plan (Balanced / High performance)
- System file integrity check — `sfc /scannow` (admin)
- Component-store repair — `DISM /Online /Cleanup-Image /RestoreHealth` (admin)

## Debloat assistant (`Debloat.bat` / `debloat-assistant.ps1`)

The report tool stays strictly hands-off. The **debloat assistant** is the opt-in
companion for when you *do* want to remove bloat and trim startup — built to be safe
enough for a work or client machine:

- **Protected allowlist that can never be removed:** email/Outlook, Teams, Office,
  OneDrive, SharePoint, PowerApps, Power Automate, the Microsoft Store, Terminal,
  Notepad, Calculator, Photos, Camera, Edge, security & Xbox dependency apps, all
  codec extensions, common dev tools (VS Code, Python, NVIDIA…), **and every
  non-Microsoft app by default.**
- **Asks per category** before removing anything — bloat/discontinued, games,
  Xbox overlays, OEM (HP/Dell/Lenovo), third-party promo apps.
- **Startup manager** lists per-user startup entries and lets you disable any one
  by one — after backing the whole key up to a `.reg` file you can double-click to
  restore.
- **Backups & reversibility:** optional System Restore Point (admin), `.reg` backup
  of startup, and every removed Store app reinstalls from the Microsoft Store.

Assess first (`debloat-assistant.ps1`, read-only), then run `-Apply` only when ready.

## What the report tool will NEVER do — the client-machine guarantee

(The read-only report / `-Tune` tool. The debloat assistant above is the separate,
clearly-labelled, consent-heavy tool for removals.)

- ❌ Disable startup items or services on its own (it lists them; disabling stays your decision)
- ❌ Registry "performance tweaks", debloat scripts, third-party optimizer engines
- ❌ Uninstall anything
- ❌ Touch any user or client file
- ❌ Change anything at all in report mode — it is strictly read-only

## Using it as an agent skill

This repo doubles as a plug-and-play skill for AI coding agents: point your agent at
the repository (or drop the folder into its skills directory) and
[SKILL.md](SKILL.md) gives it the full methodology — diagnose-first workflow, the
priority order for reading the report, and the hard "never change without consent"
rules.

Pairs well with [windows-storage-cleanup](https://github.com/Ahmed-Masoud-MS/windows-storage-cleanup)
for the "disk is nearly full" finding.

## License

MIT — see [LICENSE](LICENSE).
