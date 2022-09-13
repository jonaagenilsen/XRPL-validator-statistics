# Fetch statistics for UNL XRPL validators using API @ xrpscan.com
#
# (C) Jon Nilsen (jonaagenilsen@gmail.com) 2022
# Free to use for whatever. I hold no grudges :).
#
#

Function Get-VoteStatistics {
  $ValidVotes = $AllAmendments | Where-Object { $_.enabled -match "False"}

  [pscustomobject]$VoteStatistics = @()
  foreach ($ValidVote in $ValidVotes) {
    $Percent = [math]::Round(($ValidVote.count * 100 / $ValidVote.threshold + 1),1)
      $Object = [pscustomobject]@{
        AmendmentID   = $ValidVote.amendment_id
        AmendmentName = $ValidVote.name
        Deprecated    = $ValidVote.deprecated
        ServerVersion = $ValidVote.introduced
        Votes         = $ValidVote.count
        'Required votes (80% of UNL (+ 1 vote))'   = $ValidVote.threshold + 1
        Progress      = "$($Percent)%"
      }
      $VoteStatistics += $Object
  
    }
  Return $VoteStatistics
}

Function Get-ValidatorVotes {
  param ( [parameter(Mandatory = $true)][string] $Master_key )

  [pscustomobject]$VotedOn = @()
  $VotedIDs = ($dUNLValidators | Where-Object { $_.master_key -eq $Master_key }).votes.amendments

  if (!$VotedIDs) {
    return $VotedOn
  }

  foreach ($VotedID in $VotedIDs) {
    # Translate ID to Name on amendment
    $AmendmentName = $AllAmendments | Where-Object { $_.amendment_id -eq $AmendmentID } | Select-Object name -ExpandProperty name
    $VotedOn += "$AmendmentName "

    $Object = [pscustomobject]@{
      MasterKey = $Master_key
      AmendmentID = $VotedID
      AmendmentName = $AllAmendments | Where-Object { $_.amendment_id -eq $VotedID }                                  | Select-Object name       -ExpandProperty name
      Enabled =       $AllAmendments | Where-Object { $_.amendment_id -eq $VotedID -and $_.enabled -match "False" }   | Select-Object enabled    -ExpandProperty enabled
      Deprecated =    $AllAmendments | Where-Object { $_.amendment_id -eq $VotedID -and $_.deprecated -match "True" } | Select-Object deprecated -ExpandProperty deprecated
    }
    $VotedOn += $Object

  }
  Return $VotedOn
}

Function Get-ValidatorVoteNames {
  param ( [parameter(Mandatory = $true)][string] $Master_key )

  $VotedOn = ""
  $VotedIDs = ($dUNLValidators | Where-Object { $_.master_key -eq $Master_key }).votes.amendments
  if (!$VotedIDs) {
    return $VotedOn
#    return "-"
  }

  foreach ($VotedID in $VotedIDs) {
    # Translate ID to Name on amendment
    $AmendmentName = $AllAmendments | Where-Object { $_.amendment_id -eq $VotedID } | Select-Object name -ExpandProperty name
    $VotedOn += "$AmendmentName "
  }
  Return $VotedOn
}

Function Get-ValidatorVotesBaseOwner {
  param ( [parameter(Mandatory = $true)][string] $Master_key )
 
  [int]$BaseOwner    = ($dUNLValidators | Where-Object { $_.master_key -eq $Master_key }).votes.reserve_base
  [int]$ReserveOwner = ($dUNLValidators | Where-Object { $_.master_key -eq $Master_key }).votes.reserve_inc

  if ($BaseOwner)    { 
    $BaseOwner = $BaseOwner/1000000
  }
  if ($ReserveOwner) { 
    $ReserveOwner = $ReserveOwner/1000000
  }
  $NetworkBaseOwner = $($FeeSettings.node.ReserveBase) / 1000000
  $NetworkReserveOwner = $($FeeSettings.node.ReserveIncrement) / 1000000

  #$dUNLValidators | Where-Object { $_.master_key -eq $Master_key -and ($_.votes.reserve_base -and $_.votes.reserve_inc) } | Select-Object votes -ExpandProperty votes
  if ($BaseOwner -and $ReserveOwner) { 
    return "$BaseOwner / $ReserveOwner XRP"
  }
  elseif ($BaseOwner -and !$ReserveOwner) { 
    return "$BaseOwner / $NetworkReserveOwner XRP"
  }
  elseif (!$BaseOwner -and $ReserveOwner) { 
    return "$NetworkBaseOwner / $ReserveOwner XRP"
  }
  else {
    return "$NetworkBaseOwner / $NetworkReserveOwner XRP"
  }
  return $Result
}
#Get-ValidatorVotesBaseOwner nHDwHQGjKTz6R6pFigSSrNBrhNYyUGFPHA75HiTccTCQzuu9d7Za

