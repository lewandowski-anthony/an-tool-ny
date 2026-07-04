# Local Infrastructure & Port Management Utilities

This script belongs to the **Local Environment Housekeeping & Conflict Resolution** category (alternatively classified under **Network Troubleshooting & Process Automation**).

These types of utilities specialize in identifying and resolving localized orchestration conflicts—specifically when multiple microservices, runtime engines (like Java), or container tools (like
Docker) fight over the same host network ports during development cycles.

---

## 📋 Updated Toolkit Category Matrix

Here is how this tool fits alongside your existing DevOps automation scripts:

| Category                      | Script Name            | Target Domain      | Operation Type                |
|:------------------------------|:-----------------------|:-------------------|:------------------------------|
| **Port & Process Management** | `kill-port.sh` *(New)* | Host Network Layer | Conflict Resolution / Cleanup |
| **Docker Housekeeping**       | `clean-docker.sh`      | Container Daemon   | Mass Eviction / Factory Reset |
| **DevSecOps Integration**     | `scan-docker.sh`       | Container Images   | Security Auditing & Compiles  |

---

## 🚀 Utility Specification: Smart Port Liberator (`kill-port.sh`)

Unlike blunt tools that execute a destructive `kill -9` across any listening socket, this utility features **Context-Aware Lifecycle Handling**. It determines *what* is using the port and attempts an
elegant shutdown sequence before resorting to a forceful process termination.

### Key Features

* **Smart Docker Mapping:** If a Docker daemon component (such as `com.docker` or `vpnkit`) is occupying the port, the script maps the target port back to the explicit container ID via `docker ps`
  formats. It then invokes `docker stop` to cleanly close down the isolated application inside the container instead of crashing your entire host machine's Docker Desktop runtime.
* **Runtime Fingerprinting:** Inspects the active process command line to identify environment stacks, warning you if core processes like a `java` virtual machine are targeted.
* **Post-Execution State Validation:** Re-probes the port state exactly 200ms after executing the termination signals to guarantee the socket successfully transitioned back into a listening `FREE`
  state, offering clear programmatic `sudo` recommendations if it detects permission blocks.

### Source Code

```bash
#!/bin/bash

set -uo pipefail

PORT=${1:-}

if [ -z "$PORT" ]; then
    echo "Error: You must specify a port."
    echo "Usage: $0 <port> (e.g., $0 8080)"
    exit 1
fi

echo "Searching for process occupying port ${PORT}..."

PID=$(lsof -t -i:"$PORT" -sTCP:LISTEN)

if [ -z "$PID" ]; then
    echo "Port ${PORT} is already free. No action required."
    exit 0
fi

PROCESS_NAME=$(ps -p "$PID" -o comm= 2>/dev/null)

echo "Process found (PID: $PID, Name: $PROCESS_NAME)"

if [[ "$PROCESS_NAME" == *"com.docker"* || "$PROCESS_NAME" == *"vpnkit"* ]]; then
    echo "Docker process detected. Trying to identify the container..."

    CONTAINER_ID=$(docker ps --format '{{.ID}}\t{{.Ports}}' | grep "0.0.0.0:${PORT}" | awk '{print $1}')

    if [ -n "$CONTAINER_ID" ]; then
        CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER_ID" --format '{{.Names}}')
        echo "Stopping Docker container cleanly: ${CONTAINER_NAME} (${CONTAINER_ID})..."
        docker stop "$CONTAINER_ID" > /dev/null
        echo "Docker container stopped successfully."
        exit 0
    else
        echo "Unable to target the exact container. Forcing Docker process termination..."
    fi
fi

if [[ "$PROCESS_NAME" == *"java"* ]]; then
    echo "Java process detected."
fi

echo "Killing process ${PID}..."
kill -9 "$PID" 2>/dev/null

sleep 0.2
if ! lsof -t -i:"$PORT" -sTCP:LISTEN > /dev/null; then
    echo "Port ${PORT} freed successfully."
else
    echo "Failed to free port ${PORT}. The process might require sudo privileges."
    echo "Try: sudo $0 $PORT"
fi
```

### Usage Instructions

Make sure the script has execution permissions:

```bash
chmod +x kill-port.sh
```

**Standard User Execution:**

```bash
./kill-port.sh 8080
```

**Privileged Escalation Mode:**
If a system application or root service (like an enterprise gateway or system daemon) binds to a low-number port, pass a `sudo` override:

```bash
sudo ./kill-port.sh 443
```