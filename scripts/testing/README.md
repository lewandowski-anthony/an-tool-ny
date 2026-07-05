# Automated Testing 

This script establishes the **Automated Testing & Environment Smoke Diagnostics** category within your toolkit. It focuses on shift-left testing automation—allowing developers and DevOps engineers to
run instant, localized, or remote integration health-checks across an entire microservice architecture before shipping code.

---

## 📋 Updated Toolkit Category Matrix

Your automated toolkit now covers the complete development lifecycle:

| Category                            | Script Name                 | Target Domain        | Primary Focus                   |
|:------------------------------------|:----------------------------|:---------------------|:--------------------------------|
| **Automated Testing & Diagnostics** | `api-smoke-test.sh` *(New)* | Application Layers   | Endpoint & Contract Validations |
| **IAM & Security Diagnostics**      | `decode-jwt.sh`             | Token Authentication | Privacy-First Local Inspection  |
| **Port & Process Management**       | `kill-port.sh`              | Host Network Layer   | Local Conflict Resolution       |
| **Docker Housekeeping**             | `clean-docker.sh`           | Container Daemon     | Resource Reclaiming & Cleanup   |
| **DevSecOps Integration**           | `scan-docker.sh`            | Container Images     | Vulnerability Auditing          |

---

## 🚀 Utility Specification: Parallel API Smoke Tester (`api-smoke-test.sh`)

When deploying a stack of containerized services locally or upgrading components in a staging cluster, validating that all HTTP gateways, authentication routes, and downstream service endpoints are
operating correctly can be tedious.

`api-smoke-test.sh` consumes a simple manifest file or arrays of target endpoints, evaluates their real-time HTTP response headers, validates structural success states, measures millisecond latencies,
and yields clean diagnostic metrics.

### Key Features

* **Custom Threshold Validations:** Checks both expected HTTP response codes (e.g., `200`, `201`, `401`) and flags performance degradation if response latencies cross custom millisecond thresholds.
* **No Bulky Dependencies:** Built purely using advanced internal `curl` write-out formats (`%{http_code}`, `%{time_total}`), eliminating the need for complex external testing runtimes during quick
  sanity checks.
* **Inline Dynamic Manifest Evaluation:** Accepts text-based configuration targets so your testing sweeps can change context instantly depending on target testing suites.

### Source Code

```bash
#!/bin/bash

set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0;37m'
BOLD='\033[1m'

MANIFEST_FILE=${1:-"endpoints.txt"}
LATENCY_THRESHOLD_SECS="1.5" # 1500 milliseconds warning threshold

if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${YELLOW}ℹ No endpoint manifest file found at '$MANIFEST_FILE'. Creating a mock template...${NC}"
    mkdir -p "$(dirname "$MANIFEST_FILE")" 2>/dev/null || true
    cat << 'EOF' > "$MANIFEST_FILE"
# Format: TARGET_URL|EXPECTED_STATUS_CODE|ENDPOINT_LABEL
http://localhost:8080/actuator/health|200|Spring-Boot-Health
[https://httpbin.org/status/200](https://httpbin.org/status/200)|200|HttpBin-Baseline
[https://httpbin.org/status/401](https://httpbin.org/status/401)|401|Auth-Gateway-Sim
EOF
    echo -e "${GREEN}✔ Generated template manifest at '$MANIFEST_FILE'. Please configure it and rerun.${NC}"
    exit 0
fi

echo -e "${BLUE}${BOLD}Starting Architecture Smoke Testing Suite...${NC}"
echo -e "Reading target manifest: ${YELLOW}$MANIFEST_FILE${NC}\n"

FAILED_TESTS=0
PASSED_TESTS=0

echo -e "${BOLD}%-25s │ %-6s │ %-10s │ %-8s │ %-s${NC}" "ENDPOINT LABEL" "EXPECT" "RECEIVED" "LATENCY" "STATUS"
echo "──────────────────────────┼────────┼────────────┼──────────┼───────────────"

while read -r line || [ -n "$line" ]; do
    # Strip comments and empty blank lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    URL=$(echo "$line" | cut -d'|' -f1)
    EXPECTED_CODE=$(echo "$line" | cut -d'|' -f2)
    LABEL=$(echo "$line" | cut -d'|' -f3)

    # Execute lightweight non-allocating curl request probe
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" --connect-timeout 4 "$URL" 2>/dev/null || echo "000|0.000")
    
    HTTP_CODE=$(echo "$RESPONSE" | cut -d'|' -f1)
    TOTAL_TIME=$(echo "$RESPONSE" | cut -d'|' -f2)
    
    # Evaluate Status Code Matching
    if [ "$HTTP_CODE" -eq "$EXPECTED_CODE" ]; then
        STATUS_STRING="${GREEN}✔ PASS${NC}"
        ((PASSED_TESTS++))
    else
        STATUS_STRING="${RED}✘ FAIL (Mismatch)${NC}"
        ((FAILED_TESTS++))
    fi

    # Evaluate Latency Degradation
    LATENCY_ALERT=""
    if (( $(echo "$TOTAL_TIME > $LATENCY_THRESHOLD_SECS" | bc -l 2>/dev/null || echo 0) )); then
        LATENCY_ALERT="${YELLOW}(SLOW)${NC}"
    fi

    printf "%-25s │ %-6s │ %-10s │ %-7ss │ %b\n" "$LABEL" "$EXPECTED_CODE" "$HTTP_CODE" "$