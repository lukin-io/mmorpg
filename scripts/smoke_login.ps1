# Login + world HTTP smoke when Cursor browser MCP is dead (Server not found).
# Usage:
#   $env:SMOKE_EMAIL="..."; $env:SMOKE_PASSWORD="..."; powershell -File scripts/smoke_login.ps1
param(
  [string]$BaseUrl = "https://web-production-bc5d0.up.railway.app",
  [string]$Email = $env:SMOKE_EMAIL,
  [string]$Password = $env:SMOKE_PASSWORD
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Get-Page([string]$Uri, $Session) {
  try {
    return Invoke-WebRequest -Uri $Uri -UseBasicParsing -WebSession $Session -MaximumRedirection 5
  } catch {
    $resp = $_.Exception.Response
    if (-not $resp) { throw }
    $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
    $body = $reader.ReadToEnd()
    return [pscustomobject]@{
      StatusCode = [int]$resp.StatusCode
      Content = $body
      RawContentLength = $body.Length
      BaseResponse = $resp
    }
  }
}

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$loginPage = Get-Page "$BaseUrl/users/sign_in" $session
Write-Host "sign_in status=$($loginPage.StatusCode) len=$($loginPage.RawContentLength)"
if ($loginPage.Content -notmatch 'name="user\[login\]"|name="user\[password\]"') {
  throw "Devise login fields missing"
}

if (-not $Email -or -not $Password) {
  Write-Host "LOGIN_FORM_OK (no credentials — set SMOKE_EMAIL / SMOKE_PASSWORD for full login)"
  exit 0
}

$token = $null
if ($loginPage.Content -match 'name="authenticity_token"[^>]*value="([^"]+)"') {
  $token = $Matches[1]
} elseif ($loginPage.Content -match 'value="([^"]+)"[^>]*name="authenticity_token"') {
  $token = $Matches[1]
}
if (-not $token) { throw "CSRF token missing on sign_in" }

$body = @{
  "authenticity_token" = [System.Net.WebUtility]::HtmlDecode($token)
  "user[login]" = $Email
  "user[password]" = $Password
  "user[remember_me]" = "0"
}

$after = $null
try {
  $after = Invoke-WebRequest -Uri "$BaseUrl/users/sign_in" -Method POST -Body $body -WebSession $session -UseBasicParsing -MaximumRedirection 5 -Headers @{
    "Accept" = "text/html"
    "Content-Type" = "application/x-www-form-urlencoded"
  }
} catch {
  $resp = $_.Exception.Response
  if (-not $resp) { throw }
  $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
  $bodyText = $reader.ReadToEnd()
  $code = [int]$resp.StatusCode
  Write-Host "post_login status=$code len=$($bodyText.Length)"
  if ($code -eq 422 -or $bodyText -match "Invalid|неверн|sign_in") {
    throw "Login rejected (HTTP $code) — wrong credentials or CSRF; form itself is up"
  }
  throw
}

Write-Host "post_login status=$($after.StatusCode) len=$($after.RawContentLength)"
$world = Get-Page "$BaseUrl/world" $session
Write-Host "world status=$($world.StatusCode)"
Write-Host "LOGIN_SMOKE_OK"
