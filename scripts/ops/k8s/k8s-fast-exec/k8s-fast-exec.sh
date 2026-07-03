#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

NAMESPACE=""
POD_INPUT=""
KUBE_CONTEXT=""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0;37m'
BOLD='\033[1m'

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace=*|-n=*) NAMESPACE="${1#*=}"; shift ;;
        --namespace|-n)     NAMESPACE="$2"; shift 2 ;;
        --pod=*|-p=*)       POD_INPUT="${1#*=}"; shift ;;
        --pod|-p)           POD_INPUT="$2"; shift 2 ;;
        --context=*)        KUBE_CONTEXT="${1#*=}"; shift ;;
        --context)          KUBE_CONTEXT="$2"; shift 2 ;;
        *) echo -e "${RED}Unknown argument: $1${NC}"; exit 1 ;;
    esac
done

if [ -n "$KUBE_CONTEXT" ]; then
    kubectl config use-context "$KUBE_CONTEXT" >/dev/null 2>&1
fi

CURRENT_CONTEXT=$(kubectl config current-context)
CURRENT_NS=$( [ -n "$NAMESPACE" ] && echo "$NAMESPACE" || kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null )
CURRENT_NS=${CURRENT_NS:-default}

if [ -z "$POD_INPUT" ]; then
    echo -e "${BLUE}Fetching active pods in namespace: ${YELLOW}$CURRENT_NS${NC}"
    PODS=($(kubectl get pods -n "$CURRENT_NS" --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' 2>/dev/null))

    if [ ${#PODS[@]} -eq 0 ]; then
        echo -e "${RED}No running pods found in namespace $CURRENT_NS.${NC}"
        exit 1
    fi

    echo -e "${BOLD}Select the pod you want to connect to:${NC}"
    select TARGET_POD in "${PODS[@]}"; do
        if [ -n "$TARGET_POD" ]; then
            break
        else
            echo -e "${RED}Invalid selection. Please choose a valid number.${NC}"
        fi
    done
else
    TARGET_POD=$(kubectl get pods -n "$CURRENT_NS" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E "$POD_INPUT" | head -n 1)
fi

if [ -z "$TARGET_POD" ]; then
    echo -e "${RED}Error: No pod matching '$POD_INPUT' found in namespace '$CURRENT_NS'.${NC}"
    exit 1
fi

echo -e "\n${BLUE}Connecting to pod: ${BOLD}$TARGET_POD${NC}"
echo -e "   Context   : ${GREEN}$CURRENT_CONTEXT${NC}"
echo -e "   Namespace : ${GREEN}$CURRENT_NS${NC}\n"

if kubectl exec -n "$CURRENT_NS" "$TARGET_POD" -- which bash >/dev/null 2>&1; then
    kubectl exec -it -n "$CURRENT_NS" "$TARGET_POD" -- bash
else
    echo -e "${YELLOW}ℹ'bash' is not available in this container. Falling back to 'sh'...${NC}\n"
    kubectl exec -it -n "$CURRENT_NS" "$TARGET_POD" -- sh
fi