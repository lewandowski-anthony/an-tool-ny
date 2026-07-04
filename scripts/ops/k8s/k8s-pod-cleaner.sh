#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

NAMESPACE=""
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

echo -e "${BLUE}${BOLD}Scanning for dead, completed or evicted pods...${NC}"
echo -e "   Context   : ${GREEN}$CURRENT_CONTEXT${NC}"
echo -e "   Namespace : ${GREEN}$CURRENT_NS${NC}\n"

DEAD_PODS=$(kubectl get pods -n "$CURRENT_NS" --no-headers 2>/dev/null | grep -E "Evicted|Completed|Error|OOMKilled" | awk '{print $1}')

if [ -z "$DEAD_PODS" ]; then
    echo -e "${GREEN}Your namespace is already squeaky clean!${NC}"
else
    echo -e "${YELLOW}Found dead pods. Starting purge...${NC}"
    for POD in $DEAD_PODS; do
        echo -e "   ├── ${RED}Deleting:${NC} $POD"
        kubectl delete pod "$POD" -n "$CURRENT_NS" --grace-period=0 --force >/dev/null 2>&1
    done
    echo -e "\n${GREEN}${BOLD}Cleaning complete!${NC}"
fi