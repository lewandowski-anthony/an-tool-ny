# Multi-OS Sandbox Environment via Docker

This repository provides modular Docker Compose configurations to run multiple operating system environments inside containers. It features both Graphical User Interface (GUI) desktops accessible via your web browser or VNC client, and lightweight Headless (CLI-only) environments for fast testing and development.

---

## 📋 Quick Reference Table

### GUI Environments

| Operating System | Compose File | Web URL | VNC Port | Default Credentials / Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Ubuntu** (LXDE) | `./gui/ubuntu-compose.yaml` | `http://localhost:8080` | `5900` | Password: `secret_password` |
| **Debian** (XFCE) | `./gui/debian-compose.yaml` | `http://localhost:8080` | `5901` | Password: `password123` |
| **Windows** (ARM) | `./gui/windows-compose.yaml` | `http://localhost:8006` | `3389` | Requires RDP Client / NoVNC Web Interface |

### Headless Environments

| Operating System | Compose File | Service Name | Container Name | Interface Mode |
| :--- | :--- | :--- | :--- | :--- |
| **Arch Linux** | `./headless/arch-compose.yaml` | `arch` | `os_arch` | Interactive CLI |
| **Debian** | `./headless/debian-compose.yaml` | `debian` | `os_debian` | Interactive CLI |
| **Amazon Linux** | `./headless/amazon-compose.yaml` | `amazon` | `os_amazon` | Interactive CLI |
| **Oracle Linux** | `./headless/oracle-compose.yaml` | `oracle` | `os_oracle` | Interactive CLI |
| **openSUSE** | `./headless/opensuse-compose.yaml` | `opensuse` | `os_opensuse` | Interactive CLI |
| **IBM AIX** | `./headless/aix-compose.yaml` | `aix` | `os_aix` | Sandbox CLI |

---

## 🚀 Getting Started

### Prerequisites

Ensure you have Docker and Docker Compose installed on your system.

* [Get Docker](https://docs.docker.com/get-docker/)
* [Install Docker Compose](https://docs.docker.com/compose/install/)

### Port Conflict Warning

> **Note:** Both the Ubuntu and Debian GUI setups are configured to bind to host port `8080`. Do not run them concurrently without modifying their `ports` mappings in their respective Compose files to avoid port allocation conflicts.

---

## 💻 Deployment Instructions

Because every operating system environment is split into its own Compose configuration file, you must specify the file path using the `-f` flag for your management commands.

### 1. Running GUI Environments

#### Ubuntu Desktop
```bash
docker compose -f ./gui/ubuntu-compose.yaml up -d
```
* **Web UI:** Access `http://localhost:8080` in your browser.
* **VNC Connection:** Target `localhost:5900` with the password `secret_password`.

#### Debian Desktop
```bash
docker compose -f ./gui/debian-compose.yaml up -d
```
* **Web UI:** Access `http://localhost:8080` in your browser.
* **VNC Connection:** Target `localhost:5901` with the password `password123`.

#### Windows (ARM)
```bash
docker compose -f ./gui/windows-compose.yaml up -d
```
* **Web UI:** Access `http://localhost:8006` for the built-in system viewer.
* **RDP Connection:** Connect via any standard Remote Desktop client using `localhost:3389`.

---

### 2. Running Headless (CLI) Environments

Headless environments run with an open standard input stream and an allocated pseudo-TTY (`stdin_open: true`, `tty: true`). This setup keeps the container alive in the background and allows you to attach directly to its terminal shell.

To launch a headless container and access its command line immediately, follow this two-step process:

#### Step 1: Start the Container in Background Mode
```bash
docker compose -f ./headless/arch-compose.yaml up -d
```
*(Replace `arch-compose.yaml` with any other configuration file name from the `./headless/` directory as needed).*

#### Step 2: Attach to the Interactive Shell
```bash
docker exec -it os_arch /bin/bash
```
*(If `/bin/bash` is unavailable on specialized images like AIX or minimalist environments, use `/bin/sh` instead).*

---

## 🛠️ Useful Management Commands

### Check Active Sandboxes

View the operational status of all running system containers:

```bash
docker ps
```

### Stopping an Environment

Stop the containers without destroying persistent volume data:

```bash
docker compose -f <path-to-compose-file>.yaml stop
```

### Tearing Down and Cleaning Up

To completely halt execution and remove containers along with their internal virtual networks:

```bash
docker compose -f <path-to-compose-file>.yaml down
```

To purge the environment completely, including any attached persistent data volumes (e.g., your saved user profiles or downloads), add the `-v` flag:

```bash
docker compose -f <path-to-compose-file>.yaml down -v
```

---

## 💡 Troubleshooting & Performance Adjustments

* **Shared Memory Allocation:** GUI systems (specifically web browsers running inside containers) require adequate shared memory to prevent unexpected tab crashes. The Ubuntu and Debian configurations are initialized with `shm_size` allocations between `2gb` and `3gb` to ensure operational stability.
* **Privileged Mode:** The Linux GUI configurations utilize `privileged: true` to bypass typical kernel restrictions. This grants the container processes the capability to map memory spaces and render desktop graphics smoothly. Use caution if running these setups on production servers.
* **Hardware Acceleration:** If you experience visual lag or low frame rates during rendering, pass host graphics processing unit (GPU) hardware access nodes directly to the containers. Add the following property structure directly to the core service within your `.yaml` configuration file:

```yaml
devices:
  - /dev/dri:/dev/dri
```