$siteToCheck = "site1.com","site.co.il","www.site.co.il"
$alljobs        = $true
$fistLine    = $true
 
Function AsyncJobs([array]$siteADDRs) {
$sb = { param($site)
        $baseSite = 'https://api.ssllabs.com/api/v3/analyze?host='
        $siteParams = '&publish=off'
        $fullSite =  [string]::Format( "{0}{1}{2}",$baseSite,$site,$siteParams) 
        $results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
        While ($results.status -ne "READY" -and $results.status -ne "ERROR" )
        {
            sleep 30
            $results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
        }
        (($results | select endpoints).endpoints) | ft @{Label="Site_Address"; exp={$site}},grade,ipAddress }

    ForEach ($site in $siteADDRs) {
        Start-Job -Name $site -ScriptBlock $sb -ArgumentList $site 
        }
} 

AsyncJobs -siteADDR $siteToCheck

While ($alljobs -eq $true) { 
    $ourJobs = Get-Job
    foreach ($job in $ourJobs) {
        $jobResults   = $null
        Switch ($job.State) {
         {$_ -eq 'Running'} {
            } 
         {$_ -eq 'Completed'} {
                $jobResults = Receive-Job -id $job.id 
                if ($fistLine -eq $true) {  
                     Write-Host "first" + $fistLine + ($jobResults | Out-String)
                      $fistLine = $false
                 } else { 
                    Write-Host "else" + $fistLine +  ($jobResults | Out-String)
                 }
                 Remove-Job -id $job.id
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
