. .\Shared-Functions.ps1 

$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

function IsDockerRunning {
    & docker info 2>&1 | Out-Null
    return $LASTEXITCODE -eq 0
}

function IsDockerDesktopProcessRunning {
    return $null -ne (Get-Process "Docker Desktop" -ErrorAction SilentlyContinue)
}

if (IsDockerRunning) {
    Write-Log "Docker is already running." $null "INFORMATION"
    return
}

if (-not (IsDockerDesktopProcessRunning)) {
    Write-Log "Starting Docker Desktop..." $null "WARNING"
    Start-Process $dockerPath
} else {
    Write-Log "Docker Desktop already open, waiting for engine..." $null "WARNING"
}

$timeout = 120
$elapsed = 0

do {
    Start-Sleep -Seconds 5
    $elapsed += 5
    Write-Log "Still waiting... ($elapsed s / $timeout s)" $null "INFORMATION"
} while (-not (IsDockerRunning) -and $elapsed -lt $timeout)

if (IsDockerRunning) {
    Write-Log "Docker is ready!" $null "INFORMATION"
} else {
    Write-Log "Timed out. Try restarting Docker Desktop manually." $null "ERROR"
}