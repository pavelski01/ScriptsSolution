param([string]$CourseUrl, [string]$Suffix=$null)
$CourseUrl = $CourseUrl.Substring(0, $CourseUrl.LastIndexOf('/'))
$courseName = $CourseUrl.Substring($CourseUrl.LastIndexOf('/') + 1)
$requestUrl = "https://app.pluralsight.com/learner/content/courses/$($courseName)"
[Net.ServicePointManager]::Expect100Continue  = $true
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$jsonResponse = Invoke-WebRequest -Uri $requestUrl | ConvertFrom-Json
$courseTitle = $jsonResponse | select title -ExpandProperty title
$courseTitle = $courseTitle.Replace(":", " -")
$modules = $jsonResponse | select modules -ExpandProperty modules
$dict = [system.collections.generic.dictionary[string,string[]]]::new()
$videoCounter = 0
foreach ($clip in $modules.clips)
{
    $moduleTitle = $clip.moduleTitle.Replace(':', ' -').Replace('?', '').Trim()
    if ($dict[$moduleTitle] -eq $null)
    {
        $dict.Add($moduleTitle, @())
    }
    $clipTitle = $clip.title.Replace(':', ' -').Replace('?', '').Trim()
    $dict[$moduleTitle] += $clipTitle
    $videoCounter++
}
$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$scriptDirPath = "$scriptDir$courseTitle"
if ($Suffix -ne $null)
{
    $scriptDirPath = "$scriptDir\$Suffix\$courseTitle"
}
$allDirectories = Get-ChildItem -Directory -Path $scriptDirPath | select -Property Name -ExpandProperty Name
$fileCounter = 0
foreach ($dir in $allDirectories)
{
    $allFiles = Get-ChildItem -File -Filter *.mp4 -Path $scriptDirPath\$dir | select -Property Name -ExpandProperty Name
    foreach ($file in $allFiles)
    {
        $fileCounter++
    }
}
if ($fileCounter -ne $videoCounter)
{
    return $false
}
else
{
    return $true
}