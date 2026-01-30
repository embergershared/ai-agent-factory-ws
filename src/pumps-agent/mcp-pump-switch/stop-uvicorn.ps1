$port = 8010
$line = netstat -ano | Select-String ":$port\s+.*LISTENING"
if (-not $line) { Write-Host "Nothing listening on $port"; exit 0 }

$UVI_PID = ($line -split '\s+')[-1]
Write-Host "Killing PID $UVI_PID listening on port $port"
taskkill /PID $UVI_PID /F