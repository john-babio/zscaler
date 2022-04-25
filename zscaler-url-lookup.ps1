$seed = "apikey"
#Run script from the same folder that your urls are located in. File should be called urls.txt
# If using a new enough .NET version (4.6+) you can do this
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

# Otherwise this also works
$epoch = [DateTime]::new(1970, 1, 1, 0, 0, 0, 0, "Utc")
$timestamp = [int64]((Get-Date).ToUniversalTime() - $epoch).TotalMilliseconds

# The following uses the timestamp as a string
$nowString = $timestamp.ToString()

# Gets the last 6 chars of the timestamp
$n = $nowString.Substring($nowString.Length - 6)

# Converts those 6 chars to a number and shifts the bits to the right
# by 1 (int(n) >> 1 in Python). From there it ensures it is padded by
# 0's on the left in case the number was too small.
$r = ([int]$n -shr 1).ToString().PadLeft(6, "0")

# Enumerates each char in $n and $r and uses the decimal value each
# char represents to add a new value to the key based on the initial seed
$key = ""
foreach ($char in $n.GetEnumerator()) {
    $idx = [int][string]$char
    $key += $seed[$idx]
}
# Same as the above but the example adds an extra 2 to the index
foreach ($char in $r.GetEnumerator()) {
    $idx = [int][string]$char
    $key += $seed[$idx + 2]
}
$server = "zsapi.zscalerthree.net"

"Timestamp: $timestamp - Key: $key"
$Body = @{
    apiKey= "$key"
    username= "username"
    password= "password"
    timestamp= "$timestamp"
}

$lc = (Get-Content .\urls.txt).Length
if ( $lc -gt 100 ) {
$InputFilename = Get-Content '.\urls.txt'
$OutputFilenamePattern = 'url-list_'
$LineLimit = 100
# Initialize
$line = 0
$i = 0
$file = 0
$start = 0
# Loop all text lines
while ($line -le $InputFilename.Length) {
    # Generate child
    if ($i -eq $LineLimit -Or $line -eq $InputFilename.Length) {
        $file++
        $Filename = "$OutputFilenamePattern$file.txt"
        $InputFilename[$start..($line - 1)] | Out-File $Filename -Force
        $start = $line;
        $i = 0
        Write-Host "$Filename"
    }
    # Increment counters
    $i++;
    $line++
    }

    $urlfiles = Get-Childitem .\url-list_*
    foreach ($file in $urlfiles) {
    $url = gc $file.Name
    echo "[" | out-file .\url-list.txt -Append
    $url | forEach {"""$_"","}  | out-file .\url-list.txt -Append
    echo "]" | out-file .\url-list.txt -Append
    $url1 = gc .\url-list.txt 
    $url2 = $url1 -join ("")
    $urllist = $url2 -replace ",]","]"
    $newbody = $Body | convertTo-Json
    $new = Invoke-WebRequest -Method POST "https://zsapi.zscalerthree.net/api/v1/authenticatedSession" -ContentType 'application/json' -Body $newbody -SessionVariable Session
    $newurl = Invoke-WebRequest -Method POST "https://zsapi.zscalerthree.net/api/v1/urlLookup" -Body $urllist -ContentType 'application/json' -WebSession $Session
    $newurl | convertFrom-json
    rm .\url-list.txt
    Start-Sleep -s 2
    }
    rm .\url-list_*
} 
else {
    $url = gc .\urls.txt
    echo "[" | out-file .\url-list.txt -Append
    $url | forEach {"""$_"","}  | out-file .\url-list.txt -Append
    echo "]" | out-file .\url-list.txt -Append
    $url1 = gc .\url-list.txt 
    $url2 = $url1 -join ("")
    $urllist = $url2 -replace ",]","]"
    $newbody = $Body | convertTo-Json
    $new = Invoke-WebRequest -Method POST "https://zsapi.zscalerthree.net/api/v1/authenticatedSession" -ContentType 'application/json' -Body $newbody -SessionVariable Session
    $newurl = Invoke-WebRequest -Method POST "https://zsapi.zscalerthree.net/api/v1/urlLookup" -Body $urllist -ContentType 'application/json' -WebSession $Session
    $newurl | convertFrom-json
    rm .\url-list.txt
}
