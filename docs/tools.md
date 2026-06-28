# Tools & toggling

Enable only what you need in `gitops/root/values.yaml`. ArgoCD installs enabled tools and
prunes disabled ones.

| Flag         | Tool                        | URL                      |
| ------------ | --------------------------- | ------------------------ |
| (always on)  | ArgoCD                      | `argocd.<domain>`        |
| `monitoring` | Prometheus + Grafana        | `grafana.<domain>`       |
| `loki`       | Loki (logs, via Grafana)    | — (no UI)                |
| `jenkins`    | Jenkins CI                  | `jenkins.<domain>`       |
| `nexus`      | Nexus Repository Manager    | `nexus.<domain>`         |
| `harbor`     | Harbor registry (optional)  | `registry.<domain>`      |

Nexus also serves as the Docker registry, so Harbor is usually left off — see
[Docker registry](docker-registry.md).

## How toggling works

```mermaid
flowchart LR
  ed[Edit enabled: in values.yaml] --> pu[git push]
  pu --> ad{ArgoCD diff}
  ad -->|true| inst[install tool]
  ad -->|false| prune[prune tool]
```

Edit a flag, `git push`, and ArgoCD reconciles within ~3 min. If you enable/disable a
**heavy** tool (Jenkins/Nexus), run `vagrant reload` so the VM resizes. To force ArgoCD
immediately:

```powershell
vagrant ssh -c "bash /vagrant/scripts/sync.sh"
```

→ See also: [VM sizing](vm-sizing.md) · [Passwords](passwords.md) · [Docker registry](docker-registry.md)
