#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

NAMESPACE=""
KUBE_CONTEXT=""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

mkdir -p "${SCRIPT_DIR}/results"
REPORT_FILE="${SCRIPT_DIR}/results/namespace_audit_${CURRENT_NS}_${TIMESTAMP}.txt"

print_section() {
    local title=$1
    local color=$2
    echo -e "${color}${BOLD}==========================================================${NC}"
    echo -e "${color}${BOLD} $title${NC}"
    echo -e "${color}${BOLD}==========================================================${NC}"
}

{
    echo -e "${CYAN}┌────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│         ${BOLD}KUBERNETES NAMESPACE FULL AUDIT${NC}${CYAN}                │${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${BOLD}Context${NC}   : ${BLUE}$CURRENT_CONTEXT${NC}"
    echo -e "  ${BOLD}Namespace${NC} : ${PURPLE}$CURRENT_NS${NC}"
    echo -e "  ${BOLD}Date${NC}      : $(date)"
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    echo ""

    print_section "🚨 ALERTS & ANOMALIES (Pods not running or crashed)" "$RED"
    CRASHED_PODS=$(kubectl get pods -n "$CURRENT_NS" --no-headers 2>/dev/null | grep -v "Running" | grep -v "Completed")
    if [ -n "$CRASHED_PODS" ]; then
        echo -e "${RED}$CRASHED_PODS${NC}" | sed 's/^/  /'
    else
        echo -e "  ${GREEN}✅ All pods are healthy or completed.${NC}"
    fi
    echo ""

    print_section "📦 PODS GLOBAL OVERVIEW" "$BLUE"
    kubectl get pods -n "$CURRENT_NS" -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount,IP:.status.podIP,AGE:.metadata.creationTimestamp 2>/dev/null | sed 's/^/  /'
    echo ""

    print_section "📊 RESOURCE CONSUMPTION (Top Pods)" "$YELLOW"
    kubectl top pod -n "$CURRENT_NS" 2>/dev/null | sed 's/^/  /' || echo -e "  ${YELLOW}⚠️ metrics-server not available or loading.${NC}"
    echo ""

    print_section "🛑 15 RECENT UNHEALTHY EVENTS" "$RED"
    kubectl get events -n "$CURRENT_NS" --sort-by='.metadata.creationTimestamp' 2>/dev/null | grep -E -i "warning|error|fail|kill|oom" | tail -n 15 | sed 's/^/  /'
    echo ""

    print_section "🌐 NETWORKING & ROUTING (Services, Ingress, HTTPRoutes)" "$CYAN"
    echo -e "${BOLD}--- Services ---${NC}"
    kubectl get svc -n "$CURRENT_NS" -o wide 2>/dev/null | sed 's/^/  /'
    echo ""
    echo -e "${BOLD}--- Ingresses ---${NC}"
    kubectl get ingress -n "$CURRENT_NS" 2>/dev/null | sed 's/^/  /'
    echo ""
    echo -e "${BOLD}--- Gateway API HTTPRoutes ---${NC}"
    if kubectl api-resources | grep -q "httproutes"; then
        kubectl get httproutes -n "$CURRENT_NS" 2>/dev/null | sed 's/^/  /' || echo "  No HTTPRoutes found."
    else
        echo "  [Info] Gateway API (httproutes) CRD not installed in this cluster."
    fi
    echo ""

    print_section "🔑 SECRETS LIST & DECODED DATA" "$PURPLE"
    SECRET_LIST=$(kubectl get secrets -n "$CURRENT_NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -n "$SECRET_LIST" ]; then
        for SEC in $SECRET_LIST; do
            SEC_TYPE=$(kubectl get secret "$SEC" -n "$CURRENT_NS" -o jsonpath='{.type}' 2>/dev/null)
            echo -e "${BOLD}🔒 Secret:${NC} ${PURPLE}$SEC${NC} (${YELLOW}$SEC_TYPE${NC})"
            kubectl get secret "$SEC" -n "$CURRENT_NS" -o json 2>/dev/null | jq -r '.data | to_entries[] | "   ├── \(.key): \(.value | @base64d)"' 2>/dev/null || echo "   [Error decoding or empty data]"
            echo ""
        done
    else
        echo "  No secrets found."
    fi
    echo ""

    print_section "🦅 FLUX CD GIT REPOSITORIES & KUSTOMIZATIONS" "$GREEN"
    echo -e "${BOLD}--- Flux GitRepositories ---${NC}"
    if kubectl api-resources | grep -q "gitrepositories"; then
        kubectl get gitrepositories -n "$CURRENT_NS" 2>/dev/null | sed 's/^/  /' || echo "  No GitRepositories found."
    else
        echo "  [Info] Flux CD GitRepositories CRD not installed."
    fi
    echo ""
    echo -e "${BOLD}--- Flux Kustomizations ---${NC}"
    if kubectl api-resources | grep -q "kustomizations"; then
        kubectl get kustomizations -n "$CURRENT_NS" 2>/dev/null | sed 's/^/  /' || echo "  No Kustomizations found."
    else
        echo "  [Info] Flux CD Kustomizations CRD not installed."
    fi
    echo ""

    print_section "⚙️ CONFIGURATIONS & STORAGE" "$NC"
    echo -e "  • ConfigMaps : ${YELLOW}$(kubectl get configmap -n "$CURRENT_NS" --no-headers 2>/dev/null | wc -l | xargs)${NC}"
    echo -e "  • PVCs       : ${YELLOW}$(kubectl get pvc -n "$CURRENT_NS" --no-headers 2>/dev/null | wc -l | xargs)${NC}"
    echo ""
    if [ "$(kubectl get pvc -n "$CURRENT_NS" --no-headers 2>/dev/null | wc -l)" -gt 0 ]; then
        kubectl get pvc -n "$CURRENT_NS" | sed 's/^/  /'
        echo ""
    fi

    print_section "⏳ WORKLOADS STATUS (Deployments, StatefulSets, CronJobs)" "$NC"
    echo -e "${BOLD}--- Deployments ---${NC}"
    kubectl get deployments -n "$CURRENT_NS" 2>/dev/null | sed 's/^/  /'
    echo ""
    if [ "$(kubectl get statefulset -n "$CURRENT_NS" --no-headers 2>/dev/null | wc -l)" -gt 0 ]; then
        echo -e "${BOLD}--- StatefulSets ---${NC}"
        kubectl get statefulset -n "$CURRENT_NS" 2>/dev/null | sed 's/^/  /'
        echo ""
    fi
    if [ "$(kubectl get cronjob -n "$CURRENT_NS" --no-headers 2>/dev/null | wc -l)" -gt 0 ]; then
        echo -e "${BOLD}--- CronJobs ---${NC}"
        kubectl get cronjob -n "$CURRENT_NS" 2>/dev/null | sed 's/^/  /'
        echo ""
    fi
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
} | tee "$REPORT_FILE"

echo ""
echo -e "${GREEN}✔ Audit complete. Raw report (including color codes) saved to: $REPORT_FILE${NC}"