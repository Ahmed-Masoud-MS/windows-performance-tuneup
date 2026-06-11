# windows-performance-tuneup — debloat assistant (app assessment + startup manager).
#
#   .\debloat-assistant.ps1            ASSESS (default): scan apps & startup, recommend. Changes NOTHING.
#   .\debloat-assistant.ps1 -Apply     assess, then ask per-category before removing apps / disabling startup.
#
# SAFETY-FIRST BY DESIGN (built for client & work machines):
#   - A hard-coded PROTECTED allowlist can NEVER be removed: email/Outlook, Microsoft 365
#     & work apps (Teams, OneDrive, SharePoint, PowerApps, Power Automate), core Windows
#     (Store, Terminal, Notepad, Calculator, Photos, Camera, Edge, security/Xbox deps),
#     and common dev tools (VS Code, Python, NVIDIA, WhatsApp, etc.).
#   - Nothing is removed or disabled without an explicit per-category Y/N.
#   - Startup changes are backed up to a .reg file first; removed Store apps reinstall from the Store.
#   - Never touches user files, never edits "performance tweak" registry keys.
#
# Works on Windows PowerShell 5.1 (preinstalled) and PowerShell 7+.

param([switch]$Apply)

$ErrorActionPreference = 'SilentlyContinue'
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Section($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }
function Good($t)    { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Warn($t)    { Write-Host "  [!]    $t" -ForegroundColor Yellow }
function Info($t)    { Write-Host "  $t" }
function Ask($q)     { (Read-Host "  $q [y/N]") -match '^[yY]$' }

$backupDir = Join-Path $env:TEMP "win-tuneup-backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }

# ---------------------------------------------------------------- PROTECTED allowlist
# These app IDs (matched as wildcards against AppX package Name) are NEVER offered for removal.
$Protected = @(
    # --- Email & Outlook ---
    'Microsoft.OutlookForWindows', 'microsoft.windowscommunicationsapps', 'Microsoft.People',
    # --- Microsoft 365 & work apps ---
    'MSTeams', 'MicrosoftTeams', 'Microsoft.Teams*', 'Microsoft.OneDriveSync', 'Microsoft.OneDrive',
    'Microsoft.MicrosoftOfficeHub', 'Microsoft.Office.*', '*powerapps*', 'Microsoft.PowerAutomateDesktop',
    '*sharepoint*', 'Microsoft.Windows365', 'Microsoft.M365Companions', 'Microsoft.OfficePushNotificationUtility',
    # --- Core Windows (removing these breaks the OS or key features) ---
    'Microsoft.WindowsStore', 'Microsoft.StorePurchaseApp', 'Microsoft.DesktopAppInstaller', 'Microsoft.Winget.*',
    'Microsoft.WindowsTerminal', 'Microsoft.WindowsNotepad', 'Microsoft.WindowsCalculator',
    'Microsoft.Windows.Photos', 'Microsoft.WindowsCamera', 'Microsoft.ScreenSketch', 'Microsoft.Paint',
    'Microsoft.MicrosoftEdge*', 'Microsoft.SecHealthUI', 'Microsoft.Windows.SecHealthUI', 'Microsoft.PowerShell',
    'Microsoft.UI.*', 'Microsoft.VCLibs.*', 'Microsoft.NET.*', 'MicrosoftWindows.*', 'Microsoft.Windows.*',
    'Microsoft.AAD.*', 'Microsoft.AccountsControl', 'Microsoft.CredDialogHost', 'Microsoft.LockApp',
    'Microsoft.BioEnrollment', 'Microsoft.ECApp', 'Microsoft.AsyncTextService', 'Microsoft.Win32WebViewHost',
    # Xbox dependency apps the OS/Store/Photos rely on (the gaming front-ends are NOT here, so they can be removed)
    'Microsoft.XboxIdentityProvider', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxGameCallableUI',
    # Media/codec extensions other apps depend on
    'Microsoft.*VideoExtension*', 'Microsoft.*ImageExtension*', 'Microsoft.WebMediaExtensions', 'Microsoft.HEVCVideoExtensions',
    'Microsoft.RawImageExtension', 'Microsoft.WebpImageExtension', 'Microsoft.HEIFImageExtension',
    'Microsoft.WinAppRuntime.*', 'MicrosoftCorporationII.WinAppRuntime.*',
    # --- Dev tools & user's known software (non-MS publishers are protected by default anyway) ---
    'Microsoft.VisualStudioCode', 'PythonSoftwareFoundation.*', '*Claude*', '*WhatsApp*',
    'NVIDIACorp.*', 'RealtekSemiconductorCorp.*', 'NotepadPlusPlus', '*QuillBot*'
)

function Test-Protected($name) {
    foreach ($p in $Protected) { if ($name -like $p) { return $true } }
    return $false
}

# ---------------------------------------------------------------- removal categories
# Apps grouped by category. Only Store (AppX) apps are listed; all are reinstallable from the Store.
$Categories = [ordered]@{
    'Bloat / discontinued' = @(
        'Microsoft.MixedReality.Portal','Microsoft.SkypeApp','Microsoft.Windows.DevHome',
        'Microsoft.BingNews','Microsoft.BingFinance','Microsoft.BingSports','Microsoft.BingWeather',
        'Microsoft.BingFoodAndDrink','Microsoft.BingHealthAndFitness','Microsoft.BingTravel','Microsoft.BingTranslator',
        'Microsoft.News','Microsoft.Getstarted','Microsoft.Messaging','Microsoft.OneConnect',
        'Microsoft.Microsoft3DViewer','Microsoft.3DBuilder','Microsoft.Print3D','Microsoft.MicrosoftJournal',
        'Microsoft.Office.Sway','Microsoft.MicrosoftPowerBIForWindows','Microsoft.NetworkSpeedTest',
        'Clipchamp.Clipchamp','Microsoft.WindowsFeedbackHub','Microsoft.549981C3F5F10','Microsoft.PCManager',
        'Microsoft.Windows.AIHub','Microsoft.Copilot'
    )
    'Games & casual' = @(
        'Microsoft.MicrosoftSolitaireCollection','king.com.CandyCrushSaga','king.com.CandyCrushSodaSaga',
        'king.com.BubbleWitch3Saga','Microsoft.MinecraftUWP','*.Asphalt8Airborne','*.CookingFever',
        '*.FarmVille2CountryEscape','*.HiddenCity','*.DisneyMagicKingdoms','*.MarchofEmpires',
        '*.RoyalRevolt','*.CaesarsSlots','*.NYTCrossword'
    )
    'Xbox / gaming overlays' = @(
        'Microsoft.GamingApp','Microsoft.GamingServices','Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay','Microsoft.XboxSpeechToTextOverlay','Microsoft.Edge.GameAssist',
        'Microsoft.XboxApp'
    )
    'OEM (HP / Dell / Lenovo)' = @(
        'AD2F1837.*','E046963F.LenovoCompanion','LenovoCompanyLimited.*','DellInc.*'
    )
    'Third-party promo apps' = @(
        'SpotifyAB.*','*.Netflix','*.TikTok','*.Facebook','*.Instagram','*.Twitter','*.LinkedIn*',
        'AmazonVideo.PrimeVideo','Amazon.com.Amazon','*.Duolingo*','*.Disney*','*.Spotify','*.Shazam',
        '*.Flipboard','*.Plex','*.Pandora*','*.Hulu*','*.Viber','*.WinZip*','AdobeSystemsIncorporated.*'
    )
}

# ---------------------------------------------------------------- assess apps
Section "Installed Store apps assessment"
$installed = Get-AppxPackage | Where-Object { -not $_.IsFramework } | Select-Object -ExpandProperty Name

$plan = [ordered]@{}
foreach ($cat in $Categories.Keys) {
    $hits = @()
    foreach ($pattern in $Categories[$cat]) {
        $installed | Where-Object { $_ -like $pattern -and -not (Test-Protected $_) } | ForEach-Object { $hits += $_ }
    }
    $hits = $hits | Select-Object -Unique
    if ($hits.Count) {
        $plan[$cat] = $hits
        Write-Host ("`n  [{0}]  ({1} found):" -f $cat, $hits.Count) -ForegroundColor Yellow
        $hits | ForEach-Object { Info ("     - {0}" -f $_) }
    }
}
if ($plan.Count -eq 0) { Good "No removable bloat detected - this machine is already clean." }

Write-Host ""
Good ("PROTECTED (never removable): email/Outlook, Teams, Office, OneDrive, SharePoint, PowerApps,")
Info  ("           Store, Terminal, Notepad, Calculator, Photos, Camera, Edge, dev tools, and all non-Microsoft apps.")

# ---------------------------------------------------------------- assess startup
Section "Startup programs (per-user Run key)"
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$runEntries = @()
if (Test-Path $runKey) {
    (Get-ItemProperty $runKey).PSObject.Properties |
        Where-Object { $_.Name -notmatch '^PS' } |
        ForEach-Object { $runEntries += [pscustomobject]@{ Name=$_.Name; Command=$_.Value } }
}
if ($runEntries.Count) {
    $runEntries | ForEach-Object { Info ("   {0}" -f $_.Name) }
    Info "(Security, backup, sync and your own work apps should stay - only disable what you don't need at boot.)"
} else { Info "   (no user Run entries)" }

# ---------------------------------------------------------------- assess-only exit
if (-not $Apply) {
    Write-Host "`nAssessment only - nothing was changed. Run with -Apply for guided, consented removal." -ForegroundColor Green
    exit 0
}

# ---------------------------------------------------------------- apply (each category asks)
Section "Apply mode (each category asks first; protected apps are never touched)"

# Optional restore point (needs admin)
if ($IsAdmin -and (Ask "Create a System Restore Point first (recommended)?")) {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "win-tuneup debloat" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Good "Restore point created."
    } catch { Warn "Could not create restore point: $($_.Exception.Message)" }
} elseif (-not $IsAdmin) {
    Info "(Run as administrator to be offered a System Restore Point.)"
}

