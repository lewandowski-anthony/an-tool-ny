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

echo -e "${BLUE}${BOLD}Mapping HTTPRoute & Gateway Topology...${NC}"
echo -e "   Context   : ${GREEN}$CURRENT_CONTEXT${NC}"
echo -e "   Namespace : ${GREEN}$CURRENT_NS${NC}\n"

HTTPROUTE_LIST=$(kubectl get httproutes.gateway.networking.k8s.io -n "$CURRENT_NS" -o json 2>/dev/null)

if [ -z "$HTTPROUTE_LIST" ] || [ "$(echo "$HTTPROUTE_LIST" | jq '.items | length')" -eq 0 ]; then
    echo -e "${RED}No HTTPRoutes found in namespace $CURRENT_NS.${NC}"
    exit 1
fi

RAW_MAP=$(echo "$HTTPROUTE_LIST" | jq -r '
  .items[]? | . as $item | .metadata.name as $name |
  (if ($item.spec.parentRefs and ($item.spec.parentRefs | length) > 0) then $item.spec.parentRefs[]?.name else "*" end) as $gw |
  (if ($item.spec.hostnames and ($item.spec.hostnames | length) > 0) then $item.spec.hostnames[]? else "*" end) as $host |
  (if ($item.spec.rules and ($item.spec.rules | length) > 0) then $item.spec.rules[]? else {backendRefs:[]} end) | . as $rule |
  (if $rule.matches and ($rule.matches | length) > 0 then ($rule.matches[]? | .path.value // "/") else "/" end) as $path |
  (if $rule.backendRefs and ($rule.backendRefs | length) > 0 then $rule.backendRefs[]? else {name:"None",port:"-"} end) |
  "\($name)|\($gw)|\($host)|\($path)|\(.name)|\(.port // "-")"
' 2>/dev/null)

if [ -z "$RAW_MAP" ]; then
    echo -e "${YELLOW}HTTPRoutes found but no routing matrix could be generated.${NC}"
    exit 0
fi

echo "$RAW_MAP" | awk -F'|' -v env_green="$GREEN" -v env_yellow="$YELLOW" -v env_blue="$BLUE" -v env_nc="$NC" -v env_bold="$BOLD" '
BEGIN {
    max_route = length("HTTPROUTE");
    max_gw    = length("PARENT GATEWAY");
    max_host  = length("HOST (HOSTNAME)");
    max_path  = length("PATH MATCH");
    max_svc   = length("BACKEND SERVICE");
    max_port  = length("PORT");
}
{
    if (length($1) > max_route) max_route = length($1)
    if (length($2) > max_gw) max_gw = length($2)
    if (length($3) > max_host) max_host = length($3)
    if (length($4) > max_path) max_path = length($4)
    if (length($5) > max_svc) max_svc = length($5)
    if (length($6) > max_port) max_port = length($6)

    r_route[NR]=$1; r_gw[NR]=$2; r_host[NR]=$3; r_path[NR]=$4; r_svc[NR]=$5; r_port[NR]=$6; rows++
}
END {
    fmt_h = sprintf("%s%%-%ds │ %%-%ds │ %%-%ds │ %%-%ds │ %%-%ds │ %%-%ds%s\n", env_bold, max_route, max_gw, max_host, max_path, max_svc, max_port, env_nc)
    printf fmt_h, "HTTPROUTE", "PARENT GATEWAY", "HOST (HOSTNAME)", "PATH MATCH", "BACKEND SERVICE", "PORT"

    for(i=1; i<=max_route; i++) printf "─"; printf "─┼─"
    for(i=1; i<=max_gw; i++) printf "─"; printf "─┼─"
    for(i=1; i<=max_host; i++) printf "─"; printf "─┼─"
    for(i=1; i<=max_path; i++) printf "─"; printf "─┼─"
    for(i=1; i<=max_svc; i++) printf "─"; printf "─┼─"
    for(i=1; i<=max_port; i++) printf "─"; printf "\n"

    fmt_r = sprintf("%%-%ds │ %s%%-%ds%s │ %s%%-%ds%s │ %s%%-%ds%s │ %s%%-%ds%s │ %%-%ds\n", max_route, env_blue, max_gw, env_nc, env_blue, max_host, env_nc, env_yellow, max_path, env_nc, env_green, max_svc, env_nc, max_port)
    for(i=1; i<=rows; i++) {
        printf fmt_r, r_route[i], r_gw[i], r_host[i], r_path[i], r_svc[i], r_port[i]
    }
}'