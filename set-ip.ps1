param(
  [string]$Ip
)

$ErrorActionPreference = 'Stop'

if (-not $Ip) {
  $detected = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
      $_.IPAddress -notlike '127.*' -and
      $_.IPAddress -notlike '169.254.*' -and
      $_.InterfaceAlias -notmatch 'vEthernet|WSL|Hyper-V|Docker|Loopback|Virtual' -and
      $_.PrefixOrigin -ne 'WellKnown'
    } |
    Sort-Object InterfaceMetric |
    Select-Object -First 1 -ExpandProperty IPAddress

  if (-not $detected) {
    throw 'Could not auto-detect LAN IPv4 address. Pass it explicitly: .\set-ip.ps1 192.168.100.107'
  }
  $Ip = $detected
}

if ($Ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
  throw "Invalid IPv4 address: $Ip"
}

Write-Host "Setting HOST_IP=$Ip across Backend/.env and Frontend/.env..." -ForegroundColor Cyan

$envFiles = @(
  (Join-Path $PSScriptRoot 'Backend\.env'),
  (Join-Path $PSScriptRoot 'Frontend\.env')
)

foreach ($file in $envFiles) {
  if (Test-Path $file) {
    $content = Get-Content -Raw $file
    if ($content -match '(?m)^HOST_IP=.*$') {
      $updated = [regex]::Replace($content, '(?m)^HOST_IP=.*$', "HOST_IP=$Ip")
    } else {
      $updated = "HOST_IP=$Ip`r`n" + $content
    }
    Set-Content -Path $file -Value $updated -NoNewline
    Write-Host "  Updated $file" -ForegroundColor Green
  }
}

Write-Host 'Recreating LiveKit and API containers with the new HOST_IP...' -ForegroundColor Cyan
Push-Location (Join-Path $PSScriptRoot 'Backend')
try {
  docker compose up -d livekit api
} finally {
  Pop-Location
}

Write-Host "Done! HOST_IP is now $Ip (API: http://${Ip}:3000, LiveKit: ws://${Ip}:7880)" -ForegroundColor Green
