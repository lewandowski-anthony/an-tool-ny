# DevOps and System Administration Toolkit

This repository contains a comprehensive suite of shell utilities designed to streamline infrastructure engineering tasks. The toolkit automates workstation provisioning, manages global dependencies
across multiple operating systems, cleanly terminates processes blocking network resources, and audits cryptographic identity structures for distributed platforms like Apache Kafka.

---

## Toolchain Matrix

| Script                        | Purpose                                     | Primary Dependencies    | Target Platforms                    |
|:------------------------------|:--------------------------------------------|:------------------------|:------------------------------------|
| `install-dependencies.sh`     | Automated multi-OS package provisioning     | Native Package Managers | macOS, Windows, Debian/Ubuntu, RHEL |
| `update-dependencies.sh`      | Multi-ecosystem package upgrade manager     | Native Package Managers | Universal                           |
| `port-killer.sh`              | Intelligent network port freeing mechanism  | `lsof`, `ps`, `docker`  | Linux, macOS                        |
| `check-kafka-certificates.sh` | Cryptographic chain and key-pair validation | `openssl`               | Universal Unix/Bash                 |

---

## Component Deep Dives

### 1. Environment Provisioning Engine (`install-dependencies.sh`)

This utility automates workspace bootstrapping by detecting the host operating system and natively installing core DevOps tools.

* **OS Detection Framework**: Inspects `$OSTYPE` and file system flags like `/etc/debian_version` or `/etc/redhat-release` to parse the target architecture.
* **Ecosystem Coverage**:
    * **macOS**: Configures Homebrew if absent, refreshes formulas, and provisions core libraries plus specific tap entities like `aquasecurity/trivy/trivy`.
    * **Windows**: Interfaces directly with the Windows Package Manager CLI (`winget`), applying unattended, silent installations that auto-accept licensing agreements.
    * **Linux (Debian/RHEL)**: Uses `apt-get` or `dnf`/`yum` dynamically. For software with decoupled delivery cadences (like `yq` or `kubectl`), the engine pulls
      platform-specific architecture binaries straight from vendor release lines and registers them to systemic paths.

### 2. Multi-Ecosystem Upgrade Manager (`update-dependencies.sh`)

A safe, configuration-preserving script that loops through present package managers to execute downstream security patches and version upgrades across systems and application layers.

* **Fault-Tolerant Loops**: Evaluates binary existence sequentially via `command -v`. Missing managers are skipped gracefully without aborting the script runtime execution.
* **Automation Flags Implemented**:
    * **APT**: Implements explicit front-end flags `DEBIAN_FRONTEND=noninteractive` and updates parameters with specific `Dpkg::Options` (`--force-confdef`, `--force-confold`) to protect existing
      localized configuration files from overwrite anomalies.
    * **Windows Managers**: Couples silent parameters with package/source licensing bypass switches (`--accept-package-agreements`) for headless execution.
    * **Node Ecosystem**: Coordinates programmatic validation of global dependencies via npm packages (`npm update -g --silent`).

### 3. Intelligent Port Release Utility (`port-killer.sh`)

A specialized termination utility that isolates and safely drops processes binding specified TCP listening sockets.

* **Process Inspection**: Uses low-overhead query structures (`lsof -t -i:<port> -sTCP:LISTEN`) to extract target process identifiers.
* **Container Layer Traversal**: If the holding process maps back to virtualization abstractions like `com.docker` or `vpnkit`, the script halts normal signals. It
  translates host network allocations to trace the target container ID and runs a clean container teardown configuration (`docker stop`) to avoid corrupting background daemon storage layers.
* **Fallback Hard-Kill**: For standard processes, it signals immediate runtime termination (`kill -9`), followed by validation checks to ensure resource release.

### 4. Kafka Certificate Structure Auditor (`check-kafka-certificates.sh`)

A security compliance utility designed to intercept invalid public key infrastructure (PKI) components before deploying broken certificate paths to message brokers or schema
registries.

The script runs a comprehensive 4-stage validation routine:

1. **Authority Inspection**: Decodes the Certificate Authority (CA) public bundle, surfacing identity markers and asserting expiration status.
2. **Identity Evaluation**: Decodes the explicit client certificate, checking subject fields, confirming issuer roots, and evaluating temporal lifespans.
3. **Modulus Alignment Verification**: Extracts and creates an MD5 hash of the public certificate modulus and the private key modulus. It alerts systems operators
   immediately if a private key mismatch is discovered, preventing runtime TLS handshake negotiations from breaking down.
4. **Signature Verification**: Instructs OpenSSL to mathematically verify the client certificate's trust chain directly against the provided CA file to ensure valid ownership.

---

## Detailed Usage Reference

Ensure execution bits are set across the script workspace before initialization:

```bash
chmod +x *.sh
```

### System Initialization

```bash
./install-dependencies.sh
```

### System Patching Maintenance

```bash
./update-dependencies.sh
```

### Releasing Bound Network Ports

Pass the numerical target index of the blocked socket as the initial argument:

```bash
./port-killer.sh 8080
```

> *Note:* If target ports are held by core system services or elevated hypervisors, run using system administrator capabilities: `sudo ./port-killer.sh 8080`

### Evaluating Cryptographic Identity Sets

Pass the distinct public components, private key definitions, and trusted root definitions explicitly using the named arguments:

```bash
./check-kafka-certificates.sh \
  -c /path/to/service.cert \
  -k /path/to/service.key \
  -a /path/to/ca.pem
```

---

## Troubleshooting and Guidelines

* **Script Safety Settings**: All provisioning and evaluation scripts execute with the bash option `set -e` active[cite: 1, 2]. This ensures the execution context terminates immediately if
  an individual command fails, stopping minor errors from cascading into larger system failures.
* **Windows Support Warning**: The `port-killer.sh` script relies heavily on POSIX network configurations (`lsof`) and process mapping utilities (`ps`). For Windows-centric
  engineering stations, execute these diagnostic loops inside an active Windows Subsystem for Linux (WSL2) node or a compatible native bash container shell wrapper.