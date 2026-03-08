<#
.SYNOPSIS
    Deletes a SQL Server database safely with connection cleanup and confirmation.

.PARAMETER ServerInstance
    The SQL Server instance name (e.g., "localhost" or "SERVER\SQLEXPRESS")

.PARAMETER DatabaseName
    The name of the database to delete

.PARAMETER WithFileLog
    Enable logging to a file path

.PARAMETER Force
    Skip the confirmation prompt

.EXAMPLE
    .\Delete-Database.ps1 -ServerInstance "localhost" -DatabaseName "MyDatabase"
    .\Delete-Database.ps1 -ServerInstance "localhost" -DatabaseName "MyDatabase" -Force
    .\Delete-Database.ps1 -ServerInstance "localhost" -DatabaseName "MyDatabase" -WithFileLog -Force
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,

    [switch]$WithFileLog,

    [switch]$Force
)

. .\Shared-Functions.ps1 

$LogFile = if ($WithFileLog) { ".\DeleteDatabase_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" } else { $null }

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=$ServerInstance;Database=master;Integrated Security=True;"
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT COUNT(*) FROM sys.databases WHERE name = @dbName"
    $command.Parameters.AddWithValue("@dbName", $DatabaseName) | Out-Null
    $exists = [int]$command.ExecuteScalar()
    $connection.Close()
}
catch {
    Write-Log "Cannot connect to SQL Server: $_"  $LogFile "ERROR"
    exit 1
}

if ($exists -eq 0) {
    Write-Log "Database '$DatabaseName' not found on '$ServerInstance'." $LogFile "WARNING"
    exit 0
}
Write-Log "Database '$DatabaseName' found." $LogFile "INFORMATION"

if ($Force -or (Confirm-Deletion -ResourceType "database" -ResourceName $DatabaseName)) {
    $killQuery = "ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;"
    if (-not (Invoke-SqlQuery -ServerInstance $ServerInstance -Query $killQuery)) {
        Write-Log "Failed to close connections. Aborting." $LogFile "ERROR"
        exit 1
    }
    Write-Log "Active connections to '$DatabaseName' closed." $LogFile "INFORMATION"

    $dropQuery = "DROP DATABASE [$DatabaseName];"
    if (Invoke-SqlQuery -ServerInstance $ServerInstance -Query $dropQuery) {
        Write-Log "Database '$DatabaseName' dropped successfully." $LogFile "INFORMATION"
    } else {
        Write-Log "Failed to drop database." $LogFile "ERROR"
        exit 1
    }
    exit 0
}
Write-Log "Confirmation failed. Aborting." $LogFile "WARNING"