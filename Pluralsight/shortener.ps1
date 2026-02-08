param([string]$CourseUrl, [string]$Suffix=$null)
$flag = .\checker.ps1 -CourseUrl $CourseUrl -Suffix $Suffix | select -Last 1
$flag = $true
if ($flag -eq $true)
{
    $CourseUrl = $CourseUrl.Substring(0, $CourseUrl.LastIndexOf('/'))
    $courseName = $CourseUrl.Substring($CourseUrl.LastIndexOf('/') + 1)
    $requestUrl = "https://app.pluralsight.com/learner/content/courses/$($courseName)"
    [Net.ServicePointManager]::Expect100Continue  = $true
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $jsonResponse = Invoke-WebRequest -Uri $requestUrl | ConvertFrom-Json
    $courseTitle = $jsonResponse | select title -ExpandProperty title
    $courseTitle = $courseTitle.Replace(":", " -")
    $modules = $jsonResponse | select modules -ExpandProperty modules
    $videoDict = [system.collections.generic.dictionary[string,string[]]]::new()
    $videoCounter = 0
    foreach ($clip in $modules.clips)
    {
        $moduleTitle = $clip.moduleTitle.Replace(':', ' -').Replace('?', '').Trim()
        if ($videoDict[$moduleTitle] -eq $null)
        {
            $videoDict.Add($moduleTitle, @())
        }
        $clipTitle = $clip.title.Replace(':', ' -').Replace('?', '').Trim()
        $videoDict[$moduleTitle] += $clipTitle
        $videoCounter++
    }
    $scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
    $scriptDirPath = "$scriptDir$courseTitle"
    if ($Suffix -ne $null)
    {
        $scriptDirPath = "$scriptDir\$Suffix\$courseTitle"
    }
    $allDirectories = Get-ChildItem -Directory -Path $scriptDirPath | select -Property Name -ExpandProperty Name
    $fileDict = [system.collections.generic.dictionary[string,string[]]]::new()
    $fileCounter = 0
    foreach ($dir in $allDirectories)
    {
        if ($fileDict[$dir] -eq $null)
        {
            $fileDict.Add($dir, @())
        }
        $allFiles = Get-ChildItem -File -Filter *.mp4 -Path $scriptDirPath\$dir | select -Property Name -ExpandProperty Name
        foreach ($file in $allFiles)
        {
            $fileDict[$dir] += $file
            $fileCounter++
        }
    }
    foreach ($kvp in $fileDict.GetEnumerator())
    {
        $index = 0
        foreach ($valueAsFile in $kvp.Value)
        {
            $keyAsDirectory = $kvp.Key
            $keyAsVideo = $keyAsDirectory.Substring(3)
            $patternToSearch = $videoDict[$keyAsVideo][$index]
            $filePath = "$scriptDirPath\$keyAsDirectory\$valueAsFile"
            $isPatternFound = $valueAsFile.IndexOf($patternToSearch)
            if ($isPatternFound -gt -1)
            {
                $autoNumber = $valueAsFile.Substring(0, 4)
                $newName = $autoNumber + $patternToSearch + '.mp4'                
                Rename-Item -Path $filePath -NewName $newName      
				$srtPath = $filePath.Substring(0, $filePath.Length - 4) + '.en.srt'
                $isSrtExist = Test-Path $srtPath
                if ($isSrtExist -eq $true)
                {                    
                    $srtFile = Get-ChildItem -File -Filter $autoNumber*.en.srt -Path $scriptDirPath\$dir | select -Property Name -ExpandProperty Name -First 1
                    $filePath = "$scriptDirPath\$keyAsDirectory\$srtFile"
                    $newName = $autoNumber + $patternToSearch + '.en.srt'
                    Rename-Item -Path $srtPath -NewName $newName
                }
            }
            $index++
        }
    }
}
