# VM auto-sizing

RAM and CPU are computed from the enabled flags in `values.yaml`:

- base **4 GB / 4 CPU**
- `+1 GB` monitoring
- `+0.5 GB` Loki
- `+2 GB / +1 CPU` each for Jenkins and Nexus

…clamped to **4–8 GB / 4–8 CPU**.

Override with `VM_MEMORY` / `VM_CPUS` in `.env`.

> You can't comfortably run both heavy tools (Jenkins + Nexus) at once — that's the point
> of the toggles. After toggling a heavy tool, run `vagrant reload` so the VM resizes.
