#!/usr/bin/env bash
# Smoke test: curl each enabled tool's public URL and report HTTP status.
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/_lib.sh
load_env .env

declare -A hosts=( [MONITORING]="grafana" [JENKINS]="jenkins" [NEXUS]="nexus" )
rc=0
for f in MONITORING JENKINS NEXUS; do
  [ "$(yaml_bool "${!f:-false}")" = "true" ] || continue
  url="https://${hosts[$f]}.${DOMAIN}"
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$url" || echo "000")
  if [[ "$code" =~ ^(200|301|302|401|403)$ ]]; then
    printf "  OK   %-40s [%s]\n" "$url" "$code"
  else
    printf "  FAIL %-40s [%s]\n" "$url" "$code"; rc=1
  fi
done
exit $rc
