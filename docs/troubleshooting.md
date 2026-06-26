# Troubleshooting

### `chart not found` on sync
Pinned Helm chart versions in `gitops/root/templates/*.yaml` age out. Bump that app's
`targetRevision` to a current version and push.

### A tool didn't install after I enabled it
ArgoCD reconciles every ~3 min. Force it:
```powershell
vagrant ssh -c "bash /vagrant/scripts/sync.sh"
```
Then check health:
```powershell
bash scripts/status.sh
```

### Ingress returns 404 / no ADDRESS
k3s uses **Traefik**, not nginx. Ingresses must set `ingressClassName: traefik`. Confirm:
```bash
vagrant ssh -c "sudo k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get ingressclass"
```

### Heavy tool enabled but VM feels starved
Run `vagrant reload` so the VM resizes for the new flag set. See [VM sizing](vm-sizing.md).

### Passwords command shows nothing for a tool
It's either not enabled, or still syncing (secret not created yet). Re-run after ArgoCD
finishes. See [Passwords](passwords.md).

### Start over with Cloudflare
```bash
bash scripts/clean-cf.sh   # delete the tunnel + wildcard DNS
```
