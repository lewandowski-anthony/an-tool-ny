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

echo -e "${BLUE}${BOLD}Fetching available deployments in namespace: ${YELLOW}$CURRENT_NS${NC}\n"

DEPLOYMENTS=($(kubectl get deployments -n "$CURRENT_NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null))

if [ ${#DEPLOYMENTS[@]} -eq 0 ]; then
    echo -e "${RED}No deployments found in namespace $CURRENT_NS.${NC}"
    exit 1
fi

echo -e "${BOLD}Select the deployment you want to extract the .env from:${NC}"
select TARGET_DEPLOYMENT in "${DEPLOYMENTS[@]}"; do
    if [ -n "$TARGET_DEPLOYMENT" ]; then
        echo -e "\nSelected Deployment: ${GREEN}${BOLD}$TARGET_DEPLOYMENT${NC}\n"
        break
    else
        echo -e "${RED}Invalid selection. Please choose a valid number.${NC}"
    fi
done

OUTPUT_DIR="${SCRIPT_DIR}/results"
mkdir -p "$OUTPUT_DIR"

SAFE_CONTEXT=$(echo "$CURRENT_CONTEXT" | sed 's/[^a-zA-Z0-9_-]/_/g')
ENV_FILE="${OUTPUT_DIR}/${TARGET_DEPLOYMENT}_${CURRENT_NS}_${SAFE_CONTEXT}.env"
touch "$ENV_FILE"

echo -e "${BLUE}${BOLD}Starting Environment Extractor (.env)${NC}"

POD=$(kubectl get pods -n "$CURRENT_NS" -l "app.kubernetes.io/name=$TARGET_DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || \
      kubectl get pods -n "$CURRENT_NS" -l "app=$TARGET_DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || \
      kubectl get pods -n "$CURRENT_NS" -o json | jq -r --arg deploy "$TARGET_DEPLOYMENT" '.items[] | select(.metadata.name | startswith($deploy)) | .metadata.name' | head -n 1)

if [ -z "$POD" ]; then
    echo -e "${RED}Error: No active pods found for deployment $TARGET_DEPLOYMENT.${NC}"
    exit 1
fi

echo -e "${BLUE}Extracting full environment from pod:${NC} ${BOLD}$POD${NC}"

POD_JSON=$(kubectl get pod "$POD" -n "$CURRENT_NS" -o json 2>/dev/null)

> "$ENV_FILE"

echo "# === HARDCODED ENVIRONMENT VARIABLES ===" >> "$ENV_FILE"
echo "$POD_JSON" | jq -r '.spec.containers[].env[]? | select(.value != null) | "\(.name)=\(.value)"' >> "$ENV_FILE"
echo "" >> "$ENV_FILE"

echo "# === INJECTED FROM GLOBALS SECRETS (envFrom) ===" >> "$ENV_FILE"
SECRET_FROM=$(echo "$POD_JSON" | jq -r '.spec.containers[].envFrom[]? | select(.secretRef != null) | .secretRef.name')
for SEC in $SECRET_FROM; do
    echo -e "   ├── ${GREEN}Extracting global secret:${NC} $SEC"
    echo "# --- From Secret: $SEC ---" >> "$ENV_FILE"
    kubectl get secret "$SEC" -n "$CURRENT_NS" -o json 2>/dev/null | jq -r '.data | to_entries[] | "\(.key)=\(.value | @base64d)"' >> "$ENV_FILE"
done
echo "" >> "$ENV_FILE"

echo "# === INJECTED FROM GLOBALS CONFIGMAPS (envFrom) ===" >> "$ENV_FILE"
CM_FROM=$(echo "$POD_JSON" | jq -r '.spec.containers[].envFrom[]? | select(.configMapRef != null) | .configMapRef.name')
for CM in $CM_FROM; do
    echo -e "   ├── ${GREEN}Extracting global configmap:${NC} $CM"
    echo "# --- From ConfigMap: $CM ---" >> "$ENV_FILE"
    kubectl get configmap "$CM" -n "$CURRENT_NS" -o json 2>/dev/null | jq -r '.data | to_entries[] | "\(.key)=\(.value)"' >> "$ENV_FILE"
done
echo "" >> "$ENV_FILE"

echo "# === SPECIFIC MAPPED SECRETS (valueFrom) ===" >> "$ENV_FILE"
echo "$POD_JSON" | jq -r '.spec.containers[].env[]? | select(.valueFrom.secretKeyRef != null) | "\(.name)|\(.valueFrom.secretKeyRef.name)|\(.valueFrom.secretKeyRef.key)"' | while read -r line; do
    if [ -n "$line" ]; then
        VAR_NAME=$(echo "$line" | cut -d'|' -f1)
        SEC_NAME=$(echo "$line" | cut -d'|' -f2)
        SEC_KEY=$(echo "$line" | cut -d'|' -f3)
        VAL_DECODED=$(kubectl get secret "$SEC_NAME" -n "$CURRENT_NS" -o jsonpath="{.data.$SEC_KEY}" 2>/dev/null | base64 --decode 2>/dev/null)
        echo "$VAR_NAME=$VAL_DECODED" >> "$ENV_FILE"
    fi
done
echo "" >> "$ENV_FILE"

echo "# === SPECIFIC MAPPED CONFIGMAPS (valueFrom) ===" >> "$ENV_FILE"
echo "$POD_JSON" | jq -r '.spec.containers[].env[]? | select(.valueFrom.configMapKeyRef != null) | "\(.name)|\(.valueFrom.configMapKeyRef.name)|\(.valueFrom.configMapKeyRef.key)"' | while read -r line; do
    if [ -n "$line" ]; then
        VAR_NAME=$(echo "$line" | cut -d'|' -f1)
        CM_NAME=$(echo "$line" | cut -d'|' -f2)
        CM_KEY=$(echo "$line" | cut -d'|' -f3)
        VAL_RAW=$(kubectl get configmap "$CM_NAME" -n "$CURRENT_NS" -o jsonpath="{.data.$CM_KEY}" 2>/dev/null)
        echo "$VAR_NAME=$VAL_RAW" >> "$ENV_FILE"
    fi
done

if [ -s "$ENV_FILE" ]; then
    sed -i.bak '/^# ===/N;/^\n$/D' "$ENV_FILE" 2>/dev/null && rm "${ENV_FILE}.bak" 2>/dev/null
    echo -e "   └── ${GREEN}Saved to:${NC} ${ENV_FILE}"
else
    rm "$ENV_FILE"
    echo -e "   └── ${YELLOW}No environment variables found.${NC}"
fi
echo ""

echo -e "${GREEN}${BOLD}Done! Output file:${NC} $ENV_FILE"