param([int]$StartIndex=1,[string]$SuffixPath="*")
$index = $StartIndex
$items = Get-ChildItem $SuffixPath -Filter *.mp4 | Sort-Object -Property Name
foreach ($item in $items) 
{    
    $indexS = ""
    if ($index -lt 10)
    {
        $indexS = "00"
    }
    elseif ($index -lt 100)
    {
        $indexS = "0"
    }
    $indexS += $index
    $newName = $indexS + " " + $item.Name.Substring(4)
    Rename-Item -Path $item.FullName -NewName $newName
    $index++
}
$items = Get-ChildItem $SuffixPath -Filter *.srt | Sort-Object -Property Name
$index = $StartIndex
foreach ($item in $items) 
{    
    $indexS = ""
    if ($index -lt 10)
    {
        $indexS = "00"
    }
    elseif ($index -lt 100)
    {
        $indexS = "0"
    }
    $indexS += $index
    $newName = $indexS + " " + $item.Name.Substring(4)
    Rename-Item -Path $item.FullName -NewName $newName
    $index++
}