<#
.SYNOPSIS
    Sets up the local development environment by starting necessary services and cleaning up existing resources.

.PARAMETER ServerInstance
    The SQL Server instance name (e.g., "localhost" or "SERVER\SQLEXPRESS")

.PARAMETER DatabaseName
    Name of the database to delete before setup

.PARAMETER AzureStorageConnectionString
    Azure Storage Account connection string

.PARAMETER MigrationProjectPath
    Path to the Entity Framework Core migration project

.EXAMPLE
    .\Setup-Environment.ps1 -ServerInstance "localhost" -DatabaseName "MyDatabase" -AzureStorageConnectionString "UseDevelopmentStorage=true" -MigrationProjectPath ".\MyProject.Migrations"
#>

param (
    [string]$ServerInstance = "(localdb)\mssqllocaldb",
    [string]$AzureStorageConnectionString = "UseDevelopmentStorage=true",

    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,

    [Parameter(Mandatory = $true)]
    [string]$MigrationProjectPath
)

. .\Shared-Functions.ps1 
.\DockerDesktop-Lunch.ps1
$stackName = "azurite-stack"
$existing = docker compose -p $stackName ps --quiet 2>$null
if (-not $existing) {
	Write-Log "Starting stack '$stackName'" $null "INFORMATION"
    docker compose -f .\azurite-compose.yaml up -d
}
.\Delete-Database.ps1 -ServerInstance $ServerInstance -DatabaseName $DatabaseName -Force
.\Delete-AzureStorage.ps1 -ConnectionString $AzureStorageConnectionString -TableName OrleansSiloInstances -Force
.\Delete-AzureStorage.ps1 -ConnectionString $AzureStorageConnectionString -TableName OrleansReminders -Force
.\Delete-AzureStorage.ps1 -ConnectionString $AzureStorageConnectionString -TableName OrleansGrainState -Force
.\Delete-AzureStorage.ps1 -ConnectionString $AzureStorageConnectionString -ContainerName grainstate -Force
dotnet user-secrets remove "ConnectionStrings:DefaultConnection" --project $MigrationProjectPath
dotnet ef database update --startup-project $MigrationProjectPath -- "DefaultConnection"