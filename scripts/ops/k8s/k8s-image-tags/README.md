# Kubernetes Image Tags (`k8s-image-tags.sh`)

This Bash utility prints a **clean, aligned table of the container images** running in a namespace. For every deployment it lists each container and splits the image reference into its **repository**, **image name**, and **tag** columns.

---

## 🚀 Key Features

* **Deployment Coverage**: Iterates over all deployments and their containers in the namespace.
* **Image Decomposition**: Splits each image into repository (registry + path), image name, and tag.
* **Sane Defaults**: Falls back to `latest` when no tag is present, and `-` when there is no repository path.
* **Auto-Aligned Table**: Column widths adapt to the longest value, with color-highlighted image and tag.
* **Context Aware**: Optionally switches `kubectl` context and prints the active context/namespace.

---

## 🛠️ Usage Guide

### 1. Command Options

* `--namespace <ns>`, `-n <ns>` : Target namespace (also accepts `--namespace=<ns>` / `-n=<ns>`). Defaults to the current context namespace, or `default`.
* `--context <context>` : Optional `kubectl` context to switch to (also accepts `--context=<context>`).

### 2. Examples

```bash
# List image tags for a namespace
./k8s-image-tags.sh --namespace production

# Target a specific context
./k8s-image-tags.sh -n smart-supply --context prod-cluster
```

---

## 🔍 Output

A table printed to the console:

```
DEPLOYMENT │ CONTAINER │ REPOSITORY                        │ IMAGE   │ TAG
───────────┼───────────┼───────────────────────────────────┼─────────┼─────────
api        │ api       │ registry.example.com/team/backend │ backend │ 1.2.3
web        │ nginx     │ -                                 │ nginx   │ latest
```

---

## 📋 Requirements

* **`kubectl`** configured with access to the target cluster.
* **`jq`** for parsing deployment JSON.
* Read permission on deployments in the namespace.

---

## ⚠️ Notes

* The image reference is split on the last `/` for the repository and the last `:` for the tag.
* Passing `--context` switches your active `kubectl` context for the session.
