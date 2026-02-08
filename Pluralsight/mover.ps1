param([string]$SuffixPath)
$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$fileArray = Get-ChildItem -File -Path "$scriptDir\$SuffixPath"
$directoryArray = Get-ChildItem -Directory -Path "$scriptDir\$SuffixPath" -Exclude *.zip
$regexPrefix = "-m"
$regex = [regex]"$regexPrefix\d+-"
$fileArray | foreach 
{
    $match = $regex.Match($_.FullName)
    if ($match.Success) 
    {		
        $startIndex = $match.Index
        $subStringed = $_.FullName.Substring($startIndex + $regexPrefix.Length)
        $subStringed = $subStringed.Substring(0, $subStringed.IndexOf('-'))
        if ($subStringed.Length -eq 1) {
            $subStringed = "0$subStringed"
        }
        foreach ($directory in $directoryArray) 
        {			
            if ($directory.Name.StartsWith("$subStringed")) 
            {
                $joinedPath = Join-Path -Path $directory.FullName -ChildPath $_.Name
                Move-Item $_.FullName $joinedPath		
                break
            }
        }        
    }
}