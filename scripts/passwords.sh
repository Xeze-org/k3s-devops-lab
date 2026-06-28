#!/usr/bin/env bash
# Print admin user + password for every tool that's actually deployed.
#
# Run INSIDE the VM (the repo is mounted at /vagrant):
#   vagrant ssh -c "bash /vagrant/scripts/passwords.sh"
# or, once you're already shelled in with `vagrant ssh`:
#   bash /vagrant/scripts/passwords.sh
set -uo pipefail

# Local cluster access — sudo because k3s's kubeconfig is root-only.
k() { sudo k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml "$@"; }

# Print a block only if the password came back non-empty (i.e. the tool exists).
show() {  # label  password
  [ -n "$2" ] || return 0
  printf "\n  %-8s user: admin\n           pass: %s\n" "$1" "$2"
}

echo "== Admin credentials =="

show "ArgoCD"  "$(k -n argocd get secret argocd-initial-admin-secret \
                  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)"

show "Grafana" "$(k -n monitoring get secret grafana-admin \
                  -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d)"

show "Jenkins" "$(k -n jenkins get secret jenkins \
                  -o jsonpath='{.data.jenkins-admin-password}' 2>/dev/null | base64 -d)"

show "Nexus"   "$(k -n nexus exec deploy/nexus-nexus-repository-manager \
                  -- cat /nexus-data/admin.password 2>/dev/null)"

# Harbor stores its admin password bcrypt-hashed in the DB — not readable from
# the cluster. It's whatever harborAdminPassword was set to (chart default below).
show "Harbor"  "$(k get ns harbor >/dev/null 2>&1 && echo 'Harbor12345 (helm default — set harborAdminPassword to change)')"

echo
