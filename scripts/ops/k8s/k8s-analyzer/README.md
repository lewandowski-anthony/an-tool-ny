# Kubernetes Namespace Analyzer (`k8s-namespace-analyzer.sh`)

This Bash utility performs a **full audit of a Kubernetes namespace** in a single pass and produces a colorized, human-readable report. It surfaces anomalies, workload health, resource consumption, networking, secrets, GitOps state, and storage — giving you a one-shot snapshot of everything running in a namespace.

---

## 🚀 Key Features

* **Alerts & Anomalies**: Highlights pods that are not `Running`/`Completed` (crashed, pending, error states).
* **Pods Overview**: Name, readiness, status, restart count, IP, and age in a compact table.
* **Resource Consumption**: Top pod CPU/memory usage via `kubectl top` (metrics-server).
* **Recent Unhealthy Events**: The last 15 warning/error/kill/OOM events.
* **Networking & Routing**: Services, Ingresses, and Gateway API `HTTPRoutes` (when the CRD is present).
* **Secrets Inspection**: Lists every secret and **base64-decodes** its data.
* **GitOps State**: Flux CD `GitRepositories` and `Kustomizations` (when the CRDs are present).
* **Configs & Storage**: ConfigMap and PVC counts, plus PVC details.
* **Workloads Status**: Deployments, StatefulSets, and CronJobs.
* **Saved Report**: Full output (with color codes) written to a timestamped file under `results/`.

---

## 🛠️ Usage Guide

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

## 🔍 Output

The report is printed to the console (via `tee`) and stored under the `results/` directory:

* `results/namespace_audit_<namespace>_<timestamp>.txt`

> The saved file preserves ANSI color codes. View it with `cat` / `less -R` to keep the colors, or strip them for plain text.

---

## 📋 Requirements

* **`kubectl`** configured with access to the target cluster.
* **`jq`** for decoding secret data.
* `kubectl top` requires the **metrics-server** to be installed.
* Read permissions (`get`/`list`) on pods, events, services, ingresses, secrets, configmaps, PVCs, and workloads.

---

## ⚠️ Notes

* **Security**: The Secrets section decodes and prints secret values in clear text. Handle the generated report file with care and avoid committing it.
* Gateway API (`httproutes`) and Flux CD (`gitrepositories`, `kustomizations`) sections are skipped gracefully when the corresponding CRDs are not installed.
* Passing `--context` switches your active `kubectl` context for the session.
