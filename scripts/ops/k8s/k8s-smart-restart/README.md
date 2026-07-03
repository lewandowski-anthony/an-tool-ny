# Kubernetes Smart Restart (`k8s-smart-restart.sh`)

This Bash utility guides you through an interactive rollout restart of a deployment with no expected downtime. It lists deployments in a namespace, lets you choose one, runs `kubectl rollout restart`, and follows the rollout until it completes.

---

## Key Features

* **Interactive selection**: Lists deployments in the namespace and prompts you to choose one.
* **Zero-downtime restart**: Uses `kubectl rollout restart` to recreate pods gracefully.
* **Live monitoring**: Streams `kubectl rollout status` until the rollout finishes.
* **Context aware**: Can switch `kubectl` context and shows the active context and namespace.

---

## Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>`).

### 2. Examples

```bash
# Restart a deployment in a namespace
./k8s-smart-restart.sh --namespace production

# Target a specific context
./k8s-smart-restart.sh -n smart-supply --context prod-cluster
```

You will then be prompted to select the target deployment from a list.

---

## Behaviour

1. Lists deployments in the namespace.
2. Prompts for an interactive selection.
3. Runs `kubectl rollout restart deployment/<name>`.
4. Monitors and prints the rollout status until completion.

---

## Requirements

* **`kubectl`** configured with access to the target cluster.
* Permission to `patch`/`get` deployments in the namespace.

---

## Notes

* A rollout restart respects the deployment's update strategy (e.g. rolling update) for zero downtime.
* Passing `--context` switches your active `kubectl` context for the session.
