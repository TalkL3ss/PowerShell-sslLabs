<#
.SYNOPSIS
    .
.DESCRIPTION
    Scan sites rating in SSL-Labs
.PARAMETER siteADDRs
    Enter the sites that you want to scan as a list "www1.site1.co.il","site1.co.il".
.PARAMETER UseProxy
    Specifies if use proxy or not
.PARAMETER Proxy
    Specifies Proxy Address if not default
.EXAMPLE
    C:\PS> "www1.site1.co.il","site1.co.il" | Get-SiteRating
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "www1.site1.co.il","site1.co.il"
    Scan The following sites address for rating (with proxy enabled [default])
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "www1.site1.co.il","site1.co.il" -UseProxy
    Scan The following sites address for rating, with default proxy
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "www1.site1.co.il","site1.co.il" -UseProxy $false
    Scan The following sites address for rating, with no proxy
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "www1.site1.co.il","site1.co.il" -Proxy proxy.out.local:8080
    Scan The following sites address for rating, with other proxy settings
.NOTES
    Author: Ohad Halali
    Date:   Aug 12, 2019    
#>
$siteToCheck    = "site1.co.il","site2.co.il","site3.com"
$lastlogPath    = "c:\temp\1.csv"
$logPath        = "c:\temp\" + (Get-Date -Format dd-MM-yyyy) + ".csv"

New-Item -Path $logPath -Force -ItemType File | Out-Null

 
Function Get-SiteRating {
<#
.SYNOPSIS
    .
.DESCRIPTION
    Scan sites rating in SSL-Labs
.PARAMETER siteADDRs
    Enter the sites that you want to scan as a list "www1.site1.co.il","site1.co.il".
.PARAMETER UseProxy
    Specifies if use proxy or not
.PARAMETER Proxy
    Specifies Proxy Address if not default
.EXAMPLE
    C:\PS> "www1.site1.co.il","site1.co.il" | Get-SiteRating
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "www1.site1.co.il","site1.co.il"
    Scan The following sites address for rating (with proxy enabled [default])
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "www1.site1.co.il","site1.co.il" -UseProxy
    Scan The following sites address for rating, with default proxy
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "www1.site1.co.il","site1.co.il" -UseProxy $false
    Scan The following sites address for rating, with no proxy
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "www1.site1.co.il","site1.co.il" -Proxy http://proxy.out.local:8080
    Scan The following sites address for rating, with other proxy settings
.NOTES
    Author: Ohad Halali
    Date:   Aug 12, 2019    
#>
[CMDLetBinding()]
param (
    [Parameter(Mandatory=$true,Position=1,ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage="Enter the sites that you want to scan as a list `"www1.site1.co.il`",`"site1.co.il`"")]
    $siteADDRs,
    [string]$Proxy = "http://proxy.out.local:8080",
    [switch]$UseProxy = $true
)

 ForEach ($site in $siteADDRs) {
        $baseSite = 'https://api.ssllabs.com/api/v3/analyze?host='
        $siteParams = '&publish=off'
        $fullSite =  [string]::Format("{0}{1}{2}",$baseSite,$site,$siteParams) 
        if ($UseProxy){
                $results = Invoke-WebRequest -Uri $fullSite -Proxy $Proxy | ConvertFrom-Json 
            } else { 
                $results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
            }
        while ($results.status -ne "READY" -and $results.status -ne "ERROR" )
        {
            $siteParams = '&publish=off&fromCache=on&startNew=off&all=done'
            $fullSite =  [string]::Format( "{0}{1}{2}",$baseSite,$site,$siteParams) 
            Start-Sleep -Seconds (Get-Random -Minimum 30 -Maximum 50) 
            if ($UseProxy){
                 $results = Invoke-WebRequest -Uri $fullSite -Proxy $Proxy | ConvertFrom-Json 
            } else { 
                 $results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
            } 
            if ($results -eq $null) { 
                $site, "Unknow","Unknow" | tee $logPath -Append
            }
            else {
                $resultsToFile =  $results | select -ExpandProperty endpoints | select @{Label="Site_Address"; exp={$site}},grade,ipAddress } 
                $resultsToFile | Export-Csv -Path $logPath -Append -NoTypeInformation
                $resultsToFile = $null
                }
        }

    Copy-Item $logPath $lastlogPath -Force
}

Get-SiteRating -siteADDRs $siteToCheck
