<#
.SYNOPSIS
    .
.DESCRIPTION
    Scan sites rating in SSL-Labs
.PARAMETER siteADDRs
    Enter the sites that you want to scan as a list "a.com","b.com".
.PARAMETER UseProxy
    Specifies if use proxy or not
.PARAMETER Proxy
    Specifies Proxy Address if not default
.EXAMPLE
    C:\PS> "a.com","b.com" | Get-SiteRating
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "a.com","b.com"
    Scan The following sites address for rating (with proxy enabled [default])
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "a.com","b.com" -UseProxy
    Scan The following sites address for rating, with default proxy
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "a.com","b.com" -UseProxy $false
    Scan The following sites address for rating, with no proxy
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "a.com","b.com" -Proxy http://proxy.local:8080
    Scan The following sites address for rating, with other proxy settings
.NOTES
    Author: Ohad Halali
    Date:   Aug 12, 2019    
#>
$siteToCheck    = "a.com","b.com"
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
    Enter the sites that you want to scan as a list "a.com","b.com".
.PARAMETER UseProxy
    Specifies if use proxy or not
.PARAMETER Proxy
    Specifies Proxy Address if not default
.EXAMPLE
    C:\PS> "a.com","b.com" | Get-SiteRating
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "a.com","b.com"
    Scan The following sites address for rating (with proxy enabled [default])
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "a.com","b.com" -UseProxy
    Scan The following sites address for rating, with default proxy
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "a.com","b.com" -UseProxy $false
    Scan The following sites address for rating, with no proxy
.EXAMPLE
    C:\PS> Get-SiteRating -siteADDRs "a.com","b.com" -Proxy http://myproxy.null.com:8080
    Scan The following sites address for rating, with other proxy settings
.NOTES
    Author: Ohad Halali
    Date:   Aug 12, 2019    
#>
[CMDLetBinding()]
param (
    [Parameter(Mandatory=$true,Position=1,ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage="Enter the sites that you want to scan as a list `"a.com`",`"b.com`"")]
    $siteADDRs,
    [string]$Proxy = "http://127.0.0.1:8080",
    [switch]$UseProxy = $false
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
            $fullSite =  [string]::Format("{0}{1}{2}",$baseSite,$site,$siteParams) 
            Start-Sleep -Seconds (Get-Random -Minimum 30 -Maximum 60) 
            if ($UseProxy){
                 $results = Invoke-WebRequest -Uri $fullSite -Proxy $Proxy | ConvertFrom-Json 
            } else { 
                 $results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
            }
        }
        $resultsToFile =  $results | select -ExpandProperty endpoints | select @{Label="Site_Address"; exp={$site}},grade,ipAddress,@{Label="DateRun"; exp={get-date}} 
        $resultsToFile | Export-Csv -Path $logPath -Append -NoTypeInformation
       
        $resultsToFile = $null
        $results = $null
        Copy-Item $logPath $lastlogPath -Force
    }
}

Get-SiteRating -siteADDRs $siteToCheck