Function Get-Release_latest { 
  $Url = "https://github.com/ripple/rippled/releases/latest"
  $Request = [System.Net.WebRequest]::Create($url)
  $Response = $request.GetResponse()
  $RealTagUrl = $response.ResponseUri.OriginalString
  $Response.Close()
  $Version = $realTagUrl.split('/')[-1].Trim('v')
  
  if ($Version) { return $version }
  else { return $null }
}

clear

try {
  $Rippled_stable = Get-Release_latest
}
catch { }

if ($Rippled_stable) { 
  $FoundLatestVersion = "rippled-$($Rippled_stable)"
}

$UNL = "vl.xrplf.org"
$BaseURLAPI = "https://api.xrpscan.com"
$web_client = new-object system.net.webclient

try {
  $AllAmendments = $Web_client.DownloadString("$BaseURLAPI/api/v1/amendments")         | ConvertFrom-Json
  $AllValidators = $Web_client.DownloadString("$BaseURLAPI/api/v1/validatorregistry")  | ConvertFrom-Json
  $FeeSettings   = $Web_client.DownloadString("$BaseURLAPI/api/v1/object/FeeSettings") | ConvertFrom-Json
}
catch {
}

if ($FoundLatestVersion -and $AllAmendments -and $FeeSettings -and $AllValidators) {
  $CountTestChain              = $AllValidators | Where-Object { $_.chain -eq "test" } | Measure-Object | Select-Object -ExpandProperty count
  $CountMainChain              = $AllValidators | Where-Object { $_.chain -eq "main" } | Measure-Object | Select-Object -ExpandProperty count
  $CountMainChainUNL           = $AllValidators | Where-Object { $_.chain -eq "main" -and $_.unl -contains "$UNL" } | Measure-Object | Select-Object -ExpandProperty Count
  $CountMainChainUNLValidators = $AllValidators | Select-Object master_key, domain_legacy, unl | Where-Object { $_.unl -contains "$UNL" }| Measure-Object | Select-Object -ExpandProperty Count
  $CountAllChain               = $CountTestChain + $CountMainChain

  $ReportTime = Get-Date -Format "dd.MM.yyy HH:mm"
  Write-Host "Status of UNL validators: " -NoNewline; Write-Host "$ReportTime" -NoNewline -ForegroundColor Green; Write-Host " CEST"
  Write-Host "Found " -NoNewline; Write-Host "$CountAllChain" -NoNewline -ForegroundColor Green; Write-Host " validators in total: " -NoNewline
  Write-Host "$CountMainChain" -NoNewline -ForegroundColor Green; Write-Host " mainnet + " -NoNewline; Write-Host "$CountMainChainUNLValidators" -NoNewline -ForegroundColor Green`
  Write-Host " mainnet UNL + " -NoNewline; Write-Host "$CountTestChain" -NoNewline -ForegroundColor Green; Write-Host " testnet"
  
  Write-Host "Latest stable server software: " -NoNewline; Write-Host "$FoundLatestVersion" -ForegroundColor Green; Write-Host ""

  $dUNLValidators = $AllValidators | Select-Object master_key, domain_legacy, server_version, unl, votes | Where-Object { $_.unl -contains "$UNL" }
  $dUNLValidatorVersions = ($AllValidators | Select-Object master_key, domain_legacy, server_version, unl, votes | Where-Object { $_.unl -contains "$UNL" }).server_version.version | Select-Object -Unique | Sort-Object -Descending

  # Collect data about validators and create a collection of them.
  [pscustomobject]$ValidatorStatistics = @()
  foreach ($dUNLValidatorVersion in $dUNLValidatorVersions) {
    $Results = $dUNLValidators | Where-Object { $_.server_version -like "*$dUNLValidatorVersion*" } | Sort-Object domain_legacy | Select-Object domain_legacy, master_key, server_version
    foreach ($Result in $Results) {
      $AmendmentVotes = Get-ValidatorVoteNames -Master_key $Result.master_key
      $ReserveVotes   = Get-ValidatorVotesBaseOwner -Master_key $Result.master_key

      $Object = [pscustomobject]@{
        Domain             = $Result.domain_legacy
        ServerVersion      = $($Result.server_version.Version)
        'Reserves voting'  = $ReserveVotes
        'Amendment voting' = $AmendmentVotes
      }
      $ValidatorStatistics += $Object
    }
  }
  
  # Display ALL UNL validators on ALL existing versions.
  foreach ($dUNLValidatorVersion in $dUNLValidatorVersions) {
    $Count = $dUNLValidators | Select-Object master_key, domain_legacy, server_version, unl | Where-Object { $_.server_version -like "*$dUNLValidatorVersion*" } | Measure-Object | Select-Object -ExpandProperty Count
    $CountPercent = [math]::Round(($Count * 100 / $CountMainChainUNLValidators),1)
    Write-Host "UNL validators running " -NoNewline
    Write-Host "$dUNLValidatorVersion" -NoNewline -ForegroundColor Green
    Write-Host " [" -NoNewline
    Write-Host "$Count" -NoNewline -ForegroundColor Yellow #; Write-Host " / " -NoNewline
    Write-Host "|" -NoNewline; Write-Host "$CountPercent%" -NoNewline -ForegroundColor Green
    Write-Host "]:" -NoNewline # base/owner reserve and amendments voted for:" -NoNewline
    $NetworkStateBaseReserve = ($FeeSettings.node.ReserveBase / 1000000)
    $NetworkStateOwnerReserve = ($FeeSettings.node.ReserveIncrement / 1000000)
    
    $ValidatorStatistics | Where-Object { $_.ServerVersion -match $dUNLValidatorVersion } | Select-Object Domain, 'Reserves voting', 'Amendment voting' | ft # | Sort-Object 'Reserves voting' | ft #-HideTableHeaders
  }

  # Display active votes.
  $AmendmentVotes = Get-VoteStatistics | Select-Object * | Where-Object { $_.Deprecated -notmatch "True" }
  Write-Host "Amendments available & votes: " -NoNewline
  Write-host "$($AmendmentVotes.count)" -NoNewline -ForegroundColor Green
  
  $AmendmentVotes | Select-Object AmendmentName, ServerVersion, Votes, 'Required votes (80% of UNL (+ 1 vote))', Progress | Sort-Object Votes -Descending | ft #-HideTableHeaders
  
  # Display active but deprecated votes.
  [array]$DeprecatedAmendmentVotes = Get-VoteStatistics | Select-Object * | Where-Object { $_.Deprecated -match "True" -and $_.Votes -gt 0}
  if ($DeprecatedAmendmentVotes) {
  #  Write-Host ""
    Write-Host "Amendments (deprecated) not enabled AND being voted on.`nThese can safely be removed from active voting: " -NoNewline
    Write-host "$($DeprecatedAmendmentVotes.count)" -NoNewline -ForegroundColor Red
  
    $DeprecatedAmendmentVotes | Select-Object AmendmentName, ServerVersion, Votes, Requirement, Progress | Sort-Object Votes -Descending | ft #-HideTableHeaders
  }
}
else {
  Write-Host "Unable to fetch data from Cyberspace @ $BaseURLAPI. Aborted." -ForegroundColor Red
}

Write-Host "Sources:"
Write-Host "https://xrpscan.com/validators / https://xrpscan.com/amendments"


