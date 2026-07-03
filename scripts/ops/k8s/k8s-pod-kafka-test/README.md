# Kubernetes Kafka Connectivity Test (`k8s-pod-kafka-test.sh`)

This Bash utility runs a **two-stage Kafka connectivity diagnostic** from inside a running application pod. It first verifies raw TCP reachability to a broker, then spawns a temporary `kcat` pod to fetch cluster metadata and list topics — helping you distinguish network issues from Kafka-level (auth/listener) issues.

---

## 🚀 Key Features

* **Stage 1 — Network Layer**: TCP handshake test from the app pod using `nc`, with fallbacks to bash `/dev/tcp` or `telnet`.
* **Stage 2 — Kafka Layer**: Spawns an ephemeral `kcat` pod to query broker metadata and discovered topics.
* **Interactive or Direct**: Select the source pod from a menu or target it by name/regex; broker can be passed or prompted.
* **Actionable Diagnostics**: Clear guidance when the network fails (NetworkPolicies/egress) vs. Kafka metadata fails (SASL/SSL/listeners).
* **Context Aware**: Optionally switches `kubectl` context and prints the active context/namespace.

---

## 🛠️ Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--pod <name|regex>`, `-p <...>` : Source application pod (also accepts `--pod=<...>` / `-p=<...>`). Interactive menu if omitted.
* `--broker <host:port>`, `-b <...>` : Kafka bootstrap broker (also accepts `--broker=<...>` / `-b=<...>`). Prompted if omitted.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>`).

### 2. Examples

```bash
# Fully interactive (pick pod, prompt for broker)
./k8s-pod-kafka-test.sh --namespace production

# Direct: pod by regex + explicit broker
./k8s-pod-kafka-test.sh -n smart-supply -p "api-.*" -b kafka-cluster-kafka-bootstrap:9092
```

---

## 🔍 Output

* **[1/2]** TCP handshake result (success/failure with remediation hints).
* **[2/2]** Kafka metadata result plus a list of topics discovered on the cluster.

---

## 📋 Requirements

* **`kubectl`** configured with access to the target cluster.
* Permission to `exec` into pods and `run`/`delete` pods in the namespace.
* Cluster ability to pull `edenhill/kcat:1.7.1`.
* The source pod must provide `nc`, `bash`, or `telnet` for the network test.

---

## ⚠️ Notes

* The temporary broker-probe pod is named `kcat-diagnostic-<timestamp>` and removed automatically.
* Stage 2 may fail even when the network is healthy if Kafka requires SASL/SSL or has misconfigured external listeners.
* Passing `--context` switches your active `kubectl` context for the session.
