# Usage:
#   .\sha256-dictionary-attack.ps1 -Hash "<sha256_hash>" -Wordlist ".\wordlist.txt"
#
# Examples:
#   .\sha256-dictionary-attack.ps1 -Hash "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8" -Wordlist .\rockyou.txt -ThrottleLimit 24
#
# Parameters:
#  -Hash [string] Target SHA256 hash (mandatory)
#  -Wordlist [string] Path to wordlist file (mandatory)
#  -ThrottleLimit [int] Number of parallel threads (default: 12)

using namespace System.Threading
using namespace System.Collections.Concurrent
using namespace System

param (
    [Parameter(Mandatory=$true)][string]$Hash,
    [Parameter(Mandatory=$true)][string]$Wordlist,
    [int]$ThrottleLimit = 12
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Error: PowerShell 7 or later is required. Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    exit 1
}

$target = $Hash.ToLower().Trim()
Write-Host "Target: $target"
Write-Host "Wordlist: $Wordlist"
Write-Host "Threads: $ThrottleLimit"
Write-Host

if (-not (Test-Path $Wordlist)) { throw "Wordlist not found" }

$found = [ConcurrentBag[string]]::new()
$cancellationTokenSource = [CancellationTokenSource]::new()
$stopWatch = [Diagnostics.Stopwatch]::StartNew()

Get-Content $Wordlist -ReadCount 5000 | ForEach-Object -Parallel {
    $localTarget = $using:target
    $localFound  = $using:found
    $localCancellationTokenSource = $using:cancellationTokenSource

    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    $_ | ForEach-Object {
        if ($localCancellationTokenSource.Token.IsCancellationRequested) {
            break
        }

        $word = $_.Trim()
        if ($word -eq '') { continue }

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($word)
        $hash = $sha256.ComputeHash($bytes)
        $hashHex = [BitConverter]::ToString($hash).Replace("-","").ToLower()

        if ($hashHex -eq $localTarget) {
            $null = $localFound.Add($word)
            $localCancellationTokenSource.Cancel()
            break
        }
    }
} -ThrottleLimit $ThrottleLimit

$cancellationTokenSource.Dispose()

$stopWatch.Stop()

if ($found.Count -gt 0) {
    Write-Host
    Write-Host "PASSWORD FOUND!" -ForegroundColor Green
    Write-Host "Password:" -NoNewline
    Write-Host $found[0] -ForegroundColor Cyan
} else {
    Write-Host "Not found." -ForegroundColor Yellow
}
    Write-Host "Time: $($stopWatch.Elapsed.ToString('hh\:mm\:ss\.fff'))"