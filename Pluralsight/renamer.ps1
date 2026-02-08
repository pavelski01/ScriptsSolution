param([string]$SuffixPath)
$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$fileArray = Get-ChildItem -Filter *.mp4 -File -Path "$scriptDir\$SuffixPath"
$fileArray | foreach 
{    
    $lastIndex = $_.FullName.LastIndexOf('\') + 1
    $firstPart = $_.FullName.Substring(0, $lastIndex)
    $secondPart = $_.FullName.Substring($lastIndex)
    $lastDot = $secondPart.LastIndexOf(".") + 1
    $lastHyphen = $secondPart.LastIndexOf("-") + 1
    $prefix = $secondPart.Substring($lastHyphen, $lastDot - $lastHyphen - 1)
    if ($prefix.Length -eq 1) 
    {
        $prefix = "0$prefix"
    }
    Rename-Item $_.FullName "$firstPart$prefix $secondPart"
}