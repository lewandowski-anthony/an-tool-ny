# Kubernetes Fast Exec (`k8s-fast-exec.sh`)

This Bash utility gives you an **instant interactive shell** inside a Kubernetes pod. Either pick a running pod from an interactive menu or target one directly by name/regex, and the script opens a `bash` session (falling back to `sh` when `bash` is unavailable).

---

## 🚀 Key Features

* **Interactive Selection**: Lists running pods in the namespace and prompts you to choose one.
* **Direct Targeting**: Skip the menu by passing a pod name or regex; the first match is used.
* **Smart Shell Detection**: Opens `bash` when present, otherwise gracefully falls back to `sh`.
* **Context Aware**: Optionally switches `kubectl` context and prints the active context/namespace before connecting.

---

## 🛠️ Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--pod <name|regex>`, `-p <name|regex>` : Pod to connect to (also accepts `--pod=<...>` / `-p=<...>`). When omitted, an interactive menu is shown.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>`).

### 2. Examples

```bash
# Interactive: pick a running pod from a menu
./k8s-fast-exec.sh --namespace production

# Direct: connect to the first pod matching a regex
./k8s-fast-exec.sh -n smart-supply -p "api-.*"

# Target a specific context
./k8s-fast-exec.sh -n smart-supply -p api --context prod-cluster
```

---

## 🔍 Behaviour

1. Optionally switches to the provided `kubectl` context.
2. Resolves the namespace (flag → current context → `default`).
3. Selects the target pod (interactive menu of **running** pods, or first regex match).
4. Prints the resolved context, namespace, and pod.
5. Execs into the pod with `bash`, falling back to `sh` if `bash` is missing.

---

## 📋 Requirements

* **`kubectl`** configured with access to the target cluster.
* Permission to `exec` into pods in the namespace.

---

## ⚠️ Notes

* The interactive menu only lists pods in the `Running` phase; direct `--pod` matching considers all pods.
* When a regex matches multiple pods, only the **first** match is used.
* Passing `--context` switches your active `kubectl` context for the session.
