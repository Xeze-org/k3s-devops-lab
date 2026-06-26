# k3-kube — single-VM DevOps lab

A fully-automated, modular DevOps learning lab on one VMware VM:
**Vagrant → Ansible → k3s → ArgoCD (GitOps) → Cloudflare Tunnel**.
Toggle tools on/off from `.env`; ArgoCD installs or prunes them automatically.
Everything is reachable at `https://<tool>.<your-domain>` with no port-forwarding.

> Design spec: [`docs/superpowers/specs/2026-06-26-k3s-devops-lab-design.md`](docs/superpowers/specs/2026-06-26-k3s-devops-lab-design.md)

## Prerequisites (one-time, all free for personal use)

1. **VMware Workstation Pro** (free for personal use).
2. **Vagrant** + the **Vagrant VMware Utility** (free, from HashiCorp).
3. `vagrant plugin install vagrant-vmware-desktop` (open-source, no license).
4. **Git for Windows** (the helper scripts run via Git Bash).
5. A domain on **Cloudflare** + an API token scoped to *Zone:DNS:Edit* and
   *Account:Cloudflare Tunnel:Edit*, plus your **Account ID**.
6. A **GitHub repo** for this project + a token (ArgoCD pulls manifests from it).

## Quick start

```bash
cp .env.example .env       # then fill in DOMAIN, CF_*, GIT_*, GITHUB_TOKEN, flags
```

Windows (PowerShell):
```powershell
.\lab.ps1 up        # boot + bootstrap everything
.\lab.ps1 status    # VM size, ArgoCD app health, tool URLs
.\lab.ps1 apply     # after editing .env flags: re-render, push, reconcile
.\lab.ps1 down      # destroy the VM
.\lab.ps1 clean-cf  # delete the Cloudflare tunnel + wildcard DNS
```

With `make` (Git Bash / Linux):
```bash
make up | make status | make apply | make sync | make plan | make down | make clean-cf
```

## How toggling works

1. Edit a flag in `.env` (e.g. `JENKINS=true`).
2. `apply` renders `.env` → `gitops/root/values.yaml`, commits, and **pushes to GitHub**.
3. ArgoCD sees the change and **installs** Jenkins (or **prunes** it when set to `false`).
4. It appears at `https://jenkins.<domain>` via the Cloudflare wildcard.

Flags live in Git (`values.yaml`); secrets (CF token, GitHub token) are injected into
the cluster by Ansible and **never committed**.

## VM auto-sizing

RAM/CPU is computed from enabled flags (base 4GB/2CPU; +1GB monitoring, +0.5GB Loki,
+2GB/+1CPU each for Jenkins/Nexus), clamped to 4–8GB / 2–4 CPU. Set `VM_MEMORY`/`VM_CPUS`
in `.env` to override. You cannot comfortably run all four heavy tools at once — that's
what the toggles are for.

## Known things to verify on first run

- **Pinned Helm chart versions** in `gitops/root/templates/*.yaml` may age out. If an
  ArgoCD app shows `chart not found`, bump its `targetRevision`.
- The Cloudflare role creates a **locally-managed** tunnel named `k3-kube`; re-runs reuse
  the in-cluster credentials. `clean-cf` removes both the tunnel and the wildcard DNS.
- TLS terminates at Cloudflare's edge; in-cluster traffic to Traefik is plain HTTP (fine
  for a lab).

## License

[Apache License 2.0](LICENSE) © 2026 Xeze-org.
