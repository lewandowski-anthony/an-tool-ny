#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

NAMESPACE=""
PORT="8080"
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
        --port=*|-p=*)      PORT="${1#*=}"; shift ;;
        --port|-p)          PORT="$2"; shift 2 ;;
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

echo -e "${BLUE}${BOLD}🔍 Fetching available deployments in namespace: ${YELLOW}$CURRENT_NS${NC}\n"

DEPLOYMENTS=($(kubectl get deployments -n "$CURRENT_NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null))

if [ ${#DEPLOYMENTS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No deployments found in namespace $CURRENT_NS.${NC}"
    exit 1
fi

echo -e "${BOLD}Select the deployment you want to port-forward:${NC}"
select TARGET_DEPLOYMENT in "${DEPLOYMENTS[@]}"; do
    if [ -n "$TARGET_DEPLOYMENT" ]; then
        echo -e "\n🎯 Selected Deployment: ${GREEN}${BOLD}$TARGET_DEPLOYMENT${NC}\n"
        break
    else
        echo -e "${RED}Invalid selection. Please choose a valid number.${NC}"
    fi
done

echo -e "${BLUE}${BOLD}🧹 Checking if port $PORT is already leaked locally...${NC}"
PID=$(lsof -t -i :$PORT)

if [ -n "$PID" ]; then
    echo -e "${YELLOW}⚠️ Port $PORT is blocked by PID $PID. Killing it...${NC}"
    kill -9 $PID >/dev/null 2>&1
    sleep 1
fi

echo -e "${BLUE}${BOLD}🚀 Launching port-forward for deployment/${TARGET_DEPLOYMENT} on port ${PORT}...${NC}"
echo -e "   Context   : ${GREEN}$CURRENT_CONTEXT${NC}"
echo -e "   Namespace : ${GREEN}$CURRENT_NS${NC}"

ERR_LOG="/tmp/k8s_pf_err_${TIMESTAMP}.log"

nohup kubectl port-forward deployment/$TARGET_DEPLOYMENT $PORT:$PORT -n $CURRENT_NS > /dev/null 2> "$ERR_LOG" &
BG_PID=$!

sleep 2

if kill -0 $BG_PID 2>/dev/null; then
    disown $BG_PID 2>/dev/null
    rm -f "$ERR_LOG"
    echo -e "${GREEN}${BOLD}✅ Port-forward successfully running in background (PID: $BG_PID).${NC}"
    echo -e "   Access it via: ${BLUE}http://localhost:$PORT${NC}"
else
    echo -e "${RED}❌ Error: Port-forward failed to start or died immediately.${NC}"
    echo -e "${YELLOW}${BOLD}ℹ️ KUBECTL ERROR OUTPUT :${NC}"
    if [ -s "$ERR_LOG" ]; then
        echo -e "${RED}$(cat "$ERR_LOG" | sed 's/^/   /')${NC}"
    else
        echo -e "   [No logs captured. Check if the deployment has ready pods running]"
    fi
    rm -f "$ERR_LOG"
    exit 1
fi