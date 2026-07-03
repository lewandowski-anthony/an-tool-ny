# 🧰 an-tool-ny

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/lewandowski-anthony/an-tool-ny/graphs/commit-activity)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **an-tool-ny** /ɑ̃.tul.ni/ (noun): Anthony Lewandowski's daily toolbox. Contains everything needed to survive the workday, automate repetitive tasks, and avoid typing the exact same commands 50
> times a day.

Welcome to my digital Swiss Army knife. This repository centralizes all my scripts, configurations, and little utilities that keep me productive (and efficiently lazy) every single day.

---

## 🚀 What's Inside

The repository is structured to keep things clean and easy to find:

* 📂 `scripts/`: Automation scripts (Bash, Python, PowerShell, etc.).
* ⚙️ `config/`: Configuration files, custom aliases, and dotfiles.
* 📝 `templates/`: Reusable file templates for daily work.
* 🛠️ `utils/`: Miscellaneous helper tools.

## 🧰 Available Tools

A catalogue of the scripts currently living in this toolbox. Tools with a dedicated `README.md` are linked for detailed usage.

### 🗄️ Database

| Tool                                                                         | Description                                                                                                                                         |
|------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| [`pg-data-generator.sh`](scripts/database/data-generator/postgres/README.md) | Introspects a PostgreSQL schema and pushes random, type-safe data while respecting FK order and constraints. Supports `--rows` for bulk generation. |
| [`db-schema-extractor.sh`](scripts/database/schema-extractor/README.md)      | Extracts a database schema into a portable, readable output.                                                                                        |

### ☸️ Kubernetes / Ops

| Tool                                                                          | Description                                                                                                                 |
|-------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| [`k8s-namespace-analyzer.sh`](scripts/ops/k8s/k8s-analyzer/README.md)         | Full audit of a namespace: anomalies, pods, resource usage, events, networking, secrets, Flux CD state, and workloads.      |
| [`k8s-port-forward-manager.sh`](scripts/ops/k8s/k8s-port-forwarder/README.md) | Interactive port-forward manager: pick a deployment, free the local port, and forward it as a resilient background process. |
| [`k8s-secret-extractor.sh`](scripts/ops/k8s/k8s-secret-extractor/README.md)   | Reconstructs a deployment's full `.env` (inline, `envFrom`, and `valueFrom` refs) with decoded secrets.                     |
| [`k8s-fast-exec.sh`](scripts/ops/k8s/k8s-fast-exec/README.md)                 | Opens an instant interactive shell in a pod (`bash` with `sh` fallback), via menu or name/regex.                            |
| [`k8s-image-tags.sh`](scripts/ops/k8s/k8s-image-tags/README.md)               | Prints an aligned table of running container images, split into repository / image / tag columns.                           |
| [`k8s-cluster-curl.sh`](scripts/ops/k8s/k8s-cluster-curl/README.md)           | Spawns a disposable pod to probe a target from inside the cluster (HTTP `curl` or raw TCP `nc`).                            |
| [`k8s-httproute-mapper.sh`](scripts/ops/k8s/k8s-httproute-mapper/README.md)   | Builds a routing matrix of Gateway API HTTPRoutes: gateways, hostnames, paths, and backend services.                        |
| [`k8s-pod-cleaner.sh`](scripts/ops/k8s/k8s-pod-cleaner/README.md)             | Force-deletes dead pods (`Evicted`, `Completed`, `Error`, `OOMKilled`) in a namespace.                                      |
| [`k8s-pod-kafka-test.sh`](scripts/ops/k8s/k8s-pod-kafka-test/README.md)       | Two-stage Kafka diagnostic from a pod: TCP reachability then `kcat` broker metadata / topic discovery.                      |
| [`k8s-smart-restart.sh`](scripts/ops/k8s/k8s-smart-restart/README.md)         | Interactive zero-downtime rollout restart of a deployment, with live rollout status monitoring.                             |
| `port-killer.sh`                                                              | Frees a local port by identifying and terminating the occupying process (Docker-aware). Usage: `port-killer.sh <port>`.     |

### 🛠️ Dev

| Tool                                                           | Description                                                                              |
|----------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [`app-ressources-analyze.sh`](scripts/dev/resources/README.md) | Analyzes CPU/memory resource usage of one or more Kubernetes pods matched by name/regex. |

### 🐳 Docker

| Tool                         | Description                                                                                          |
|------------------------------|------------------------------------------------------------------------------------------------------|
| `docker-clean-containers.sh` | Nukes the local Docker environment: stops/removes all containers, volumes, and non-default networks. |
| `docker-scan-component.sh`   | Scans Dockerfiles/images for vulnerabilities using Trivy and writes a consolidated report.           |

### 🌿 Git

| Tool                    | Description                                                                                                          |
|-------------------------|----------------------------------------------------------------------------------------------------------------------|
| `git-purge-branches.sh` | Fetches, prunes, and deletes local branches already merged into the main branch. Optional target directory argument. |

### 🌐 Web

| Tool             | Description                                                                                     |
|------------------|-------------------------------------------------------------------------------------------------|
| `jwt-decoder.sh` | Decodes and pretty-prints the header and payload of a JWT. Usage: `jwt-decoder.sh <jwt_token>`. |

## 🛠️ Setup & Usage

To clone this masterpiece to your local machine:

```bash
git clone [https://github.com/lewandowski-anthony/an-tool-ny.git](https://github.com/lewandowski-anthony/an-tool-ny.git)
cd an-tool-ny
```

## 🧠 Project Philosophy

If you have to do it more than twice, automate it.

If the script is ugly but it works, it belongs here.

Always test locally before running a tool that could break production (ideally).

## 📄 License

This project is licensed under the MIT License. Feel free to copy these scripts to look like a wizard in front of your coworkers.

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.