#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

MODE="local"
POD_NAME=""
NAMESPACE=""
KUBE_CONTEXT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --k8s|--kube) MODE="k8s"; shift ;;
        --pod) POD_NAME="$2"; shift 2 ;;
        --namespace|-n) NAMESPACE="$2"; shift 2 ;;
        --context) KUBE_CONTEXT="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [ "$MODE" != "k8s" ] || [ -z "$POD_NAME" ] || [ -z "$NAMESPACE" ]; then
    echo "Error: This specialized resource analyzer requires Kubernetes mode."
    echo "Usage: $0 --k8s --pod <pod_name> --namespace <namespace> [--context <context>]"
    exit 1
fi

KUBECTL_ARGS="-n $NAMESPACE"
if [ -n "$KUBE_CONTEXT" ]; then KUBECTL_ARGS="--context=$KUBE_CONTEXT -n $NAMESPACE"; fi

mkdir -p "${SCRIPT_DIR}/results"
REPORT_FILE="${SCRIPT_DIR}/results/resource_analysis_${POD_NAME}_${TIMESTAMP}.txt"

echo "Collecting Kubernetes pod resource metrics..."
POD_TOP=$(kubectl top pod "$POD_NAME" $KUBECTL_ARGS --no-headers 2>/dev/null)
CPU_USAGE=$(echo "$POD_TOP" | awk '{print $2}')
RAM_USAGE=$(echo "$POD_TOP" | awk '{print $3}')

echo "Inspecting JVM internals..."
JAVA_PROCESSES=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- jcmd 2>/dev/null | grep -v "sun.tools.jcmd")
PID=$(echo "$JAVA_PROCESSES" | head -n 1 | awk '{print $1}')

if [ -z "$PID" ]; then
    echo "Error: Unable to find Java process or JDK tools inside the container."
    exit 1
fi

JVM_THREADS=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- jcmd "$PID" Thread.print 2>/dev/null)
JVM_HEAP=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- jmap -histo:live "$PID" 2>/dev/null)

{
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│         POD RESOURCE CONSUMPTION DIAGNOSTIC            │"
    echo "└────────────────────────────────────────────────────────┘"
    echo "  Target Pod   : $POD_NAME"
    echo "  Namespace    : $NAMESPACE"
    echo "  Total CPU    : $CPU_USAGE"
    echo "  Total RAM    : $RAM_USAGE"
    echo "──────────────────────────────────────────────────────────"
    echo ""
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│ 1. RAM EXPLANATION (Top Heap Objects Allocations)      │"
    echo "└────────────────────────────────────────────────────────┘"
    echo "  (Shows what is currently occupying the Java Heap memory)"
    echo ""
    echo "$JVM_HEAP" | head -n 20 | tail -n 16 | sed 's/^/  /'
    echo ""
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│ 2. CPU EXPLANATION (Active Execution Hotspots)         │"
    echo "└────────────────────────────────────────────────────────┘"
    echo "  (Shows the methods most likely to consume CPU cycles)"
    echo ""
    echo "$JVM_THREADS" | grep "at " | grep -v -E "java.lang|java.util|sun.|jdk.|org.apache.tomcat|org.postgresql|com.zaxxer.hikari" | sort | uniq -c | sort -nr | head -n 10 | awk '{print "  Active Count: " $1 " \t-> " $2 " " $3}'
    echo ""
    echo "└────────────────────────────────────────────────────────┘"
} > "$REPORT_FILE"

cat "$REPORT_FILE"
echo "Resource diagnostic saved to: $REPORT_FILE"