# Kubernetes Port-Forward Manager (`k8s-port-forward-manager.sh`)

This Bash utility gives you an interactive way to port-forward a Kubernetes deployment to your local machine. It lists deployments in a namespace, lets you choose one, frees the local port if it is already in use, and starts the port-forward as a resilient background process.

---

## Key Features

* **Interactive selection**: Lists deployments in the namespace and prompts you to choose one.
* **Automatic port cleanup**: Detects any local process already bound to the target port and kills it before forwarding.
* **Resilient background process**: Starts `kubectl port-forward` with `nohup` + `disown` so it survives terminal closure.
* **Startup verification**: Confirms the forward started; if it fails, prints the captured `kubectl` error output.

---

## Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--port <port>`, `-p <port>` : Local and remote port to forward (also accepts `--port=<port>` / `-p=<port>`). Defaults to `8080`.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>`).

### 2. Examples

```bash
# Forward a deployment on the default port (8080)
./k8s-port-forward-manager.sh --namespace production

# Forward on a custom port and specific context
./k8s-port-forward-manager.sh -n smart-supply -p 9090 --context prod-cluster
```

After selecting a deployment, the service becomes available at `http://localhost:<port>`.

---

## Behaviour

1. Resolves the namespace and lists available deployments.
2. Prompts for an interactive selection.
3. Checks port `<port>` locally and kills the occupying process if needed.
4. Starts `kubectl port-forward deployment/<name> <port>:<port>` in the background.
5. Verifies the process is alive and prints the local access URL, or the error output on failure.

---

## Requirements

* **`kubectl`** configured with access to the target cluster.
* **`lsof`** (used to detect the process occupying the local port).
* Permission to `port-forward` deployments in the namespace.

---

## Notes

* The same port number is used for **both** the local and the remote side (`<port>:<port>`).
* The background process is detached (`disown`); to stop it later, find and kill it manually (e.g. `lsof -t -i :<port>` then `kill`).
* The target deployment must have at least one **ready** pod for the forward to succeed.
* Passing `--context` switches your active `kubectl` context for the session.
