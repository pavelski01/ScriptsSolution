<#
.SYNOPSIS
    Deletes an Azure Blob Container and Azure Table Storage table.

.PARAMETER ConnectionString
    Azure Storage Account connection string

.PARAMETER ContainerName
    Name of the blob container to delete

.PARAMETER TableName
    Name of the table to delete

.PARAMETER WithFileLog
    Enable logging to a file path

.PARAMETER Force
    Skip confirmation prompt

.EXAMPLE
    .\Delete-AzureStorage.ps1 `
        -ConnectionString "DefaultEndpointsProtocol=https;AccountName=..." `
        -ContainerName "my-blob-container" `
        -TableName "my-table" `
        -WithFileLog `
        -Force
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$ConnectionString,

    [Parameter(Mandatory = $false)]
    [string]$ContainerName,

    [Parameter(Mandatory = $false)]
    [string]$TableName,

    [switch]$WithFileLog,

    [switch]$Force
)

. .\Shared-Functions.ps1

$LogFile = if ($WithFileLog) { ".\DeleteAzureStorage_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" } else { $null }

if (-not $ContainerName -and -not $TableName) {
    Write-Log "You must specify at least one of -ContainerName or -TableName." $LogFile "ERROR"
    exit 1
}

Install-RequiredModule "Az.Storage"

try {
    $context = New-AzStorageContext -ConnectionString $ConnectionString
    Write-Log "Connected to storage account: '$($context.StorageAccountName)'" $LogFile "INFORMATION"
}
catch {
    Write-Log "Failed to create storage context: $_" $LogFile "ERROR"
    exit 1
}

if ($ContainerName) {
    try {
        $container = Get-AzStorageContainer -Name $ContainerName -Context $context -ErrorAction Stop
    }
    catch {
        Write-Log "Blob container '$ContainerName' not found. Skipping." $LogFile "WARNING"
        $container = $null
    }

    if ($container) {
        try {
            $blobCount = (Get-AzStorageBlob -Container $ContainerName -Context $context).Count
            Write-Log "Container contains $blobCount blob(s)." $LogFile "WARNING"
        }
        catch {
            Write-Log "Could not retrieve blob count." $LogFile "WARNING"
        }

        $proceed = $Force -or (Confirm-Deletion -ResourceType "container" -ResourceName $ContainerName)
        if ($proceed) {
            Write-Log "Deleting blob container '$ContainerName'..." $LogFile "INFORMATION"
            try {
                Remove-AzStorageContainer -Name $ContainerName -Context $context -Force
                Write-Log "Blob container '$ContainerName' deleted successfully." $LogFile "INFORMATION"
            }
            catch {
                Write-Log "Failed to delete container '$ContainerName': $_" $LogFile "ERROR"
            }
        }
        else {
            Write-Log "Deletion of container '$ContainerName' cancelled by user." $LogFile "WARNING"
        }
    }
}

if ($TableName) {
    try {
        $table = Get-AzStorageTable -Name $TableName -Context $context -ErrorAction Stop
    }
    catch {
        Write-Log "Table '$TableName' not found. Skipping." $LogFile "WARNING"
        $table = $null
    }

    if ($table) {
        $proceed = $Force -or (Confirm-Deletion -ResourceType "table" -ResourceName $TableName)

        if ($proceed) {
            try {
                Remove-AzStorageTable -Name $TableName -Context $context -Force
                Write-Log "Table '$TableName' deleted successfully." $LogFile "INFORMATION"
            }
            catch {
                Write-Log "Failed to delete table '$TableName': $_" $LogFile "ERROR"
            }
        }
        else {
            Write-Log "Deletion of table '$TableName' cancelled by user." $LogFile "WARNING"
        }
    }
}