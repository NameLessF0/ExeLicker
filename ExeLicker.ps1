# Start
Write-Host "Little Bypass by NameLessF0" -ForegroundColor Magenta
Write-Host "GitHub: https://github.com/NameLessF0" -ForegroundColor White
Write-Host "Discord: https://discord.gg/k7hcQKRXQt" -ForegroundColor Blue
Write-Host "`nRunning the script..." -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red
Write-Host " " -ForegroundColor Red

# 1. Configuration & Keywords
$cheatKeywords = @(
    "Vape", "Rise", "Prestige", "Doomsday", "LiquidBounce", "MouseMacro", 
    "Impact", "Wurst", "Sigma", "Aristois", "Kami Blue", "Satella", 
    "Ghost", "Meteor", "Skilled", "KillAura", "Bloody", "Razer", 
    "Macro", "AimAssist", "AutoClicker", "Velocity", "ESP", "Xray",
    "AutoTotem", "AutoClick", "JumpReset", "SilentAura", "FlyHack"
)

$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$executionHistory = @()

Write-Host "`n[+] System Boot Since $bootTime" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"

# --- PHASE 1: EVENT LOGS (Security & PCA) ---
Write-Host "[1/4] Scanning..." -ForegroundColor Gray
try {
    $secEvents = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4688; StartTime=$bootTime} -ErrorAction SilentlyContinue
    foreach ($event in $secEvents) {
        $xml = [xml]$event.ToXml()
        $procName = ($xml.Event.EventData.Data | Where-Object { $_.Name -eq "NewProcessName" }).'#text'
        if ($procName -and $procName -like "*.exe") {
            $executionHistory += [PSCustomObject]@{
                Timestamp = $event.TimeCreated
                ExeName   = [System.IO.Path]::GetFileName($procName)
                FullPath  = $procName
                Source    = "EventLog"
            }
        }
    }
    $pcaEvents = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Application-Experience/Program-Telemetry'; StartTime=$bootTime} -ErrorAction SilentlyContinue
    foreach ($event in $pcaEvents) {
        $executionHistory += [PSCustomObject]@{
            Timestamp = $event.TimeCreated
            ExeName   = "PCA-Activity"
            FullPath  = $event.Message
            Source    = "PCA-Telemetry"
        }
    }
} catch { Write-Host "[!] Access Denied to Security Logs." -ForegroundColor Yellow }

# --- PHASE 2: PREFETCH ANALYSIS ---
Write-Host "[2/4] Scanning..." -ForegroundColor Gray
$prefetchPath = "$env:SystemRoot\Prefetch"
if (Test-Path $prefetchPath) {
    $prefetchFiles = Get-ChildItem -Path $prefetchPath -Filter *.pf | Where-Object { $_.LastWriteTime -gt $bootTime }
    foreach ($pf in $prefetchFiles) {
        $cleanName = ($pf.Name -split "-")[0] + ".exe"
        if ($executionHistory.ExeName -notcontains $cleanName) {
            $executionHistory += [PSCustomObject]@{
                            Timestamp = $pf.LastWriteTime
                ExeName   = $cleanName
                FullPath  = "Prefetch: $($pf.FullName)"
                Source    = "Prefetch"
            }
        }
    }
}

# --- PHASE 3: SHIMCACHE & AMCACHE (Registry Traces) ---
Write-Host "[3/4] Scanning..." -ForegroundColor Gray
try {
    $shimPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache"
    if (Test-Path $shimPath) {
        $executionHistory += [PSCustomObject]@{ Timestamp = $bootTime; ExeName = "ShimCache-Metadata"; FullPath = $shimPath; Source = "ShimCache" }
    }
    $amcachePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts"
    if (Test-Path $amcachePath) {
        $executionHistory += [PSCustomObject]@{ Timestamp = $bootTime; ExeName = "Amcache-Metadata"; FullPath = $amcachePath; Source = "Amcache" }
    }
} catch { Write-Host "[!] Registry access denied." -ForegroundColor Yellow }

# --- PHASE 4: FINAL CLEAN REPORTING ---
Write-Host "[4/4] Scanning..." -ForegroundColor Gray
Write-Host "--------------------------------------------------------------------------------"

if ($executionHistory.Count -eq 0) {
    Write-Host "[?] No execution traces found since boot." -ForegroundColor Yellow
} else {
    $sortedHistory = $executionHistory | Sort-Object Timestamp -Descending

    # Header
    Write-Host ("{0,-20} | {1,-30} | {2}" -f "TIMESTAMP", "APPLICATION NAME", "PATH / SOURCE") -ForegroundColor White
    Write-Host ("-" * 85) -ForegroundColor Gray

    foreach ($item in $sortedHistory) {
        $isSuspicious = $false
        foreach ($word in $cheatKeywords) {
            if ($item.ExeName -match $word -or $item.FullPath -match $word) {
                $isSuspicious = $true
                break
            }
        }

        if ($isSuspicious) {
            # "BOLD" EFFECT: BrightRed + Prefix
            $nameDisplay = "[!] " + $item.ExeName
            $line = "{0,-20} | {1,-30} | {2}" -f $item.Timestamp.ToString("HH:mm:ss"), $nameDisplay, $item.FullPath
            Write-Host $line -ForegroundColor Red
        } else {
            # NORMAL: White/Gray
            $nameDisplay = $item.ExeName
            $line = "{0,-20} | {1,-30} | {2}" -f $item.Timestamp.ToString("HH:mm:ss"), $nameDisplay, $item.FullPath
            Write-Host $line -ForegroundColor White
        }
    }
}

Write-Host "--------------------------------------------------------------------------------"
Write-Host "[*] Scan Complete." -ForegroundColor Cyan
