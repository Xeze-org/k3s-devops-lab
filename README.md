# k3s DevOps Lab

![License](https://img.shields.io/badge/License-Apache%202.0-blue?style=for-the-badge)

**Core stack** &nbsp;·&nbsp; *host → provisioning → cluster → GitOps → edge*

![VMware](https://img.shields.io/badge/VMware-607078?style=for-the-badge&logo=vmware&logoColor=white)
![Vagrant](https://img.shields.io/badge/Vagrant-1563FF?style=for-the-badge&logo=vagrant&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![k3s](https://img.shields.io/badge/k3s-FFC61C?style=for-the-badge&logo=k3s&logoColor=black)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)
![Cilium](https://img.shields.io/badge/Cilium-F8C517?style=for-the-badge&logo=cilium&logoColor=black)

**DevOps stack** &nbsp;·&nbsp; *observability + CI/CD + artifacts + autoscaling*

![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Nexus](https://img.shields.io/badge/Nexus-1B1C30?style=for-the-badge&logo=sonatype&logoColor=white)
![KEDA](https://img.shields.io/badge/KEDA-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)

A fully-automated, modular DevOps learning lab on one VMware VM. Toggle tools on/off in
`values.yaml`; ArgoCD installs or prunes them. Every tool is reachable at
`https://<tool>.<your-domain>` via a Cloudflare Tunnel — no port-forwarding, no public IP.

> [!NOTE]
> Optional **eBPF networking**: set `cilium.enabled` to swap Flannel + kube-proxy
> for [Cilium + Hubble](docs/cilium.md). Unlike the ArgoCD tool toggles, it's a
> provision-time flag (needs a fresh `vagrant up`).

📖 **Docs:** [Prerequisites](docs/prerequisites.md) · [Quick start](docs/quickstart.md) · [Configuration](docs/configuration.md) · [Tools](docs/tools.md) · [KEDA](docs/keda.md) · [Cilium + Hubble](docs/cilium.md) · [Passwords](docs/passwords.md) · [Networking](docs/networking.md) · [VM sizing](docs/vm-sizing.md) · [Troubleshooting](docs/troubleshooting.md)

🧩 **Want to deploy your own app?** Copy the [`example/`](example/) app — manifests + ArgoCD setup, fully explained.

> [!WARNING]
> **Fork this repo first.** Then set `repoURL` (your fork) and `domain` in
> `gitops/root/values.yaml` and push — ArgoCD pulls from **your** repository, not this one.

```mermaid
flowchart LR
  v[gitops/root/values.yaml<br/>domain + tool flags] --> vg[vagrant up]
  vg --> an[Ansible bootstrap]
  an --> k3s[k3s]
  k3s -.->|cilium.enabled| ci[Cilium eBPF CNI<br/>+ Hubble]
  an --> cf[cloudflared tunnel]
  an --> ar[ArgoCD]
  ar -->|pulls public repo| gh[(GitHub)]
  gh --> tools[enabled tools<br/>grafana · loki · jenkins · nexus · keda]
```

## Quick start

```powershell
Copy-Item .env.example .env        # fill in CF_API_TOKEN + CF_ACCOUNT_ID
# edit gitops/root/values.yaml (domain + repoURL + tool flags), then:
git add gitops/root/values.yaml; git commit -m "configure lab"; git push
vagrant up
```

Details: [Quick start](docs/quickstart.md) · [Configuration](docs/configuration.md).

## Get your passwords

Username is `admin` for every tool:

```powershell
vagrant ssh -c "bash /vagrant/scripts/passwords.sh"
```

## Port-forwarding

Most tools are reachable at `https://<tool>.<domain>` via the Cloudflare Tunnel.
For anything **not** exposed through an ingress — e.g. the **Hubble UI** (no auth,
deliberately kept private) — reach it directly with a port-forward:

```powershell
# Hubble UI (the live eBPF flow map) — requires cilium.enabled
vagrant ssh -c "sudo k3s kubectl port-forward -n kube-system svc/hubble-ui 12000:80"
# then open http://localhost:12000
```

> The forward runs inside the VM. To reach it from your host browser, either run
> the `kubectl port-forward` over `vagrant ssh` (as above, then browse on the VM)
> or add `--address 0.0.0.0` and hit the VM IP `192.168.56.50:<local>`.

→ See [Cilium + Hubble](docs/cilium.md) · [Networking](docs/networking.md).

## License

[Apache License 2.0](LICENSE) © 2026 Xeze-org.
