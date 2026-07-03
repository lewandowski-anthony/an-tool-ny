# Kubernetes Namespace Analyzer (`k8s-namespace-analyzer.sh`)

This Bash utility audits a Kubernetes namespace in one pass and writes a colorized report that is easy to scan. It covers workload health, resource usage, networking, secrets, GitOps resources, storage, and common warning signs so you can quickly understand what is running in a namespace.

---

## Key Features

* **Alerts & Anomalies**: Highlights pods that are not `Running`/`Completed`, including crash, pending, and error states.
* **Pods Overview**: Shows name, readiness, status, restart count, IP, and age in a compact table.
* **Resource Consumption**: Reports top pod CPU and memory usage through `kubectl top` when metrics are available.
* **Recent Unhealthy Events**: Shows the last 15 warning, error, kill, and OOM-related events.
* **Networking & Routing**: Lists Services, Ingresses, and Gateway API `HTTPRoutes` when the CRD is present.
* **Secrets Inspection**: Lists every secret and **base64-decodes** its data.
* **GitOps State**: Shows Flux CD `GitRepositories` and `Kustomizations` when the CRDs are present.
* **Configs & Storage**: Reports ConfigMap and PVC counts, plus PVC details.
* **Workloads Status**: Summarizes Deployments, StatefulSets, and CronJobs.
* **Saved Report**: Writes the full output, including color codes, to a timestamped file under `results/`.

---

## Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--context <context>` : Optional `kubectl` context to switch to before auditing (also accepts `--context=<context>`).

### 2. Examples

```bash
# Audit an explicit namespace
./k8s-namespace-analyzer.sh --namespace production

# Audit using a specific context
./k8s-namespace-analyzer.sh -n smart-supply --context prod-cluster
```

---

## Output

The report is printed to the console with `tee` and saved under the `results/` directory:

* `results/namespace_audit_<namespace>_<timestamp>.txt`

> The saved file keeps ANSI color codes. View it with `cat` / `less -R` to keep the colors, or strip them for plain text.

---

## Requirements

* **`kubectl`** configured with access to the target cluster.
* **`jq`** for decoding secret data.
* `kubectl top` requires the **metrics-server** to be installed.
* Read permissions (`get`/`list`) on pods, events, services, ingresses, secrets, configmaps, PVCs, and workloads.

---

## Notes

* **Warning:** The Secrets section decodes and prints secret values in clear text. Treat the generated report as sensitive and do not commit it.
* Gateway API (`httproutes`) and Flux CD (`gitrepositories`, `kustomizations`) sections are skipped gracefully when the corresponding CRDs are not installed.
* Passing `--context` switches your active `kubectl` context for the session.
