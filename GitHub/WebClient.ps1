param([string]$Url, [string]$User, [string]$Token)
$pair = "$($User):$($Token)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuth = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuth
    Accept = "application/vnd.github.v3+json"
    "Accept-Charset" = "utf-8"
    "Content-Type" = "application/json; charset=utf-8"
}
$response = Invoke-WebRequest -Uri $Url -Headers $Headers 
$jsonCorrected = [Text.Encoding]::UTF8.GetString([Text.Encoding]::GetEncoding(65001).GetBytes($response.Content))
$json = $jsonCorrected | ConvertFrom-Json
return $json
