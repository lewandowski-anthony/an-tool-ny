# Identity & Access Management (IAM) & Security Diagnostics

This script falls cleanly into the **Security, Cryptography, & IAM Diagnostics** category (or alternatively, **Developer Privacy & Troubleshooting Utilities**).

These tools focus on the security layer of modern cloud-native architectures—specifically inspecting, validating, and debugging cryptographic identity signatures locally during developer runtime triage.

---

## 📋 Updated Toolkit Category Matrix

Here is how this addition completes your growing DevOps and developer workflow suite:

| Category | Script Name | Target Domain | Primary Focus |
| :--- | :--- | :--- | :--- |
| **IAM & Security Diagnostics** | `decode-jwt.sh` *(New)* | Token Authentication | Privacy-First Local Inspection |
| **Port & Process Management** | `kill-port.sh` | Host Network Layer | Local Conflict Resolution |
| **Docker Housekeeping** | `clean-docker.sh` | Container Daemon | Resource Reclaiming & Cleanup |
| **DevSecOps Integration** | `scan-docker.sh` | Container Images | Vulnerability Auditing |

---

## 🚀 Utility Specification: Offline JWT Inspector (`decode-jwt.sh`)

When debugging authentication middleware, OAuth2 flows, or microservice Authorization headers, developers frequently copy-paste JSON Web Tokens into web-based tools like `jwt.io`. This presents a critical security risk: pasting real production tokens leaks Personally Identifiable Information (PII), signature layouts, and claims matrices to external servers.

`decode-jwt.sh` solves this by executing a zero-network, local structural audit of any standard RS256, HS256, or ES256 string.

### Key Features
* **Zero-Network Privacy:** Keeps tokens entirely isolated on your local engine. No data ever leaves your terminal context.
* **Base64URL Compliance Engine:** Standard Base64 decoders fail on JWT components because the spec replaces URL-unsafe characters (`+`/`/` to `-`/`_`) and strips out padding (`=`). This utility dynamically checks character modulo string lengths to rebuild standard cryptographic padding arrays cleanly.
* **Structured Visual Output:** Leverages the local host's `jq` binary to process the payload and header streams into colorized, pretty-printed, indented JSON models.

### Source Code

```bash
#!/bin/bash

set -uo pipefail

JWT=${1:-}

if [ -z "$JWT" ]; then
    echo "Error: You must provide a JWT token."
    echo "Usage: $0 <jwt_token>"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install it using: brew install jq"
    exit 1
fi

decode_base64url() {
    local input=$(echo "$1" | tr '_-' '/+')
    local len=${#input}
    local mod=$((len % 4))
    if [ $mod -eq 2 ]; then
        input="${input}=="
    elif [ $mod -eq 3 ]; then
        input="${input}="
    fi
    echo "$input" | openssl base64 -d -A 2>/dev/null
}

HEADER_BASE64=$(echo "$JWT" | cut -d'.' -f1)
PAYLOAD_BASE64=$(echo "$JWT" | cut -d'.' -f2)

if [ -z "$HEADER_BASE64" ] || [ -z "$PAYLOAD_BASE64" ]; then
    echo "Error: Invalid JWT format. A valid JWT must contain at least two dots."
    exit 1
fi

echo "--- HEADER ---"
decode_base64url "$HEADER_BASE64" | jq . 2>/dev/null || echo "Error: Failed to decode or parse Header JSON."

echo -e "\n--- PAYLOAD ---"
decode_base64url "$PAYLOAD_BASE64" | jq . 2>/dev/null || echo "Error: Failed to decode or parse Payload JSON."
```

### Usage Instructions

Give the utility binary permission overrides:
```bash
chmod +x decode-jwt.sh
```

**Inspecting a Token String:**
```bash
./decode-jwt.sh eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Real-world Terminal Shortcut (Piping from Environment Variables):**
```bash
./decode-jwt.sh $MY_ACCESS_TOKEN
```