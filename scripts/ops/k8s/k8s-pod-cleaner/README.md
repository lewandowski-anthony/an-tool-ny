# Kubernetes Pod Cleaner (`k8s-pod-cleaner.sh`)

This Bash utility scans a namespace for **dead pods** — `Evicted`, `Completed`, `Error`, or `OOMKilled` — and force-deletes them, keeping your namespace tidy.

---

## 🚀 Key Features

* **Targeted Cleanup**: Matches pods in `Evicted`, `Completed`, `Error`, and `OOMKilled` states.
* **Force Delete**: Removes each stale pod with `--grace-period=0 --force`.
* **Safe When Clean**: Reports success and does nothing when there is nothing to purge.
* **Context Aware**: Optionally switches `kubectl` context and prints the active context/namespace.

---

## 🛠️ Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>`).

### 2. Examples

```bash
# Clean dead pods in a namespace
./k8s-pod-cleaner.sh --namespace production

# Target a specific context
./k8s-pod-cleaner.sh -n smart-supply --context prod-cluster
```

---

## 🔍 Behaviour

1. Lists pods matching `Evicted|Completed|Error|OOMKilled`.
2. If none are found, prints a "clean" confirmation.
3. Otherwise, force-deletes each matched pod and reports completion.

---

## 📋 Requirements

* **`kubectl`** configured with access to the target cluster.
* Permission to `delete` pods in the namespace.

---

## ⚠️ Notes

* Deletion is **forced** (`--grace-period=0 --force`) — use with care, as it skips graceful termination.
* `Completed` pods (e.g. finished Jobs) are included in the purge.
* Passing `--context` switches your active `kubectl` context for the session.
