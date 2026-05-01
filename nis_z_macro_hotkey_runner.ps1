param(
    [string]$WindowTitleContains = "NIS",
    [string]$RunHotkey = "{F4}",
    [int]$PollMilliseconds = 500,
    [int]$CooldownSeconds = 5
)

Add-Type -AssemblyName System.Windows.Forms

$ErrorActionPreference = "Stop"

$localRoot = "E:\Jiayi\NISZBridge"
$commandsDir = Join-Path $localRoot "commands"
$logPath = Join-Path $localRoot "nis_z_macro_hotkey_runner.log"
$stopPath = Join-Path $localRoot "stop_hotkey_runner.txt"

$wsh = New-Object -ComObject WScript.Shell
$lastTriggerAt = Get-Date "2000-01-01"
$lastTriggeredCommand = ""

function Write-RunnerLog {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $line = "$timestamp [HOTKEY] $Message"
    Add-Content -LiteralPath $logPath -Value $line
    Write-Host $line
}

function Get-PendingCommandFile {
    if (-not (Test-Path -LiteralPath $commandsDir)) {
        return $null
    }

    Get-ChildItem -LiteralPath $commandsDir -Filter *.txt -File |
        Sort-Object LastWriteTime, Name |
        Select-Object -First 1
}

function Get-NisWindowProcess {
    Get-Process |
        Where-Object {
            $_.MainWindowHandle -ne 0 -and
            $_.MainWindowTitle -and
            $_.MainWindowTitle -like "*$WindowTitleContains*"
        } |
        Sort-Object StartTime -Descending |
        Select-Object -First 1
}

Write-RunnerLog "Starting macro hotkey runner. WindowTitleContains='$WindowTitleContains' Hotkey='$RunHotkey'"
Write-RunnerLog "Create '$stopPath' to stop this runner cleanly."

while ($true) {
    if (Test-Path -LiteralPath $stopPath) {
        Remove-Item -LiteralPath $stopPath -Force
        Write-RunnerLog "Stop file detected. Exiting."
        break
    }

    $pending = Get-PendingCommandFile
    if ($null -ne $pending) {
        $now = Get-Date
        $secondsSinceTrigger = ($now - $lastTriggerAt).TotalSeconds
        $commandKey = $pending.FullName + "|" + $pending.LastWriteTimeUtc.Ticks

        if ($commandKey -ne $lastTriggeredCommand -or $secondsSinceTrigger -ge $CooldownSeconds) {
            $nisProcess = Get-NisWindowProcess
            if ($null -ne $nisProcess) {
                if ($wsh.AppActivate($nisProcess.Id)) {
                    Start-Sleep -Milliseconds 250
                    [System.Windows.Forms.SendKeys]::SendWait($RunHotkey)
                    $lastTriggerAt = $now
                    $lastTriggeredCommand = $commandKey
                    Write-RunnerLog "Triggered NIS pid=$($nisProcess.Id) title='$($nisProcess.MainWindowTitle)' for pending command '$($pending.Name)'"
                } else {
                    Write-RunnerLog "Found NIS process but could not activate pid=$($nisProcess.Id) title='$($nisProcess.MainWindowTitle)'"
                }
            } else {
                Write-RunnerLog "No NIS window found containing '$WindowTitleContains'"
            }
        }
    }

    Start-Sleep -Milliseconds $PollMilliseconds
}
