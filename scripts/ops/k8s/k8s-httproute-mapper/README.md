# Kubernetes HTTPRoute Mapper (`k8s-httproute-mapper.sh`)

This Bash utility builds a routing matrix for Gateway API `HTTPRoutes` in a namespace. It expands each route's parent gateways, hostnames, path matches, and backend services into one aligned, color-coded table so you can see where traffic goes.

---

## Key Features

* **Full Route Expansion**: Expands parent gateways, hostnames, rules, path matches, and backend refs into individual rows.
* **Resilient Parsing**: Uses `*`/`/`/`None` defaults when optional fields are missing.
* **Auto-Aligned Table**: Adjusts column widths to fit the content and applies color highlighting per column.
* **Context Aware**: Optionally switches `kubectl` context and prints the active context and namespace.

---

## Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>`).

### 2. Examples

```bash
# Map HTTPRoutes in a namespace
./k8s-httproute-mapper.sh --namespace production

# Target a specific context
./k8s-httproute-mapper.sh -n smart-supply --context prod-cluster
```

---

## Output

Prints a table with the columns: **HTTPROUTE**, **PARENT GATEWAY**, **HOST (HOSTNAME)**, **PATH MATCH**, **BACKEND SERVICE**, **PORT**.

---

## Requirements

* **`kubectl`** configured with access to the target cluster.
* **`jq`** for parsing the HTTPRoute JSON.
* The **Gateway API** CRDs (`httproutes.gateway.networking.k8s.io`) installed on the cluster.
* Read permission on HTTPRoutes in the namespace.

---

## Notes

* Exits with a message if no HTTPRoutes exist in the namespace.
* Passing `--context` switches your active `kubectl` context for the session.
