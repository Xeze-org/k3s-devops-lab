# KEDA — event-driven autoscaling

[KEDA](https://keda.sh) scales workloads on *events* — a queue depth, a cron
window, a Prometheus metric — and uniquely can scale **to zero** when idle
(plain HPA floors at 1 replica). It's a live ArgoCD toggle like the other tools.

| Flag   | Installs                              | URL       |
| ------ | ------------------------------------- | --------- |
| `keda` | KEDA controller **+ a Cron demo**     | — (no UI) |

## Enable / disable

```yaml
# gitops/root/values.yaml
keda:
  enabled: true     # false = ArgoCD prunes it
```
`git push` → ArgoCD reconciles within ~3 min. (`keda` is light, ~512MB; no
`vagrant reload` needed.)

## What gets installed

Two ArgoCD Applications (`gitops/root/templates/keda.yaml`):

1. **`keda`** — the controller (operator + metrics API server + admission
   webhook) from the `kedacore` Helm chart, into namespace `keda`.
2. **`keda-demo`** — a self-contained demo in namespace `keda-demo`
   (`gitops/apps/keda-demo/`): a tiny nginx Deployment + a `ScaledObject` with a
   **Cron trigger** that scales it `0 → 3` for 5 minutes every 10 minutes, then
   back to 0.

## Watch it scale

```bash
vagrant ssh
sudo k3s kubectl get scaledobject,hpa,deploy,pods -n keda-demo -w
```
On the window boundary (minutes `0,10,20,…`) replicas climb to 3; after the
window + `cooldownPeriod` (60s) they fall back to 0.

## Key details

- The demo Deployment **omits `replicas`** on purpose — KEDA generates an HPA
  that owns that field. Pinning it would fight the autoscaler.
- `minReplicaCount: 0` is KEDA's headline feature (scale-to-zero); regular HPA
  cannot do this.
- The `keda-demo` ArgoCD app uses `SkipDryRunOnMissingResource=true` so it
  settles before KEDA's `ScaledObject` CRD exists (ArgoCD retries until green).

## Write your own ScaledObject

Drop a manifest in `gitops/apps/keda-demo/` (or a new app dir) and push. KEDA
supports 60+ scalers — Kafka, RabbitMQ, Prometheus, AWS SQS, cron, CPU/memory.
A Prometheus-based scaler needs `monitoring.enabled: true`.

→ See also: [Tools & toggling](tools.md) · [VM sizing](vm-sizing.md)
