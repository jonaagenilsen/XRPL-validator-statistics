# Fetch statistics for XRPL node servers grabbed from (generated) output from Alloy.
#
# (C) Jon Nilsen (jonaagenilsen@gmail.com) 2022
# Free to use for whatever. I hold no grudges :).
#
#

clear

$URL = "https://zstats.alloy.ee/mainnet/latest.json"
$web_client = new-object system.net.webclient

try {
  $Servers = $Web_client.DownloadString("$URL") | ConvertFrom-Json
}
catch {
}

if ($Servers) {
  Write-Host "Found $($Servers.total) in $($Servers.network) network:"

  [pscustomobject]$ServerStatistics = @()
  
  foreach ($Server in $($Servers.nodes | Select-Object version -Unique)) {
    $ServerCount = ($Servers.nodes | Where-Object { $_.version -match "$($Server.version)" }).count

    $Object = [pscustomobject]@{
       version = $($Server.version)
       count = $ServerCount
    }
    $ServerStatistics += $Object
  }
}

Write-Output ""
Write-Output "Servers sorted by version"
$ServerStatistics | Select-Object * | Sort-Object version -Descending | ft

Write-Output ""
Write-Output "Servers sorted by count"
$ServerStatistics | Select-Object * | Sort-Object count -Descending | ft
