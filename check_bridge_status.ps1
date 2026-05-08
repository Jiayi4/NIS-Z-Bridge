param(
    [string]$LocalRoot = "E:\Jiayi\NISZBridge",
    [int]$RecentLogLines = 20
)

$commandDir = Join-Path $LocalRoot "commands"
$responseDir = Join-Path $LocalRoot "responses"
$stateDir = Join-Path $LocalRoot "state"
$processedDir = Join-Path $LocalRoot "processed"
$errorsDir = Join-Path $LocalRoot "errors"
$logPath = Join-Path $LocalRoot "nis_z_sync.log"
$hotkeyLogPath = Join-Path $LocalRoot "nis_z_macro_hotkey_runner.log"
$stopFile = Join-Path $LocalRoot "stop_hotkey_runner.txt"

function Show-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ==="
}

function Show-LatestFiles {
    param(
        [string]$Path,
        [int]$Count = 5
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "Missing: $Path"
        return
    }

    Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $Count Name, Length, LastWriteTime |
        Format-Table -AutoSize
}

function Show-CurrentTextFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "Not present: $Path"
        return
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        $clean = ($raw -replace [char]0, "").Trim()
        Write-Host "$Path => $clean"
    } catch {
        Write-Host "$Path => unreadable: $($_.Exception.Message)"
    }
}

Write-Host "Bridge status at $(Get-Date -Format s)"
Write-Host "Local root: $LocalRoot"

Show-Section "Processes"
$pythonBridge = Get-CimInstance Win32_Process -Filter "Name = 'python.exe'" |
    Where-Object { $_.CommandLine -like "*nis_z_sync_shared_to_local.py*" } |
    Select-Object ProcessId, Name, CommandLine

if ($pythonBridge) {
    $pythonBridge | Format-Table -AutoSize
} else {
    Write-Host "Sync process not found."
}

$powershellHotkey = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
    Where-Object { $_.CommandLine -like "*nis_z_macro_hotkey_runner.ps1*" } |
    Select-Object ProcessId, Name, CommandLine

if ($powershellHotkey) {
    $powershellHotkey | Format-Table -AutoSize
} else {
    Write-Host "Hotkey runner process not found."
}

if (Test-Path -LiteralPath $stopFile) {
    Write-Host "Stop file is present: $stopFile"
}

Show-Section "Commands"
Show-LatestFiles -Path $commandDir

Show-Section "Responses"
Show-LatestFiles -Path $responseDir
Show-CurrentTextFile -Path (Join-Path $responseDir "current_getz_response.txt")

Show-Section "State"
Show-LatestFiles -Path $stateDir
Show-CurrentTextFile -Path (Join-Path $stateDir "current_getz.id")
Show-CurrentTextFile -Path (Join-Path $stateDir "current_z.txt")

Show-Section "Processed"
Show-LatestFiles -Path $processedDir

Show-Section "Errors"
Show-LatestFiles -Path $errorsDir

Show-Section "Recent Sync Log"
if (Test-Path -LiteralPath $logPath) {
    Get-Content -LiteralPath $logPath -Tail $RecentLogLines
} else {
    Write-Host "Missing: $logPath"
}

Show-Section "Recent Hotkey Log"
if (Test-Path -LiteralPath $hotkeyLogPath) {
    Get-Content -LiteralPath $hotkeyLogPath -Tail $RecentLogLines
} else {
    Write-Host "Missing: $hotkeyLogPath"
}
