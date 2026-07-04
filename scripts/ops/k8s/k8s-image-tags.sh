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

echo -e "${BLUE}${BOLD}Fetching running image versions...${NC}"
echo -e "   Context   : ${GREEN}$CURRENT_CONTEXT${NC}"
echo -e "   Namespace : ${GREEN}$CURRENT_NS${NC}\n"

DEPLOY_LIST=$(kubectl get deployments -n "$CURRENT_NS" -o json 2>/dev/null)

if [ -z "$DEPLOY_LIST" ] || [ "$(echo "$DEPLOY_LIST" | jq '.items | length')" -eq 0 ]; then
    echo -e "${RED}No deployments found in namespace $CURRENT_NS.${NC}"
    exit 1
fi

RAW_DATA=$(echo "$DEPLOY_LIST" | jq -r '.items[] | .metadata.name as $dep | .spec.template.spec.containers[] | "\($dep)|\(.name)|\(.image)"' | while read -r line; do
    DEPLOYMENT=$(echo "$line" | cut -d'|' -f1)
    CONTAINER=$(echo "$line" | cut -d'|' -f2)
    FULL_IMAGE=$(echo "$line" | cut -d'|' -f3)

    IMAGE_TAG=$(echo "$FULL_IMAGE" | awk -F: '{ if (NF > 1) print $NF; else print "latest" }')
    IMAGE_PATH=$(echo "$FULL_IMAGE" | sed -E "s/:${IMAGE_TAG}\$//")

    if [[ "$IMAGE_PATH" == */* ]]; then
        IMAGE_REPOSITORY="${IMAGE_PATH%/*}"
        IMAGE_NAME="${IMAGE_PATH##*/}"
    else
        IMAGE_REPOSITORY="-"
        IMAGE_NAME="$IMAGE_PATH"
    fi

    echo "$DEPLOYMENT|$CONTAINER|$IMAGE_REPOSITORY|$IMAGE_NAME|$IMAGE_TAG"
done)

echo "$RAW_DATA" | awk -F'|' -v env_green="$GREEN" -v env_yellow="$YELLOW" -v env_blue="$BLUE" -v env_nc="$NC" -v env_bold="$BOLD" '
BEGIN {
    deployment_width = 10
    container_width = 9
    repository_width = 10
    image_width = 5
}
{
    if (length($1) > deployment_width) deployment_width = length($1)
    if (length($2) > container_width) container_width = length($2)
    if (length($3) > repository_width) repository_width = length($3)
    if (length($4) > image_width) image_width = length($4)
    row_deployment[NR] = $1
    row_container[NR] = $2
    row_repository[NR] = $3
    row_image[NR] = $4
    row_tag[NR] = $5
    total_rows++
}
END {
    header_format = sprintf("%s%%-%ds │ %%-%ds │ %%-%ds │ %%-%ds │ %%s%s\n", env_bold, deployment_width, container_width, repository_width, image_width, env_nc)
    printf header_format, "DEPLOYMENT", "CONTAINER", "REPOSITORY", "IMAGE", "TAG"

    for (i = 1; i <= deployment_width; i++) printf "─"
    printf "─┼─"
    for (i = 1; i <= container_width; i++) printf "─"
    printf "─┼─"
    for (i = 1; i <= repository_width; i++) printf "─"
    printf "─┼─"
    for (i = 1; i <= image_width; i++) printf "─"
    printf "─┼──────────────────\n"

    row_format = sprintf("%%-%ds │ %%-%ds │ %%-%ds │ %s%%-%ds%s │ %s%%s%s\n", deployment_width, container_width, repository_width, env_yellow, image_width, env_nc, env_green, env_nc)
    for (i = 1; i <= total_rows; i++) {
        printf row_format, row_deployment[i], row_container[i], row_repository[i], row_image[i], row_tag[i]
    }
}
'