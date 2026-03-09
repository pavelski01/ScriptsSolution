.\DockerDesktopConditionalLunch.ps1
$stackName = "azurite-stack"
$existing = docker compose -p $stackName ps --quiet 2>$null
if (-not $existing) {
	Write-Host "Starting stack '$stackName'" -ForegroundColor Green
    docker compose -f .\compose.yaml up -d
}
.\Delete-Database.ps1 -ServerInstance "(localdb)\mssqllocaldb" -DatabaseName aspnet-53bc9b9d-9d6a-45d4-8429-2a2761773502 -Force
.\Delete-AzureStorage.ps1 -ConnectionString "UseDevelopmentStorage=true" -TableName OrleansSiloInstances -Force
.\Delete-AzureStorage.ps1 -ConnectionString "UseDevelopmentStorage=true" -TableName OrleansReminders -Force
.\Delete-AzureStorage.ps1 -ConnectionString "UseDevelopmentStorage=true" -TableName OrleansGrainState -Force
.\Delete-AzureStorage.ps1 -ConnectionString "UseDevelopmentStorage=true" -ContainerName grainstate -Force
dotnet ef database update --project .\GloboTicket\GloboTicket.App\GloboTicket.App.csproj --startup-project .\GloboTicket\GloboTicket.App\GloboTicket.App.csproj