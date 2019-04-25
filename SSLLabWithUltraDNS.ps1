<#
This Script Check ultradns api for any A Records in the DNS,
And send a query for SSLLabs for certificate ranking
!!!!
$username = "myUser"
$password = "Password123!@#"
!!!!
Ohad Halali 2019
#>
$lastlogPath    = "c:\temp\1.csv" #set singal log for the Excel application to read
$logPath        = "c:\temp\" + (Get-Date -Format dd-MM-yyyy) + ".csv"#save history file 
New-Item -Path $logPath -Force -ItemType File | Out-Null #create the history file 

#saved cred for the api of ultradns
$CredData = @{
    grant_type = "password"
    username = "UserName"
    password = "Password"
}


<# Remove the comments marks if proxy needed, this will overwrite the default of Invoke-WebRequest -Proxy #>

$global:PSDefaultParameterValues = @{
        'Invoke-RestMethod:Proxy'='http://proxy.local.co.il:8080'
        'Invoke-WebRequest:Proxy'='http://proxy.local.co.il:8080'
        '*:ProxyUseDefaultCredentials'=$false
    }


Function Get-UDNZones {
[CMDLetBinding()]
param ($CredData)

    $Oauth = Invoke-WebRequest "https://api.ultradns.com/authorization/token" -Method Post -Body $CredData | ConvertFrom-Json #Get OAuth Token
    $OauthToken = @{ Authorization = "Bearer "+ $Oauth.access_token } #Create OAuth Auth Authorization Token header
    $AllZones = Invoke-WebRequest https://api.ultradns.com/zones/ -Headers $OauthToken | ConvertFrom-Json #Get all of my Zones in UltraDNS

    #run on all zones and check if any A Record is exists
    for ($i=0; $i -le $AllZones.zones.properties.Count-1; $i++) {
        if (($AllZones.zones.properties[$i].name.TrimEnd(".") -like "xn--*") -or -not([bool]$AllZones.zones.properties[$i].name.TrimEnd("."))) { continue } #Jump over null or hebrew zones
        $oneZone = $AllZones.zones.properties[$i].name.TrimEnd(".")
        $ARecURL = "https://api.ultradns.com/zones/{0}/rrsets/A/" -f $oneZone #Create URL for checking the A Records
        Write-Host "Checking Zone: $oneZone" -BackgroundColor DarkRed -ForegroundColor Yellow #Show the Zone that we gonna ask the a Records
        try {
            $ARecInZone = Invoke-WebRequest $ARecURL -Headers $OauthToken | ConvertFrom-Json #Get the A Records   
        } catch {
            if ($_.Exception.Response.StatusCode.Value__ -eq '401') { 
                $Oauth = Invoke-WebRequest "https://api.ultradns.com/authorization/token" -Method Post -Body @{grant_type = "refresh_token"; refresh_token = $Oauth.refresh_token } | ConvertFrom-Json #Get OAuth Token
                $OauthToken = @{ Authorization = "Bearer "+ $Oauth.access_token } #Create OAuth Auth Authorization Token header
                $ARecInZone = Invoke-WebRequest $ARecURL -Headers $OauthToken | ConvertFrom-Json #Get the A Records   
            }
         }
        for ($x=0;$x -le $ARecInZone.rrSets.Count-1; $x++) { 
        if ($ARecInZone.rrSets.Count -le 1) { continue }
			Write "Scan This: $ARecInZone.rrSets[$x].ownerName.TrimEnd(""."")"
            Get-SiteRating -site $ARecInZone.rrSets[$x].ownerName.TrimEnd(".")  #get only the A Record and save it to file
         }
    
    }
}


 
Function Get-SiteRating {
[CMDLetBinding()]
param ($site)
$baseSite = 'https://api.ssllabs.com/api/v3/analyze?host='
$siteParams = '&publish=off'
$fullSite =  [string]::Format("{0}{1}{2}",$baseSite,$site,$siteParams) #bulid a full url to check SSLabs 
$results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
while ($results.status -ne "READY" -and $results.status -ne "ERROR" )
    {
        $siteParams = '&publish=off&fromCache=on&startNew=off&all=done'
        $fullSite =  [string]::Format("{0}{1}{2}",$baseSite,$site,$siteParams) 
        if ($eta -eq $null) {
            Start-Sleep -Seconds 20
                } else {
             Start-Sleep -Seconds $eta
                 }

                 $results = Invoke-WebRequest -Uri $fullSite | ConvertFrom-Json 
            
        }
        
$eta = ($results | select -ExpandProperty endpoints | select eta).eta
$resultsToFile =  $results | select -ExpandProperty endpoints | select @{Label="Site_Address"; exp={$site}},grade,ipAddress,@{Label="DateRun"; exp={get-date}} 
$resultsToFile | Export-Csv -Path $logPath -Append -NoTypeInformation
       
$resultsToFile = $null
$results = $null
}

Get-UDNZones -CredData $CredData
Copy-Item $logPath $lastlogPath -Force
