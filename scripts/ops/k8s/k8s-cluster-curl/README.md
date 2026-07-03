# Kubernetes Cluster Curl (`k8s-cluster-curl.sh`)

This Bash utility spawns a **disposable network-tester pod** inside your cluster to probe a target from a pod's network perspective. It runs an HTTP request (via `curl`) for URLs, or a raw TCP port check (via `nc`) for `host:port` targets — perfect for debugging in-cluster connectivity, NetworkPolicies, and egress rules.

---

## 🚀 Key Features

* **In-Cluster Perspective**: Tests reachability from inside the namespace, not from your laptop.
* **Dual Mode**:
  * **HTTP** — a verbose `curl` GET against a URL (`http://...`).
  * **Raw TCP** — a `nc` port check for `host:port` targets.
* **Ephemeral**: Runs a throwaway pod with `--rm` so nothing is left behind.
* **Interactive Fallback**: Prompts for a target if none is provided.
* **Context Aware**: Optionally switches `kubectl` context and prints the active context/namespace.

---

## 🛠️ Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--target <url|host:port>`, `-t <...>` : Target to probe (also accepts `--target=<...>` / `-t=<...>`). Prompted interactively if omitted.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>` / `--ctx=<context>`).

### 2. Examples

```bash
# HTTP health check against an internal service
./k8s-cluster-curl.sh -n smart-supply -t http://smart-supply-api:8080/actuator/health

# Raw TCP port check against an external host
./k8s-cluster-curl.sh -n smart-supply -t google.com:443

# Interactive target prompt
./k8s-cluster-curl.sh --namespace production
```

---

## 🔍 Behaviour

* Targets containing `:` **without** `http` → raw TCP check using a `busybox` pod (`nc -zv`).
* All other targets → HTTP GET using a `curlimages/curl` pod (`curl -ivs`).
* Both run with a 5-second connect timeout.

---

## 📋 Requirements

* **`kubectl`** configured with access to the target cluster.
* Permission to `run`/`delete` pods in the namespace.
* Cluster ability to pull `busybox` and `curlimages/curl` images.

---

## ⚠️ Notes

* The temporary pod is named `k8s-network-tester-<timestamp>` and removed automatically.
* Passing `--context` switches your active `kubectl` context for the session.
