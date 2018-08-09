$siteToCheck    = "site.co.il","www.site.co.il","site.com"
$alljobs        = $true
$logPath        = "c:\temp\1.csv"

New-Item -Path $logPath -Force -ItemType File

Function WriteLog($line)
{
     Add-Content -Path $logPath -Value $line 
} 

 
Function AsyncJobs([array]$siteADDRs) {
$sb = { param($site)
        $baseSite = 'https://api.ssllabs.com/api/v3/analyze?host='
        $siteParams = '&publish=off'
        $fullSite =  [string]::Format( "{0}{1}{2}",$baseSite,$site,$siteParams) 
        $results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
        While ($results.status -ne "READY" -and $results.status -ne "ERROR" )
        {
            $siteParams = '&publish=off&fromCache=on&startNew=off&all=done'
            $fullSite =  [string]::Format( "{0}{1}{2}",$baseSite,$site,$siteParams) 
            Start-Sleep -Seconds (Get-Random -Minimum 30 -Maximum 60) 
            $results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
        }
        $results | select -ExpandProperty endpoints | select @{Label="Site_Address"; exp={$site}},grade,ipAddress }

    ForEach ($site in $siteADDRs) {
        Start-Job -Name $site -ScriptBlock $sb -ArgumentList $site | out-null
        }
} 

AsyncJobs -siteADDR $siteToCheck

While ($alljobs -eq $true) { 
    $ourJobs = Get-Job
    foreach ($job in $ourJobs) {
        $jobResults   = $null
        Switch ($job.State) {
         {$_ -eq 'Completed'} {
                $jobResults = Receive-Job -id $job.id | Export-Csv -Path $logPath -Append -NoTypeInformation
                Remove-Job $job.Id -Force
            }
          {$_ -eq 'Failed'} {
           }

        }      
    } 
    $ourJobs = $null
    $ourJobs = Get-Job 

    if ($ourJobs) {$alljobs = $true} else {$alljobs = $false}

    Start-Sleep -Seconds 10

}
