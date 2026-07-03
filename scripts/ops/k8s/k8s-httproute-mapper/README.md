# Kubernetes HTTPRoute Mapper (`k8s-httproute-mapper.sh`)

This Bash utility builds a **routing matrix** of the Gateway API `HTTPRoutes` in a namespace. It flattens each route's parent gateways, hostnames, path matches, and backend services into a single aligned, color-coded table — giving you a clear picture of how traffic is routed.

---

## 🚀 Key Features

* **Full Route Expansion**: Explodes parent gateways, hostnames, rules, path matches, and backend refs into individual rows.
* **Resilient Parsing**: Gracefully substitutes `*`/`/`/`None` defaults for missing fields.
* **Auto-Aligned Table**: Column widths adapt to content, with color highlighting per column.
* **Context Aware**: Optionally switches `kubectl` context and prints the active context/namespace.

---

## 🛠️ Usage Guide

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

## 🔍 Output

A table with the columns: **HTTPROUTE**, **PARENT GATEWAY**, **HOST (HOSTNAME)**, **PATH MATCH**, **BACKEND SERVICE**, **PORT**.

---

## 📋 Requirements

* **`kubectl`** configured with access to the target cluster.
* **`jq`** for parsing the HTTPRoute JSON.
* The **Gateway API** CRDs (`httproutes.gateway.networking.k8s.io`) installed on the cluster.
* Read permission on HTTPRoutes in the namespace.

---

## ⚠️ Notes

* Exits with a message if no HTTPRoutes exist in the namespace.
* Passing `--context` switches your active `kubectl` context for the session.
