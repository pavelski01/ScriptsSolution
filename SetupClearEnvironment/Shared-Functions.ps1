function Write-Log {
    param([string]$Message, [string]$LogFile = $null, [string]$Level = "INFORMATION")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFORMATION" { "Green" }
        default { "Cyan" }
    }

    if ([string]::IsNullOrEmpty($LogFile)) {
        Write-Host $entry -ForegroundColor $color
    }
    else {
        Tee-Object -InputObject $entry -FilePath $LogFile -Append
    }
}

function Invoke-SqlQuery {
    param([string]$Query, [string]$ServerInstance, [string]$Database = "master", [string]$LogFile = $null)
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $command.CommandTimeout = 60
        $command.ExecuteNonQuery() | Out-Null
        $connection.Close()
        return $true
    }
    catch {
        Write-Log "SQL error: $_"  $LogFile "ERROR"
        if ($connection.State -eq [System.Data.ConnectionState]::Open) { $connection.Close() }
        return $false
    }
}

function Confirm-Deletion {
    param([string]$ResourceType, [string]$ResourceName, [string]$LogFile = $null)
    Write-Log "WARNING: This will PERMANENTLY delete the $ResourceType '$ResourceName'!" $LogFile "WARNING"
    Write-Log "This action cannot be undone." $LogFile "WARNING"
    $confirm = Read-Host "  Type the $ResourceType name to confirm"
    return ($confirm -eq $ResourceName)
}

function Install-RequiredModule {
    param([string]$ModuleName, [string]$LogFile = $null)
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Log "Installing module '$ModuleName'..." $LogFile "WARNING"
        try {
            Install-Module -Name $ModuleName -Force -Scope CurrentUser -Repository PSGallery
            Write-Log "Module '$ModuleName' installed." $LogFile "INFORMATION"
        }
        catch {
            Write-Log "Failed to install '$ModuleName': $_" $LogFile "ERROR"
            exit 1
        }
    }
    Import-Module $ModuleName -ErrorAction Stop
}