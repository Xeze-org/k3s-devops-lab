#!/usr/bin/env bash
# Show enabled flags + ArgoCD app health + tool URLs.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/_lib.sh
load_env .env

echo "== Flags (.env) =="
for f in MONITORING LOKI JENKINS NEXUS; do printf "  %-12s %s\n" "$f" "$(yaml_bool "${!f:-false}")"; done

echo
echo "== ArgoCD applications =="
vagrant ssh -c "sudo kubectl -n argocd get applications.argoproj.io 2>/dev/null \
  -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status" \
  2>/dev/null || echo "  (VM not reachable — is it up?)"

echo
echo "== URLs (only enabled tools resolve) =="
declare -A hosts=( [MONITORING]="grafana" [LOKI]="loki" [JENKINS]="jenkins" [NEXUS]="nexus" )
for f in MONITORING LOKI JENKINS NEXUS; do
  [ "$(yaml_bool "${!f:-false}")" = "true" ] && echo "  https://${hosts[$f]}.${DOMAIN}"
done
