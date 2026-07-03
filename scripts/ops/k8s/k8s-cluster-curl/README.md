# Kubernetes Cluster Curl (`k8s-cluster-curl.sh`)

This Bash utility starts a disposable network-tester pod inside your cluster and probes a target from the pod's network view. It uses `curl` for URLs and `nc` for `host:port` targets, which makes it useful for checking in-cluster connectivity, NetworkPolicies, and egress rules.

---

## Key Features

* **In-Cluster Perspective**: Tests reachability from inside the namespace instead of from your laptop.
* **Dual Mode**:
  * **HTTP** — a verbose `curl` GET against a URL (`http://...`).
  * **Raw TCP** — a `nc` port check for `host:port` targets.
* **Ephemeral**: Runs a throwaway pod with `--rm` so nothing is left behind.
* **Interactive Fallback**: Prompts for a target when none is provided.
* **Context Aware**: Optionally switches `kubectl` context and prints the active context and namespace.

---

## Usage Guide

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

## Behaviour

* Targets containing `:` **without** `http` use a raw TCP check with a `busybox` pod (`nc -zv`).
* All other targets use an HTTP GET with a `curlimages/curl` pod (`curl -ivs`).
* Both modes run with a 5-second connect timeout.

---

## Requirements

* **`kubectl`** configured with access to the target cluster.
* Permission to `run`/`delete` pods in the namespace.
* Cluster ability to pull `busybox` and `curlimages/curl` images.

---

## Notes

* The temporary pod is named `k8s-network-tester-<timestamp>` and removed automatically.
* Passing `--context` switches your active `kubectl` context for the session.
