param([Parameter(ValueFromRemainingArguments=$true)]$RspecArgs)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not $RspecArgs -or $RspecArgs.Count -eq 0) {
  $RspecArgs = @("spec/services/game/world/gather_fishing_mail_spec.rb")
}
$joined = ($RspecArgs -join " ")
$script = @"
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq build-essential libpq-dev libyaml-dev git postgresql-client > /dev/null
bundle install --quiet
bundle exec rails db:prepare
bundle exec rspec $joined
"@
docker compose -f docker-compose.test.yml run --rm rspec $script
