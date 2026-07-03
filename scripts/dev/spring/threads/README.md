# Spring Engine Health Dashboard & Thread Dump Analyzer

A lightweight, robust, and interactive command-line utility designed for Java Spring Boot developers. This tool captures live JVM thread dumps, cleans out the framework noise, and generates an instant text-based health dashboard. It works seamlessly for both local applications and remote Kubernetes pods.

## Features

- **Interactive Selection**: Automatically detects running Java applications and provides an interactive CLI menu to pick the target process.
- **Universal Framework Filtering**: Automatically filters out JVM internal threads, application servers (Tomcat, Undertow), database drivers (PostgreSQL, MySQL, HikariCP), and Spring AOP/Web plumbing to expose only your actual business logic hotspots.
- **Dual-Mode Execution**: Supports local JVM analysis (`jcmd`/`jstack`) and remote container analysis via Kubernetes (`kubectl exec`).
- **Persistent Reporting**: Automatically generates and saves a structured text dashboard in a centralized `./results` directory located next to the script.

## Project Structure

The utility is split into two components to prevent code duplication:
- `spring-thread-dump-analyzer.sh`: The main entry point handling parameter parsing, interactivity, and infrastructure targeting (Local vs. Kubernetes).
- `spring-analyzer-core.sh`: The shared analytical engine that processes raw dumps and renders the dashboard.

## Prerequisites

- **Local Mode**: A full Java Development Kit (JDK) must be installed. The standard Java Runtime Environment (JRE) does not include `jcmd` and `jstack`.
- **Kubernetes Mode**: The `kubectl` CLI tool must be authenticated against your cluster, and the target container image must run a full JDK to support remote diagnostic commands.

## Installation

Ensure both scripts are located in the same directory and grant execution permissions:

```bash
chmod +x ./spring-thread-dump-analyzer.sh
chmod +x ./spring-analyzer-core.sh
```

## Usage

The script utilizes named arguments, allowing parameters to be passed in any order.

### 1. Local Application Analysis

To analyze a Java/Spring Boot application running on your local machine, execute the script without any parameters:

```bash
./spring-thread-dump-analyzer.sh
```
*If multiple Java processes are active, an interactive prompt will ask you to select the target.*

### 2. Kubernetes Pod Analysis

To analyze a Spring Boot application running inside a remote Kubernetes cluster, pass the `--k8s` flag along with the required parameters:

```bash
# Basic usage within the active kubectl context
./spring-thread-dump-analyzer.sh --k8s --pod <pod_name> --namespace <namespace>

# Advanced usage targeting a specific cluster context
./spring-thread-dump-analyzer.sh --k8s --pod <pod_name> --namespace <namespace> --context <kube_context>
```

Since the parameters are named, the following command is also perfectly valid:

```bash
./spring-thread-dump-analyzer.sh --namespace production --context gke-prod-cluster --pod inventory-service-xyz --k8s
```

## Dashboard Overview

The generated report is saved to `results/` and structured into four actionable categories:

1. **JVM Thread States**: High-level counter breaking down threads into RUNNABLE, TIMED_WAITING, WAITING, and BLOCKED states.
2. **Spring Ecosystem Pools**: Quick statistics on Tomcat HTTP executors, HikariCP database connection pools, and Spring `@Scheduled` runners.
3. **Critical Alerts**: Immediate extraction of stack traces if a Java-level deadlock or severe thread contention is detected.
4. **Hotspots & Bottleneck Candidates**: A ranked top-10 list of the most frequent business methods executing in parallel, pinpointing exact class names and line numbers.