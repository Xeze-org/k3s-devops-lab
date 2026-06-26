# Admin passwords

The username is `admin` for every tool. One command prints the password for each tool
that's actually deployed:

```powershell
vagrant ssh -c "bash /vagrant/scripts/passwords.sh"
```

```
== Admin credentials ==

  ArgoCD   user: admin
           pass: x7Kf9...
  Grafana  user: admin
           pass: prom-operator
```

Tools you haven't enabled are skipped. Change each password after first login.

## Where each password lives

| Tool    | Source                                           |
| ------- | ------------------------------------------------ |
| ArgoCD  | secret `argocd-initial-admin-secret`             |
| Grafana | secret `monitoring-grafana`                      |
| Jenkins | secret `jenkins`                                 |
| Nexus   | file `/nexus-data/admin.password` inside the pod |

> A tool that's enabled but still syncing won't show yet — its secret doesn't exist until
> ArgoCD finishes (~3 min). Re-run the command shortly after.
