using namespace "System.Collections.Generic"
<# 
    Usage: 
        .\GitHub.ps1 
            -Login '<GitHub login>'
            -Token '<GitHub token>'
            -Owner '<owner>'
            -Repo '<repository>'
            -Author '<commit author>'
            -Date '<date from>'
    
    Example:
        .\GitHub.ps1 
            -Login 'test'
            -Token '***'
            -Owner 'Microsoft'
            -Repo 'CodeCamp'
            -Author 'john.smith@gmail.com'
            -Date ([DateTime]::Today.AddDays(-1))
#>
param(
    [string]$Login, [string]$Token, 
    [string]$Owner, [string]$Repo, 
    [string]$Author="pavelski01@gmail.com", [DateTime]$Date=[DateTime]::Today
)
$since = Get-Date -Date $Date.Date -Format 'yyyy-MM-ddT00:00:00Z'
$url = "https://api.github.com/repos/$($Owner)/$($Repo)/branches?per_page=100"
$branchesJson = &".\WebClient.ps1" -Url $url -User $Login -Token $Token
$dict = [dictionary[string, list[string]]]::new()
$page = 1
$branchesJson.ForEach({
    $url = "https://api.github.com/repos/$($Owner)/$($Repo)/commits?sha=$($_.commit.sha)&author=$($Author)&since=$($since)&sort=pushed&per_page=100&page$($page)"
    $commitsJson = &".\WebClient.ps1" -Url $url -User $Login -Token $Token | Foreach-Object {
        $hash = [ordered]@{}
        $_.PsObject.Properties | Foreach-Object { 
            $hash[$_.Name] = $_.Value
        }
        $hash
    }
    if ($commitsJson -eq $null) { return }
    $key = $_.name
    $dict.Add($key, [list[string]]::new())
    $commitsJson.ForEach({
        $commitDate = [DateTime]$_.commit.committer.date
        if ($commitDate.Date -gt $Date.Date) { return }
        $message = $_.commit.message
        if ($message -like "Merge branch*") { return }
        $splitted = $message.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries) 
        if ($splitted.Length -eq 2) {
            $message = "$($splitted[0]) ($($splitted[1]))"
        }
        $dict[$key].Add($message)
    })
    $page++
    if ($commitsJson.Length -ge 100) { return }
})
$dict.GetEnumerator() | ForEach-Object {
    if (([list[string]]$_.Value).Count -le 0) { return }
    $_.Value.Reverse()
    Write-Host "$($_.Key) - $($_.Value -join '; ')`n`r"
}