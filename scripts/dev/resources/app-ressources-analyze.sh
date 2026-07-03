#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

MODE="local"
POD_INPUT=""
NAMESPACE=""
KUBE_CONTEXT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --k8s|--kube) MODE="k8s"; shift ;;
        --pod) POD_INPUT="$2"; shift 2 ;;
        --namespace|-n) NAMESPACE="$2"; shift 2 ;;
        --context) KUBE_CONTEXT="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [ "$MODE" != "k8s" ] || [ -z "$POD_INPUT" ] || [ -z "$NAMESPACE" ]; then
    echo "Error: This analyzer requires Kubernetes mode."
    echo "Usage: $0 --k8s --pod <pod_name_or_regex> --namespace <namespace> [--context <context>]"
    exit 1
fi

KUBECTL_ARGS="-n $NAMESPACE"
if [ -n "$KUBE_CONTEXT" ]; then KUBECTL_ARGS="--context=$KUBE_CONTEXT -n $NAMESPACE"; fi

echo "Resolving pod(s) for input '$POD_INPUT'..."
MATCHING_PODS=($(kubectl get pods $KUBECTL_ARGS -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E "$POD_INPUT"))

if [ ${#MATCHING_PODS[@]} -eq 0 ]; then
    echo "Error: No pods found matching '$POD_INPUT' in namespace '$NAMESPACE'."
    exit 1
fi

echo "Found ${#MATCHING_PODS[@]} pod(s) to analyze."

mkdir -p "${SCRIPT_DIR}/results"
REPORT_FILE="${SCRIPT_DIR}/results/universal_analysis_${POD_INPUT//[^a-zA-Z0-9]/_}_${TIMESTAMP}.txt"

{
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│         UNIVERSAL K8S RESOURCE ANALYZER                │"
    echo "└────────────────────────────────────────────────────────┘"
    echo "  Pattern   : $POD_INPUT"
    echo "  Namespace : $NAMESPACE"
    echo "  Date      : $(date)"
    echo "──────────────────────────────────────────────────────────"
    echo ""
} > "$REPORT_FILE"

for POD_NAME in "${MATCHING_PODS[@]}"; do
    echo "--------------------------------------------------"
    echo "Analyzing pod: $POD_NAME..."
    echo "--------------------------------------------------"

    POD_JSON=$(kubectl get pod "$POD_NAME" $KUBECTL_ARGS -o json 2>/dev/null)
    if [ -z "$POD_JSON" ]; then
        echo "  [Error] Failed to fetch JSON for $POD_NAME. Skipping." >> "$REPORT_FILE"
        continue
    fi

    START_TIME=$(echo "$POD_JSON" | jq -r '.status.startTime // "Unknown"')
    POD_IP=$(echo "$POD_JSON" | jq -r '.status.podIP // "Unknown"')
    IMAGE_NAME=$(echo "$POD_JSON" | jq -r '.spec.containers[0].image // "Unknown"')
    RESTART_COUNT=$(echo "$POD_JSON" | jq -r '.status.containerStatuses[0].restartCount // "0"')
    LAST_STATE_REASON=$(echo "$POD_JSON" | jq -r '.status.containerStatuses[0].lastState.terminated.reason // "None"')

    POD_TOP=$(kubectl top pod "$POD_NAME" $KUBECTL_ARGS --no-headers 2>/dev/null)
    CPU_USAGE=$(echo "$POD_TOP" | awk '{print ($2 ? $2 : "N/A")}')
    RAM_USAGE=$(echo "$POD_TOP" | awk '{print ($3 ? $3 : "N/A")}')
    CPU_REQ=$(echo "$POD_JSON" | jq -r '.spec.containers[0].resources.requests.cpu // "None"')
    CPU_LIM=$(echo "$POD_JSON" | jq -r '.spec.containers[0].resources.limits.cpu // "None"')
    MEM_REQ=$(echo "$POD_JSON" | jq -r '.spec.containers[0].resources.requests.memory // "None"')
    MEM_LIM=$(echo "$POD_JSON" | jq -r '.spec.containers[0].resources.limits.memory // "None"')

    FRONT_PROCESSES=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- ps aux 2>/dev/null || kubectl exec $KUBECTL_ARGS "$POD_NAME" -- ps -ef 2>/dev/null || kubectl exec $KUBECTL_ARGS "$POD_NAME" -- top -b -n 1 | head -n 15 2>/dev/null)

    TECH_STACK="Generic/Unknown"
    if echo "$FRONT_PROCESSES" | grep -qi "java"; then
        TECH_STACK="Java/JVM (Spring Boot, Quarkus...)"
    elif echo "$FRONT_PROCESSES" | grep -E -qi "node|next|nuxt"; then
        TECH_STACK="Node.js (SSR Frontend / BFF)"
    elif echo "$FRONT_PROCESSES" | grep -qi "nginx"; then
        TECH_STACK="Nginx (Static Front / Proxy)"
    elif echo "$FRONT_PROCESSES" | grep -qi "python"; then
        TECH_STACK="Python (FastAPI, Django, Flask)"
    fi

    {
        echo "=========================================================="
        echo " POD: $POD_NAME"
        echo "=========================================================="
        echo "  • Detected Stack : $TECH_STACK"
        echo "  • IP             : $POD_IP"
        echo "  • Restarts       : $RESTART_COUNT (Last Crash Reason: $LAST_STATE_REASON)"
        echo ""
        echo "  [Resource Capacity vs Current Usage]"
        echo "    COMPONENT │ REQUESTED  │ CURRENT    │ LIMIT       "
        echo "    "$(printf "%-10s│ %-11s│ %-11s│ %-12s" "CPU" "$CPU_REQ" "$CPU_USAGE" "$CPU_LIM")
        echo "    "$(printf "%-10s│ %-11s│ %-11s│ %-12s" "MEMORY" "$MEM_REQ" "$RAM_USAGE" "$MEM_LIM")
        echo ""
    } >> "$REPORT_FILE"

    if [ "$TECH_STACK" = "Java/JVM (Spring Boot, Quarkus...)" ]; then
        JAVA_PROCESSES=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- jcmd 2>/dev/null | grep -v "sun.tools.jcmd")
        PID=$(echo "$JAVA_PROCESSES" | head -n 1 | awk '{print $1}')

        if [ -n "$PID" ]; then
            JVM_THREADS=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- jcmd "$PID" Thread.print 2>/dev/null)
            JVM_HEAP=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- jmap -histo:live "$PID" 2>/dev/null)
            {
                echo "  [JVM - Top Heap Objects Allocations]"
                echo "$JVM_HEAP" | head -n 15 | sed 's/^/    /'
                echo ""
                echo "  [JVM - Active Execution Hotspots]"
                echo "$JVM_THREADS" | grep "at " | grep -v -E "java.lang|java.util|sun.|jdk.|org.apache.tomcat" | sort | uniq -c | sort -nr | head -n 8 | awk '{print "    Active Count: " $1 " \t-> " $2 " " $3}'
            } >> "$REPORT_FILE"
        else
            echo "    [Warning] Java process found but JDK diagnosis tools (jcmd/jmap) are missing." >> "$REPORT_FILE"
        fi
    else
        RAW_LOGS=$(kubectl logs $KUBECTL_ARGS "$POD_NAME" --tail=3000 2>/dev/null)
        TOP_ASSETS=$(echo "$RAW_LOGS" | grep -E "GET.*(\.js|\.css|\.png|\.json|/api)" | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 8)
        ERRORS=$(echo "$RAW_LOGS" | grep -E "ERROR|Failed|exception|500|502|504|timeout|Hydration" | sort | uniq -c | sort -nr | head -n 8)

        {
            echo "  [Traffic & Endpoint Analysis]"
            if [ -n "$TOP_ASSETS" ]; then echo "$TOP_ASSETS" | awk '{print "    Hits: " $1 " \t-> " $2}'; else echo "    No asset/routing logs found."; fi
            echo ""
            echo "  [Top Error Patterns & Logs]"
            if [ -n "$ERRORS" ]; then echo "$ERRORS" | sed 's/^/    /'; else echo "    Logs look clean. No frequent errors detected."; fi
        } >> "$REPORT_FILE"
    fi

    {
        echo ""
        echo "  [Internal Running Processes]"
        if [ -n "$FRONT_PROCESSES" ]; then echo "$FRONT_PROCESSES" | head -n 8 | sed 's/^/    /'; else echo "    'ps'/'top' commands not available inside this slim container."; fi
        echo "──────────────────────────────────────────────────────────"
        echo ""
    } >> "$REPORT_FILE"

done

clear
cat "$REPORT_FILE"
echo "Diagnostic saved to: $REPORT_FILE"