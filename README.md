# ⚡ Windows Performance Tune-Up

Find out **why** a Windows PC feels slow — then fix it with consent, not guesswork.

Most "optimizer" tools apply blind registry tweaks and break things. This tool works like a good technician: **diagnose first** with a read-only health report, then offer only safe, official, reversible fixes — each one asking Y/N. Safe enough to run on a client's computer.

## Quick start (no terminal needed)

1. Download or clone this repo onto the PC
2. Double-click **`Report.bat`** → read-only health report + prioritized recommendations
3. Double-click **`TuneUp.bat`** → same report, then guided fixes (each asks first)

Right-click → **Run as administrator** to unlock the system repair offers
(`sfc /scannow`, `DISM /RestoreHealth`).

Prefer a terminal?

```powershell
.\scripts\performance-check.ps1          # report only
.\scripts\performance-check.ps1 -Tune    # report + guided fixes
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

## What it will NEVER do — the client-machine guarantee

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
