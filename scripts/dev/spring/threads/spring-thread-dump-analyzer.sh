#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
CORE_ANALYZER="${SCRIPT_DIR}/spring-analyzer-core.sh"

if [ ! -f "$CORE_ANALYZER" ]; then
    echo "Error: Core analyzer engine missing at ${CORE_ANALYZER}"
    exit 1
fi

mkdir -p "${SCRIPT_DIR}/results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

MODE="local"
POD_NAME=""
NAMESPACE=""
KUBE_CONTEXT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --k8s|--kube)
            MODE="k8s"
            shift
            ;;
        --pod)
            POD_NAME="$2"
            shift 2
            ;;
        --namespace|-n)
            NAMESPACE="$2"
            shift 2
            ;;
        --context)
            KUBE_CONTEXT="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage local: $0"
            echo "Usage k8s  : $0 --k8s --pod <name> --namespace <ns> [--context <ctx>]"
            exit 1
            ;;
    esac
done

# --- MODE KUBERNETES ---
if [ "$MODE" == "k8s" ]; then
    if [ -z "$POD_NAME" ] || [ -z "$NAMESPACE" ]; then
        echo "Error: Missing required parameters for Kubernetes mode."
        echo "Usage: $0 --k8s --pod <pod_name> --namespace <namespace> [--context <kube_context>]"
        exit 1
    fi

    KUBECTL_ARGS="-n $NAMESPACE"
    if [ -n "$KUBE_CONTEXT" ]; then
        KUBECTL_ARGS="--context=$KUBE_CONTEXT -n $NAMESPACE"
    fi

    echo "Fetching Java processes inside Pod ${POD_NAME}..."
    JAVA_PROCESSES=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- jcmd 2>/dev/null | grep -v "sun.tools.jcmd")

    if [ -z "$JAVA_PROCESSES" ]; then
        echo "Error: No Java processes or JDK found in the container."
        exit 1
    fi

    PID=$(echo "$JAVA_PROCESSES" | head -n 1 | awk '{print $1}')
    PROCESS_NAME=$(echo "$JAVA_PROCESSES" | head -n 1 | cut -d' ' -f2-)

    REPORT_FILE="${SCRIPT_DIR}/results/k8s_analysis_${POD_NAME}_${TIMESTAMP}.txt"
    CONTEXT_INFO="  Target Pod     : $POD_NAME\n  Namespace      : $NAMESPACE\n  Kube Context   : ${KUBE_CONTEXT:-current-context}\n  Container PID  : $PID\n  Process        : $PROCESS_NAME"

    echo "Generating thread dump from remote cluster..."
    THREAD_DUMP=$(kubectl exec $KUBECTL_ARGS "$POD_NAME" -- jstack "$PID" 2>/dev/null)

# --- MODE LOCAL (DEFAULT) ---
else
    JAVA_PROCESSES=$(jcmd | grep -v "sun.tools.jcmd")

    if [ -z "$JAVA_PROCESSES" ]; then
        echo "Error: No running Java application found."
        exit 1
    fi

    NUM_PROCESSES=$(echo "$JAVA_PROCESSES" | wc -l)
    if [ "$NUM_PROCESSES" -eq 1 ]; then
        PID=$(echo "$JAVA_PROCESSES" | awk '{print $1}')
        PROCESS_NAME=$(echo "$JAVA_PROCESSES" | cut -d' ' -f2-)
    else
        echo "Multiple local Java processes detected. Select one:"
        echo "--------------------------------------------------------"
        IFS=$'\n'
        PS3="Enter the number of the process to analyze: "
        select CHOICE in $JAVA_PROCESSES "Exit"; do
            if [ "$CHOICE" = "Exit" ] || [ -z "$CHOICE" ]; then exit 0; fi
            PID=$(echo "$CHOICE" | awk '{print $1}')
            PROCESS_NAME=$(echo "$CHOICE" | cut -d' ' -f2-)
            break
        done
    fi

    REPORT_FILE="${SCRIPT_DIR}/results/local_analysis_${PID}_${TIMESTAMP}.txt"
    CONTEXT_INFO="  Target PID     : $PID\n  Process        : $PROCESS_NAME"

    echo "Generating local thread dump..."
    THREAD_DUMP=$(jstack "$PID" 2>/dev/null)
fi

if [ -z "$THREAD_DUMP" ]; then
    echo "Error: Failed to collect thread dump. (Check permissions/JDK availability)."
    exit 1
fi

bash "$CORE_ANALYZER" "$THREAD_DUMP" "$REPORT_FILE" "$CONTEXT_INFO"

echo "Report successfully saved to: $REPORT_FILE"