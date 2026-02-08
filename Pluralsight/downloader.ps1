param([string]$CourseUrl,[string]$SuffixPath,[int]$PlaylistStart=1,[bool]$SubsOnly=0)
$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
if ($SuffixPath -ne $null) 
{ 
	$scriptDir = Join-Path -Path $scriptDir -ChildPath "$SuffixPath\" 
}
$additionalOptions = [string]::Empty
if ($SubsOnly -eq 1) 
{ 
	$additionalOptions = -join($additionalOptions, "--skip-download") 
}
.\youtube-dl.exe "$CourseUrl" --output "$scriptDir%(playlist_title)s\%(autonumber)003d %(title)s.%(ext)s" --all-subs --username "" --password "" -r 5.0M --verbose --sleep-interval 120 $additionalOptions --playlist-start "$PlaylistStart" -f best --no-cache-dir
.\crawler.ps1 -CourseUrl $CourseUrl
