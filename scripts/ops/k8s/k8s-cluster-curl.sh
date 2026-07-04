#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

NAMESPACE=""
KUBE_CONTEXT=""
TARGET_URL=""

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
        --context=*|--ctx=*) KUBE_CONTEXT="${1#*=}"; shift ;;
        --context)          KUBE_CONTEXT="$2"; shift 2 ;;
        --target=*|-t=*)    TARGET_URL="${1#*=}"; shift ;;
        --target|-t)        TARGET_URL="$2"; shift 2 ;;
        *) echo -e "${RED}Unknown argument: $1${NC}"; exit 1 ;;
    esac
done

if [ -n "$KUBE_CONTEXT" ]; then
    kubectl config use-context "$KUBE_CONTEXT" >/dev/null 2>&1
fi

CURRENT_CONTEXT=$(kubectl config current-context)
CURRENT_NS=$( [ -n "$NAMESPACE" ] && echo "$NAMESPACE" || kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null )
CURRENT_NS=${CURRENT_NS:-default}

if [ -z "$TARGET_URL" ]; then
    echo -e "${YELLOW}ℹNo target URL specified. Examples of valid targets:${NC}"
    echo -e "   - Internal service : http://smart-supply-api:8080/actuator/health"
    echo -e "   - External database: google.com:443 (for raw port check)"
    echo -e ""
    read -p "Enter target URL or Host:Port : " TARGET_URL
fi

if [ -z "$TARGET_URL" ]; then
    echo -e "${RED}Error: Target cannot be empty.${NC}"
    exit 1
fi

POD_NAME="k8s-network-tester-$(date +%s)"

echo -e "${BLUE}${BOLD}Spawning temporary network-tester pod...${NC}"
echo -e "   Context   : ${GREEN}$CURRENT_CONTEXT${NC}"
echo -e "   Namespace : ${GREEN}$CURRENT_NS${NC}"
echo -e "   Target    : ${YELLOW}$TARGET_URL${NC}\n"

if [[ "$TARGET_URL" =~ : ]] && [[ ! "$TARGET_URL" =~ http ]]; then
    HOST=$(echo "$TARGET_URL" | cut -d: -f1)
    PORT=$(echo "$TARGET_URL" | cut -d: -f2)
    echo -e "${BLUE}Testing raw TCP connection to $HOST on port $PORT...${NC}"
    kubectl run $POD_NAME -n "$CURRENT_NS" --rm -i --tty --image=busybox --restart=Never -- nc -zv -w 5 "$HOST" "$PORT"
else
    echo -e "${BLUE}Executing HTTP GET Request against $TARGET_URL...${NC}"
    kubectl run $POD_NAME -n "$CURRENT_NS" --rm -i --tty --image=curlimages/curl --restart=Never -- curl -ivs --connect-timeout 5 "$TARGET_URL"
fi