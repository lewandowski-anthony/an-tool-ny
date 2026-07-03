# Universal Resource Analyzer (`app-ressources-analyze.sh`)

This Bash utility analyzes resource usage for applications running in **Kubernetes**. It can resolve one or many pods from a name or regex, detect each pod's technology stack, and write a consolidated report. For Java workloads it adds **JVM-specific diagnostics**; for other stacks such as Node, Nginx, or Python, it focuses on **log/traffic analysis**.

---

## Key Features

* **Multi-Pod Resolution**: Accepts an exact pod name or a **regex** and analyzes every matching pod in one run.
* **Automatic Stack Detection**: Inspects the running processes to classify each pod as:
  * **Java/JVM** (Spring Boot, Quarkus...)
  * **Node.js** (SSR frontend / BFF)
  * **Nginx** (static front / proxy)
  * **Python** (FastAPI, Django, Flask)
  * **Generic/Unknown** (fallback)
* **Adaptive Diagnostics**:
  * **Java pods** → live heap histogram (`jmap -histo:live`) and active execution hotspots (`jcmd Thread.print`).
  * **Non-Java pods** → traffic/endpoint analysis and top error patterns from the last 3000 log lines.
* **Capacity vs. Usage**: Compares CPU/memory **requests** and **limits** against live usage from `kubectl top`.
* **Stability Insight**: Reports pod IP, restart count, and the last crash reason.
* **Process Fallback**: Tries `ps aux` → `ps -ef` → `top` to remain compatible with distroless/slim images.
* **Consolidated Report**: Writes all pod results to one timestamped file under `results/`.

---

## Usage Guide

### 1. Command Options

* `--k8s`, `--kube` : Enable Kubernetes mode (**required**)
* `--pod <name_or_regex>` : Pod name or regex to match one or more pods (**required**)
* `--namespace <ns>`, `-n <ns>` : Kubernetes namespace (**required**)
* `--context <context>` : Optional `kubectl` context to target a specific cluster

### 2. Examples

#### Single pod
```bash
./app-ressources-analyze.sh \
--k8s \
--pod my-service-7d9f8c6b5-abcde \
--namespace production
```

#### Multiple pods via regex
```bash
./app-ressources-analyze.sh \
--k8s \
--pod "backend-.*" \
--namespace production \
--context prod-cluster
```

---

## Output

The consolidated diagnostic is printed to the console and stored under the `results/` directory:

* `results/universal_analysis_<pattern>_<timestamp>.txt`

For each matching pod the report contains:

1. **Identity & Stack** — detected technology, IP, restart count and last crash reason.
2. **Resource Capacity vs. Usage** — CPU/memory requested, current, and limit.
3. **Adaptive Section**:
   * *Java*: top heap object allocations and active execution hotspots.
   * *Other*: traffic/endpoint hits and top error patterns.
4. **Internal Running Processes** — processes observed inside the container.

---

## Requirements

* **`kubectl`** configured with access to the target cluster.
* **`jq`** for parsing pod JSON.
* Permission to run `kubectl get`, `kubectl top`, `kubectl exec`, and `kubectl logs`.
* For full JVM diagnostics, the Java container image must ship the **JDK tools** (`jcmd`, `jmap`).

---

## Notes

* The script runs in Kubernetes mode only — it exits with an error if `--pod` or `--namespace` is missing.
* `kubectl top` requires the **metrics-server** to be installed in the cluster.
* The `--pod` value is treated as a regex; anchor it (e.g. `^backend$`) if you need an exact match.
* Stack detection relies on inspecting container processes; distroless/slim images without `ps`/`top` may fall back to `Generic/Unknown`.
* The heap histogram (`jmap -histo:live`) triggers a full GC on the target JVM; use it deliberately on production workloads.
