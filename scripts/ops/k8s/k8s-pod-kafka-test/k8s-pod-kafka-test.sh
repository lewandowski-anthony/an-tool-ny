#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

NAMESPACE=""
POD_INPUT=""
BROKER_INPUT=""
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
        --broker=*|-b=*)    BROKER_INPUT="${1#*=}"; shift ;;
        --broker|-b)        BROKER_INPUT="$2"; shift 2 ;;
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
    echo -e "${BLUE}🔍 Fetching running pods in namespace: ${YELLOW}$CURRENT_NS${NC}"
    PODS=($(kubectl get pods -n "$CURRENT_NS" --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' 2>/dev/null))

    if [ ${#PODS[@]} -eq 0 ]; then
        echo -e "${RED}❌ No running pods found in namespace $CURRENT_NS.${NC}"
        exit 1
    fi

    echo -e "${BOLD}Select the application pod from which to test Kafka connectivity:${NC}"
    select TARGET_POD in "${PODS[@]}"; do
        if [ -n "$TARGET_POD" ]; then break; else echo -e "${RED}Invalid selection.${NC}"; fi
    done
else
    TARGET_POD=$(kubectl get pods -n "$CURRENT_NS" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E "$POD_INPUT" | head -n 1)
fi

if [ -z "$TARGET_POD" ]; then
    echo -e "${RED}❌ Error: No pod matching '$POD_INPUT' found.${NC}"
    exit 1
fi

if [ -z "$BROKER_INPUT" ]; then
    read -p "🎯 Enter Kafka Bootstrap Broker (e.g. kafka-cluster-kafka-bootstrap:9092) : " TARGET_BROKER
else
    TARGET_BROKER="$BROKER_INPUT"
fi

if [ -z "$TARGET_BROKER" ]; then
    echo -e "${RED}❌ Error: No Kafka broker specified.${NC}"
    exit 1
fi

BROKER_HOST=$(echo "$TARGET_BROKER" | cut -d: -f1)
BROKER_PORT=$(echo "$TARGET_BROKER" | cut -d: -f2)

echo -e "\n${BLUE}${BOLD}🌐 RUNNING DIAGNOSTIC FROM POD: ${YELLOW}$TARGET_POD${NC}"
echo -e "   Context      : ${GREEN}$CURRENT_CONTEXT${NC}"
echo -e "   Namespace    : ${GREEN}$CURRENT_NS${NC}"
echo -e "   Kafka Target : ${GREEN}$TARGET_BROKER${NC}\n"

echo -e "${BOLD}[1/2] Testing Network Layer (TCP Handshake)...${NC}"

if kubectl exec -n "$CURRENT_NS" "$TARGET_POD" -- which nc >/dev/null 2>&1; then
    TEST_CMD="kubectl exec -n $CURRENT_NS $TARGET_POD -- nc -w 4 -zv $BROKER_HOST $BROKER_PORT"
elif kubectl exec -n "$CURRENT_NS" "$TARGET_POD" -- which bash >/dev/null 2>&1; then
    TEST_CMD="kubectl exec -n $CURRENT_NS $TARGET_POD -- bash -c \"timeout 4 echo > /dev/tcp/$BROKER_HOST/$BROKER_PORT\""
else
    TEST_CMD="kubectl exec -n $CURRENT_NS $TARGET_POD -- timeout 4 telnet $BROKER_HOST $BROKER_PORT"
fi

eval "$TEST_CMD" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "   └── ${GREEN}✅ SUCCESS: Pod can physically reach Kafka on port $BROKER_PORT!${NC}\n"
else
    echo -e "   └── ${RED}❌ FAILURE: Network connection refused or timed out.${NC}"
    echo -e "       👉 Check your K8s NetworkPolicies, Egress rules, or firewall config.${NC}\n"
    exit 1
fi

echo -e "${BOLD}[2/2] Testing Kafka Layer (Fetching Metadata/Topics)...${NC}"
echo -e "   ℹ️ Spawning a temporary kcat pod to query Kafka cluster layout..."

TMP_POD="kcat-diagnostic-$(date +%s)"
kubectl run $TMP_POD -n "$CURRENT_NS" --rm -i --tty --image=edenhill/kcat:1.7.1 --restart=Never -- kcat -B "$TARGET_BROKER" -L -t 2>/dev/null | tail -n +1 > /tmp/kcat_out.txt

if [ ${PIPESTATUS[0]} -eq 0 ] && [ -s /tmp/kcat_out.txt ]; then
    echo -e "   └── ${GREEN}✅ SUCCESS: Broker metadata retrieved successfully!${NC}"
    echo -e "\n${BOLD}📝 TOPICS DISCOVERED ON CLUSTER :${NC}"
    cat /tmp/kcat_out.txt | grep "topic" | awk '{print "   ├── " $0}' || echo "   (No custom topics found or metadata empty)"
else
    echo -e "   └── ${YELLOW}⚠️ Could not fetch high-level Kafka metadata.${NC}"
    echo -e "       Possible reasons: Kafka requires SASL/SSL auth, or external listeners are misconfigured.${NC}"
fi

rm -f /tmp/kcat_out.txt
echo -e "\n${GREEN}${BOLD}🎉 Diagnostic finished.${NC}"