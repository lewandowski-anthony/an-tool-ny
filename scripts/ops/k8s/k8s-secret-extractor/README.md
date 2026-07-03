# Kubernetes Secret / Env Extractor (`k8s-secret-extractor.sh`)

This Bash utility reconstructs the full runtime environment (`.env`) for a Kubernetes deployment. You pick a deployment, it inspects one of its pods, then resolves each environment variable: inline values, `envFrom` secrets/configmaps, and individually mapped `valueFrom` references, decoding secrets along the way.

---

## Key Features

* **Interactive selection**: Lists deployments in the namespace and prompts you to choose one.
* **Smart pod resolution**: Finds a backing pod via `app.kubernetes.io/name`, then `app` labels, then a name-prefix fallback.
* **Complete env reconstruction**, grouped by source:
  * Hardcoded `env` values.
  * Bulk `envFrom` **Secrets** (base64-decoded).
  * Bulk `envFrom` **ConfigMaps**.
  * Individually mapped `valueFrom` **secretKeyRef** (decoded).
  * Individually mapped `valueFrom` **configMapKeyRef**.
* **Ready-to-use output**: Writes a clean `.env` file named after the deployment, namespace, and context.

---

## Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>`).

### 2. Examples

```bash
# Extract the env of a deployment in a namespace
./k8s-secret-extractor.sh --namespace production

# Target a specific context
./k8s-secret-extractor.sh -n smart-supply --context prod-cluster
```

You will then be prompted to select the target deployment from a list.

---

## Output

The reconstructed environment file is stored under the `results/` directory:

* `results/<deployment>_<namespace>_<context>.env`

Each section is annotated with a comment header indicating the source of the variables (hardcoded, `envFrom` secret/configmap, or specific `valueFrom` mapping).

---

## Requirements

* **`kubectl`** configured with access to the target cluster.
* **`jq`** for parsing pod, secret, and configmap JSON.
* **`base64`** for decoding secret values.
* Read permissions on pods, secrets, and configmaps in the namespace.

---

## Notes

* **Security**: The generated `.env` contains **decoded secret values in clear text**. Treat it as sensitive and do not commit it to version control.
* If no environment variables are found, the empty output file is removed automatically.
* The script inspects the **first container** of the resolved pod.
* Passing `--context` switches your active `kubectl` context for the session.
