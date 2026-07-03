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

echo -e "${BLUE}${BOLD}🔍 Fetching deployments...${NC}"
DEPLOYMENTS=($(kubectl get deployments -n "$CURRENT_NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null))

if [ ${#DEPLOYMENTS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No deployments found in namespace $CURRENT_NS.${NC}"
    exit 1
fi

echo -e "${BOLD}Select the deployment to restart (Zero-Downtime Rollout):${NC}"
select TARGET_DEP in "${DEPLOYMENTS[@]}"; do
    if [ -n "$TARGET_DEP" ]; then
        break
    else
        echo -e "${RED}Invalid selection. Please choose a valid number.${NC}"
    fi
done

echo -e "\n${BLUE}🚀 Triggering rollout restart for deployment/${TARGET_DEP}...${NC}"
echo -e "   Context   : ${GREEN}$CURRENT_CONTEXT${NC}"
echo -e "   Namespace : ${GREEN}$CURRENT_NS${NC}\n"

kubectl rollout restart deployment/$TARGET_DEP -n "$CURRENT_NS"

echo -e "\n${YELLOW}👀 Monitoring rollout progression...${NC}"
kubectl rollout status deployment/$TARGET_DEP -n "$CURRENT_NS"