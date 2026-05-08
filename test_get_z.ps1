param(
    [string]$SharedRoot = "\\sti-nas1.rcp.epfl.ch\bios\bios-raw\backups\visible\cell\Jiayi_bios-raw\Z control shared",
    [int]$TimeoutSeconds = 90,
    [int]$PollSeconds = 1,
    [int]$ReadRetryMilliseconds = 500
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$suffix = [guid]::NewGuid().ToString("N").Substring(0, 8)
$id = "test_${timestamp}_$suffix"

$commandDir = Join-Path $SharedRoot "commands"
$responseDir = Join-Path $SharedRoot "responses"
$commandPath = Join-Path $commandDir "$id.txt"
$responsePath = Join-Path $responseDir "$id.txt"

Write-Host "Testing GET_Z through shared bridge"
Write-Host "Request id: $id"
Write-Host "Command path: $commandPath"
Write-Host "Response path: $responsePath"

Set-Content -LiteralPath $commandPath -Value "GET_Z" -Encoding ascii
Write-Host "Command sent at $(Get-Date -Format s)"

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    if (Test-Path -LiteralPath $responsePath) {
        try {
            $response = Get-Content -LiteralPath $responsePath -Raw -ErrorAction Stop
            $cleanResponse = $response.Replace([char]0, "").Trim()
            Write-Host "Response received at $(Get-Date -Format s)"
            Write-Host $cleanResponse
            exit 0
        } catch {
            Write-Host "Response file exists but is still locked; retrying..."
            Start-Sleep -Milliseconds $ReadRetryMilliseconds
            continue
        }
    }

    Start-Sleep -Seconds $PollSeconds
}

Write-Host "Timed out after $TimeoutSeconds seconds waiting for $responsePath"
exit 1
