# Spring Resource Analyzer (`spring-resource-analyzer.sh`)

This Bash utility produces a resource-consumption diagnostic for a Spring Boot (JVM) application running inside a **Kubernetes** pod. It correlates the pod's overall CPU and RAM usage with what is happening *inside* the JVM — top heap allocations and the most active execution hotspots — so you can quickly explain **why** a pod is consuming memory or CPU.

---

## 🚀 Key Features

* **Pod-Level Metrics**: Reads total CPU and RAM usage via `kubectl top pod`.
* **RAM Explanation**: Runs a live heap histogram (`jmap -histo:live`) to show the objects currently occupying the Java heap.
* **CPU Explanation**: Captures a thread dump (`jcmd Thread.print`) and aggregates active stack frames to surface the methods most likely to be burning CPU cycles.
* **Noise Filtering**: Framework and runtime frames (`java.lang`, `java.util`, `sun.*`, `jdk.*`, Tomcat, PostgreSQL, HikariCP) are filtered out so only application-relevant hotspots remain.
* **Timestamped Reports**: Every run is saved to a dated file under `results/` for later comparison.

---

## 🛠️ Usage Guide

### 1. Command Options

* `--k8s`, `--kube` : Enable Kubernetes mode (**required**)
* `--pod <pod_name>` : Target pod name (**required**)
* `--namespace <ns>`, `-n <ns>` : Kubernetes namespace (**required**)
* `--context <context>` : Optional `kubectl` context to target a specific cluster

### 2. Example

```bash
./spring-resource-analyzer.sh \
--k8s \
--pod my-spring-app-7d9f8c6b5-abcde \
--namespace production \
--context prod-cluster
```

---

## 🔍 Output

The diagnostic report is printed to the console and stored under the `results/` directory:

* `results/resource_analysis_<pod_name>_<timestamp>.txt`

The report contains:

1. **Header** — target pod, namespace, total CPU and RAM usage.
2. **RAM Explanation** — the top objects allocated on the Java heap.
3. **CPU Explanation** — the most frequently observed application stack frames.

---

## 📋 Requirements

* **`kubectl`** configured with access to the target cluster.
* Permission to run `kubectl top` and `kubectl exec` against the pod.
* The container image must ship the **JDK tools** (`jcmd`, `jmap`); a JRE-only image will not work.

---

## ⚠️ Notes

* The script runs in Kubernetes mode only — it exits with an error if `--pod` or `--namespace` is missing.
* `kubectl top` requires the **metrics-server** to be installed in the cluster.
* The heap histogram (`jmap -histo:live`) triggers a full GC on the target JVM; use it deliberately on production workloads.
