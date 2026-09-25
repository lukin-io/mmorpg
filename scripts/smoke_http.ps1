# Permanent HTTP smoke for Railway when agent browser MCP is dead.
# Usage: powershell -File scripts/smoke_http.ps1
param(
  [string]$BaseUrl = "https://web-production-bc5d0.up.railway.app"
)

$ErrorActionPreference = "Stop"
Write-Host "Smoke against $BaseUrl"

$login = Invoke-WebRequest -Uri "$BaseUrl/users/sign_in" -UseBasicParsing
Write-Host "sign_in status=$($login.StatusCode) len=$($login.RawContentLength)"
if ($login.Content -notmatch "password|Password|парол|email|Email") {
  throw "Login form markers missing"
}

$root = Invoke-WebRequest -Uri "$BaseUrl/" -UseBasicParsing -MaximumRedirection 5
Write-Host "root status=$($root.StatusCode)"
Write-Host "SMOKE_OK"
