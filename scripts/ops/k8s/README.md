# Kubernetes DevOps & Productivity Toolkit

A professional-grade collection of automation shell scripts designed to streamline multi-context cluster troubleshooting, network diagnostics, configuration analysis, and day-to-day application
operations.

---

## 📋 Toolkit Overview Matrix

All scripts natively support independent Kubernetes contexts and target namespace overrides without permanently altering your active shell configurations.

| Script Name                       | Category       | Interactive? | Key Dependencies       | Primary Function                                                              |
|:----------------------------------|:---------------|:-------------|:-----------------------|:------------------------------------------------------------------------------|
| **`k8s-cluster-curl.sh`**         | Networking     | Optional     | `kubectl`              | Runs raw TCP (`nc`) or HTTP (`curl`) tests via short-lived debugging pods.    |
| **`k8s-fast-exec.sh`**            | Operations     | Yes          | `kubectl`              | Interactively selects running pods and defaults securely to `bash` or `sh`.   |
| **`k8s-httproute-mapper.sh`**     | Architecture   | No           | `kubectl`, `jq`, `awk` | Compiles a live routing matrix of Gateway API `HTTPRoutes` and backends.      |
| **`k8s-image-tags.sh`**           | Security/Audit | No           | `kubectl`, `jq`, `awk` | Maps a tabular index of all deployed image repositories, names, and tags.     |
| **`k8s-namespace-analyzer.sh`**   | Security/Audit | No           | `kubectl`, `jq`        | Runs an extensive namespace health check (Logs, Alerts, Event logs, Secrets). |
| **`k8s-pod-cleaner.sh`**          | Housekeeping   | No           | `kubectl`              | Forcefully expunges `Evicted`, `Completed`, `Error`, or `OOMKilled` pods.     |
| **`k8s-pod-kafka-test.sh`**       | Networking     | Yes          | `kubectl`, `kcat`      | Validates active pod network pathways and maps remote Kafka topic lists.      |
| **`k8s-port-forward-manager.sh`** | Operations     | Yes          | `kubectl`, `lsof`      | Clears local network port conflicts and background-runs port-forwards.        |
| **`k8s-secret-extractor.sh`**     | Security/Audit | Yes          | `kubectl`, `jq`        | Decodes application configurations into a local, deployable `.env` file.      |
| **`k8s-smart-restart.sh`**        | Operations     | Yes          | `kubectl`              | Triggers and monitors zero-downtime rolling upgrades for target workloads.    |

---

## ⚙️ Global Configuration & Flag Mechanics

Every utility script shares a unified interface syntax pattern. You can target explicit contexts or partitions directly using the following parameter overrides:

```bash
# Targeting explicitly named workspaces
./script-name.sh --context="production-cluster" --namespace="core-banking"

# Short-hand syntax alternatives
./script-name.sh -n customized-namespace
```

If these arguments are omitted, the scripts automatically discover and use your current configuration context (`kubectl config current-context`) and default namespace fallback paths.

---

## 🛠 Deep-Dive & Usage Manual

### 1. Cluster Connectivity Tester (`k8s-cluster-curl.sh`)

Spawns an ephemeral testing container within the target cluster environment to evaluate raw connectivity or network policies.

* **TCP Layer Mode:** Uses a `busybox` snapshot running `nc -zv` to assess raw target node connections.
* **HTTP Layer Mode:** Leverages a custom `curlimages/curl` instance to execute verbose headers (`curl -ivs`).

```bash
./k8s-cluster-curl.sh --target="http://internal-microservice:8080/actuator/health"
./k8s-cluster-curl.sh --target="external-database.com:5432"
```

### 2. Fast Pod Shell Exec (`k8s-fast-exec.sh`)

Provides an interactive menu targeting active pods in a namespace. It automatically performs an inline validation probe to prioritize `/bin/bash` connectivity before failing back gracefully to
structural `/bin/sh` shell wrappers.

```bash
# Interactively search and select
./k8s-fast-exec.sh

# Fast lookup by regex/string pattern filtering
./k8s-fast-exec.sh --pod="api-gateway"
```

### 3. Gateway API HTTPRoute Mapper (`k8s-httproute-mapper.sh`)

Queries the active cluster's custom routing resources (`httproutes.gateway.networking.k8s.io`). It pipes raw JSON structures through complex `jq` maps and native `awk` alignment matrix formatters to
render structural ingress path layouts.

```bash
./k8s-httproute-mapper.sh -n istio-ingress
```

