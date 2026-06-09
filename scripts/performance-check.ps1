# windows-performance-tuneup — health & performance report for a Windows PC,
# with an optional, fully-consented tune-up mode.
#
#   .\performance-check.ps1          REPORT (default): read-only diagnosis + recommendations.
#   .\performance-check.ps1 -Tune    report, then offer safe fixes one by one (Y/N each).
#
# CLIENT-MACHINE SAFE BY DESIGN:
#   - Report mode changes absolutely nothing.
#   - Tune mode only offers reversible, official actions (power plan, DNS flush,
#     system file integrity check) and each one asks first.
#   - It never uninstalls software, never disables services or startup items,
#     never edits registry "tweaks", never touches any user or client file.
#
# Works on Windows PowerShell 5.1 (preinstalled) and PowerShell 7+.

param([switch]$Tune)

$ErrorActionPreference = 'SilentlyContinue'
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Section($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }
function Good($t)    { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Warn($t)    { Write-Host "  [!]    $t" -ForegroundColor Yellow }
function Info($t)    { Write-Host "  $t" }
function Ask($q)     { (Read-Host "  $q [y/N]") -match '^[yY]$' }

$recommendations = New-Object System.Collections.Generic.List[string]

# ---------------------------------------------------------------- report

Section "System"
$os  = Get-CimInstance Win32_OperatingSystem
$cs  = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor
$uptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
Info ("{0}  (build {1})" -f $os.Caption, $os.BuildNumber)
Info ("{0}  |  {1} logical cores" -f $cpu.Name.Trim(), $cs.NumberOfLogicalProcessors)
Info ("Uptime: {0} days" -f $uptimeDays)
if ($uptimeDays -gt 14) {
    Warn "No full restart in over 2 weeks - memory leaks and pending updates pile up."
    $recommendations.Add("Restart the PC (a real Restart, not Shut down - Fast Startup skips cleanup).")
}

Section "Memory"
$ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$ramFree  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$ramUsedPct = [math]::Round(100 * ($ramTotal - $ramFree) / $ramTotal)
Info ("RAM: {0} GB total, {1} GB free  ({2}% used)" -f $ramTotal, $ramFree, $ramUsedPct)
if ($ramUsedPct -ge 85) {
    Warn "RAM usage is high - see top consumers below."
    $recommendations.Add("Close or uninstall the heaviest RAM consumers, or consider a RAM upgrade if this is constant.")
} else { Good "Memory headroom is fine." }
Info "Top memory consumers:"
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 8 | ForEach-Object {
    Info ("   {0,8:N0} MB  {1}" -f ($_.WorkingSet64 / 1MB), $_.ProcessName)
}

Section "Storage"
$drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freePct = [math]::Round(100 * $drive.FreeSpace / $drive.Size)
Info ("C: {0} GB total, {1} GB free ({2}%)" -f [math]::Round($drive.Size/1GB), [math]::Round($drive.FreeSpace/1GB), $freePct)
if ($freePct -lt 15) {
    Warn "Less than 15% free - Windows slows down noticeably below this."
    $recommendations.Add("Free up disk space (see the windows-storage-cleanup tool).")
} else { Good "Free space is healthy." }
Get-PhysicalDisk | ForEach-Object {
    $note = ""
    if ($_.MediaType -eq 'HDD') { $note = "  (spinning disk - an SSD upgrade is the single biggest speed-up)" }
    Info ("Disk: {0}  [{1}]  Health: {2}{3}" -f $_.FriendlyName, $_.MediaType, $_.HealthStatus, $note)
    if ($_.HealthStatus -ne 'Healthy') {
        Warn "Disk health is NOT healthy - back up immediately!"
        $recommendations.Add("BACK UP NOW and replace the unhealthy disk.")
    }
    if ($_.MediaType -eq 'HDD') {
        $recommendations.Add("Consider an SSD upgrade (HDD detected) - by far the biggest performance win.")
    }
}

Section "Startup programs (slow logins start here)"
$startup = Get-CimInstance Win32_StartupCommand
if ($startup) {
    $startup | ForEach-Object { Info ("   {0}  <- {1}" -f $_.Name, $_.Location) }
    if (@($startup).Count -gt 8) {
        Warn ("{0} startup entries - each one slows logon and stays in RAM." -f @($startup).Count)
        $recommendations.Add("Review startup apps in Task Manager > Startup apps; disable what is not needed daily (do not disable security/backup agents on client machines).")
    }
} else { Info "   (none found)" }

Section "Power plan"
$plan = powercfg /getactivescheme
Info ("   " + ($plan -replace '^Power Scheme GUID:\s*', ''))
if ($plan -match 'Power saver') {
    Warn "Power saver plan throttles the CPU."
    $recommendations.Add("Switch to Balanced or High performance power plan.")
}

Section "Pending reboot"
$pending = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
           (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
if ($pending) {
    Warn "A reboot is pending (updates waiting) - performance and stability suffer until restarted."
    $recommendations.Add("Restart to finish installing updates.")
} else { Good "No reboot pending." }

Section "Recent system errors (last 7 days)"
$errors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 200
$crashes = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1001; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; StartTime=(Get-Date).AddDays(-30)} -MaxEvents 10
Info ("   {0} error events in the System log this week" -f @($errors).Count)
if (@($crashes).Count -gt 0) {
    Warn ("   {0} blue-screen crash(es) in the last 30 days - check Reliability Monitor (perfmon /rel)." -f @($crashes).Count)
    $recommendations.Add("Investigate blue-screen crashes: Reliability Monitor (perfmon /rel), update drivers.")
}

Section "Recommendations"
if ($recommendations.Count -eq 0) {
    Good "Nothing urgent - this machine looks healthy."
} else {
    $i = 1
    $recommendations | Select-Object -Unique | ForEach-Object { Info ("   {0}. {1}" -f $i, $_); $i++ }
}

if (-not $Tune) {
    Write-Host "`nReport only - nothing was changed. Run with -Tune for guided, consented fixes." -ForegroundColor Green
    exit 0
}

# ---------------------------------------------------------------- tune (each step asks)

Section "Tune-up (each action asks first; all are official and reversible)"

if (Ask "Flush the DNS cache (harmless, fixes some 'slow internet' complaints)?") {
    ipconfig /flushdns | Out-Null
    Good "DNS cache flushed."
}

if (Ask "Switch power plan? (1=Balanced 2=High performance after confirming)") {
    $choice = Read-Host "  Enter 1 for Balanced, 2 for High performance, anything else to skip"
    if ($choice -eq '1') { powercfg /setactive SCHEME_BALANCED; Good "Balanced plan active." }
    elseif ($choice -eq '2') { powercfg /setactive SCHEME_MIN; Good "High performance plan active." }
}

if ($IsAdmin) {
    if (Ask "Run system file integrity check (sfc /scannow - official, read/repair system files, ~10 min)?") {
        sfc /scannow
    }
    if (Ask "Run component-store repair (DISM /RestoreHealth - official, can take 15+ min)?") {
        Dism.exe /Online /Cleanup-Image /RestoreHealth
    }
} else {
    Info "  (Run as administrator to be offered sfc /scannow and DISM /RestoreHealth.)"
}

Write-Host ""
Good "Tune-up finished. Startup apps were listed but NOT changed - that stays a human decision in Task Manager."
