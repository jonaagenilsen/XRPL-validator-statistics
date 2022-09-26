# Fetch statistics for XRPL node servers grabbed from (generated) output from Alloy.
#
# (C) Jon Nilsen (jonaagenilsen@gmail.com) 2022
# Free to use for whatever. I hold no grudges :).
#
#

#clear

$URL = "https://zstats.alloy.ee/mainnet/latest.json"
$web_client = new-object system.net.webclient

try {
  $Servers = $Web_client.DownloadString("$URL") | ConvertFrom-Json
}
catch {
}

if ($Servers) {
  Write-Host "Status of XRPL servers: " -NoNewline; Write-Host "$ReportTime" -NoNewline -ForegroundColor Green; Write-Host " CEST"
  Write-Host "Found $($Servers.total) servers in $($Servers.network) network:"
  Write-Host ""

  [pscustomobject]$ServerStatistics = @()
  
  foreach ($Server in $($Servers.nodes | Select-Object version -Unique)) {
    $ServerCount = ($Servers.nodes | Where-Object { $_.version -match "$($Server.version)" }).count
    $CurrentVersionCount = ($Servers.nodes | Where-Object { $_.version -match "$($Server.version)" }).count
    $CurrentVersionPercent = [math]::Round(($CurrentVersionCount * 100 / $Servers.total),1)

    $Object = [pscustomobject]@{
       version = $($Server.version)
       count = $ServerCount
       percent = $CurrentVersionPercent
    }
    $ServerStatistics += $Object
  }

  Write-Host "Servers sorted by version" -NoNewline
  $ServerStatistics | Select-Object * | Sort-Object version -Descending | ft #-HideTableHeaders
  
  Write-Host "Servers sorted by count" -NoNewline
  $ServerStatistics | Select-Object * | Sort-Object count -Descending | ft #-HideTableHeaders
}
else {
  Write-Host "*Display old man yelling at clouds"
}

#$CurrentVersionCount = ($ServerStatistics | Select-Object * -First 1).count
#$CurrentVersion = ($ServerStatistics | Select-Object * -First 1).version
#$CurrentVersionPercent = [math]::Round(($CurrentVersionCount * 100 / $Servers.total),1)
#Write-host "Servers upgraded to latest version $($CurrentVersion): $($CurrentVersionCount)/$($Servers.total) ($CurrentVersionPercent%)"
Write-Host "Source: @alloynetworks"