### 4. Deployment Image Version Auditor (`k8s-image-tags.sh`)

Pulls the pod specification configurations across all active namespace deployments, sanitizes repository prefixes, extracts unique target application labels, and formats a real-time tracking matrix of
active tags.

```bash
./k8s-image-tags.sh --namespace=production
```

### 5. Deep Namespace Auditor (`k8s-namespace-analyzer.sh`)

Generates an extensive security compliance and health overview of an entire namespace partition. It pipes full evaluations out into local persistent text assets.

* Captures pod crashes, memory issues (`OOMKilled`), and recent infrastructure alert warning events.
* Tabulates resource consumption via metric servers (`kubectl top`).
* Extracts and dynamically base64-decodes active context cluster secret keys into a unified readable log format.
* Audits active continuous delivery tracking paths (Flux CD `GitRepositories` & `Kustomizations`).

```bash
./k8s-namespace-analyzer.sh -n core-payment
```

*Outputs compiled analytics artifacts to: `./results/namespace_audit_[namespace]_[timestamp].txt`*

### 6. Evicted & Dead Pods Purger (`k8s-pod-cleaner.sh`)

Sweeps your active namespace partitions to locate and purge stale pod references. It extracts tracking references matching `Evicted`, `Completed`, `Error`, or `OOMKilled` signatures and initiates
zero-grace-period force evictions (`--grace-period=0 --force`).

```bash
./k8s-pod-cleaner.sh
```

### 7. Live Kafka Connectivity Analyzer (`k8s-pod-kafka-test.sh`)

A diagnostic framework that executes a multi-layered verification check:

1. **Network Pass:** Tests the physical TCP network layers directly from inside a running application pod using a standard handshake probe.
2. **Protocol Pass:** Spawns a temporary container image running `edenhill/kcat` inside the cluster partition to query the remote cluster bootstrap server (`-B`), downloading live broker layout
   metrics and discovering active target topics.

```bash
./k8s-pod-kafka-test.sh --pod="backend-worker" --broker="kafka-cluster-bootstrap.kafka.svc:9092"
```

### 8. Background Port-Forward Manager (`k8s-port-forward-manager.sh`)

Automates host-to-cluster connection forwarding. The script reads local connections using `lsof`, identifies and terminates conflicting background system processes blocking the target local execution
port (`kill -9`), and safely deploys background instances via `nohup`.

```bash
./k8s-port-forward-manager.sh --port=8082
```

*Verifies tracking access metrics via standard background redirects directly to: `http://localhost:[port]`*

### 9. Environment File Extractor (`k8s-secret-extractor.sh`)

A utility for local testing setup. It connects to active runtime pods, extracts configuration values across hardcoded variables, processes global configuration schemas (`envFrom`), maps structural
storage references, and unifies them into a clean, local `.env` format.

```bash
./k8s-secret-extractor.sh
```

*Saves variables to: `./results/[deployment_name]_[namespace]_[context].env`*

### 10. Zero-Downtime Rollout Operator (`k8s-smart-restart.sh`)

Triggers an orderly, zero-downtime configuration rolling restart across target cluster apps. It safely initializes structural pod updates while establishing an inline synchronous status monitoring
terminal watch (`rollout status`).

```bash
./k8s-smart-restart.sh
```

---

## 📂 Internal Directory Layout Strategy

To maintain a clean working directory, several tools automatically save reports and assets to an isolated `results` subdirectory:

```text
📁 k8s-toolkit/
├── 📄 k8s-cluster-curl.sh
├── 📄 k8s-fast-exec.sh
├── 📄 k8s-httproute-mapper.sh
├── 📄 k8s-image-tags.sh
├── 📄 k8s-namespace-analyzer.sh
├── 📄 k8s-pod-cleaner.sh
├── 📄 k8s-pod-kafka-test.sh
├── 📄 k8s-port-forward-manager.sh
├── 📄 k8s-secret-extractor.sh
├── 📄 k8s-smart-restart.sh
└── 📁 results/
    ├── 📄 namespace_audit_default_20260704_150000.txt
    └── 📄 smart-supply-api_default_prod_cluster.env
```

---

## 🚀 Execution Onboarding

Ensure execution privileges are correctly applied across your local workspace:

```bash
# Grant executable permissions across the toolkit
chmod +x k8s-*.sh

# Verify core command line application dependencies are met
command -v kubectl jq lsof >/dev/null 2>&1 || echo "Warning: Ensure kubectl, jq, and lsof are installed."
```