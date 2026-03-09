. .\Shared-Functions.ps1
$dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
if ($dockerService.Status -ne 'Running') {
    Write-Log "Docker is not running. Starting Docker Desktop..." $null "WARNING"
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    Write-Log "Waiting for Docker to be ready..." $null "WARNING"
    $timeout = 60
    $elapsed = 0

    do {
        Start-Sleep -Seconds 3
        $elapsed += 3
        $ready = docker info 2>$null
    } while (-not $ready -and $elapsed -lt $timeout)

    if ($ready) {
        Write-Log "Docker is ready!" $null "INFO"
    } else {
        Write-Log "Timed out waiting for Docker." $null "ERROR"
    }
} else {
    Write-Log "Docker is already running." $null "INFO"
}