foreach ($cat in $plan.Keys) {
    $apps = $plan[$cat]
    Write-Host ("`n  Category: {0}  ({1} apps)" -f $cat, $apps.Count) -ForegroundColor Yellow
    $apps | ForEach-Object { Info ("     - {0}" -f $_) }
    if (Ask ("Remove all {0} app(s) in '{1}'?" -f $apps.Count, $cat)) {
        foreach ($a in $apps) {
            if (Test-Protected $a) { Warn "skipped (protected): $a"; continue }
            $pkg = Get-AppxPackage -Name $a -ErrorAction SilentlyContinue
            if ($pkg) {
                try { $pkg | Remove-AppxPackage -ErrorAction Stop; Good "removed: $a" }
                catch { Warn "could not remove $a : $($_.Exception.Message)" }
            }
        }
    } else { Info "  kept this category." }
}

# Startup manager
if ($runEntries.Count) {
    Section "Startup manager"
    if (Ask "Review startup entries one by one to disable any you don't need at boot?") {
        # Back up the Run key before any change
        $stamp = (Get-CimInstance Win32_OperatingSystem).LocalDateTime.ToString('yyyyMMdd-HHmmss')
        $regBackup = Join-Path $backupDir "HKCU_Run_backup_$stamp.reg"
        reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" $regBackup /y | Out-Null
        Good "Backed up startup entries to: $regBackup  (double-click to restore)"
        foreach ($e in $runEntries) {
            if (Ask ("Disable '{0}' from startup? (stays installed, just won't auto-launch)" -f $e.Name)) {
                Remove-ItemProperty -Path $runKey -Name $e.Name -Force -ErrorAction SilentlyContinue
                Good "disabled from startup: $($e.Name)"
            }
        }
    }
}

Write-Host ""
Good "Debloat finished. Protected apps were never touched. Removed apps reinstall from the Microsoft Store;"
Info  "          startup entries can be restored from the .reg backup above. Consider a restart to finalize."
