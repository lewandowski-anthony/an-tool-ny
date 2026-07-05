# ==============================================================================
#  an-tool-ny - SWISS ARMY KNIFE ALIASES (Java / Spring / Docker / Git / Ops)
# ==============================================================================

# --- CORE PATHS ---
# Redefine this variable with your path of the tool box if necessary
AN_TOOLS_DIR="$HOME/Developer/an-tool-ny"
AN_TOOLS_SCRIPT_DIR="$AN_TOOLS_DIR/scripts"

# --- MAVEN (Daily time-savers) ---
alias mci="mvn clean install"
alias mcist="mvn clean install -DskipTests"
alias mt="mvn test"
alias mcv="mvn clean verify"
alias mboot="mvn spring-boot:run"
alias mboot-debug="mvn spring-boot:run -Dspring-boot.run.jvmArguments='-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005'"

# --- GRADLE ---
alias gcb="./gradlew clean build"
alias gcbst="./gradlew clean build -x test"
alias gboot="./gradlew bootRun"

# --- DOCKER & DOCKER COMPOSE ---
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dlo="docker logs -f --tail 100"
alias ddown="docker compose down --v"
alias dup="docker compose up -d"
alias dnuke="docker stop \$(docker ps -aq) && docker rm \$(docker ps -aq)"

# --- GIT PRO ---
alias gs="git status"
alias gaa="git add ."
alias gc="git commit -m"
alias gpush="git push origin \$(git branch --show-current)"
alias gpull="git pull origin \$(git branch --show-current)"
alias gl="git log --oneline --graph --decorate -n 10"
alias git-clean-branches="git branch -vv | grep 'gone]' | awk '{print \$1}' | xargs -r git branch -D"

# --- UTILITIES & SHORTCUTS ---
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."
alias myip="curl ifconfig.me && echo"

# --- AN-TOOL-NY: DATABASE ---
alias db-extract="$AN_TOOLS_SCRIPT_DIR/database/db-schema-extractor.sh"
alias pg-gen="$AN_TOOLS_SCRIPT_DIR/database/pg-data-generator.sh"

# --- AN-TOOL-NY: API CONVERTERS ---
alias api-to-bruno="$AN_TOOLS_SCRIPT_DIR/api/openapi-to-bruno.sh"
alias api-to-postman="$AN_TOOLS_SCRIPT_DIR/api/openapi-to-postman.sh"
alias api-to-intellij="$AN_TOOLS_SCRIPT_DIR/api/openapi-to-intellij.sh"

# --- AN-TOOL-NY: DOCKER AUTOMATION ---
alias docker-clean="$AN_TOOLS_SCRIPT_DIR/docker/docker-clean-containers.sh"
alias docker-scan="$AN_TOOLS_SCRIPT_DIR/docker/docker-scan-component.sh"

# --- AN-TOOL-NY: TESTING & IAM ---
alias k6-gen="$AN_TOOLS_SCRIPT_DIR/testing/generate_k6_from_swagger.sh"
alias jwt-decode="$AN_TOOLS_SCRIPT_DIR/iam/jwt-decoder.sh"

# --- AN-TOOL-NY: DEVELOPMENT & LOCAL OPS ---
alias app-analyze="$AN_TOOLS_SCRIPT_DIR/dev/app-ressources-analyze.sh"
alias port-kill="$AN_TOOLS_SCRIPT_DIR/ops/local/port-killer.sh"
alias kafka-cert-check="$AN_TOOLS_SCRIPT_DIR/ops/local/check-kafka-certificates.sh"

# --- AN-TOOL-NY: GIT DevOps ---
alias git-backup-wip="$AN_TOOLS_SCRIPT_DIR/git/git-backup-unpushed.sh"
alias git-purge="$AN_TOOLS_SCRIPT_DIR/git/git-purge-branches.sh"

# --- AN-TOOL-NY: KUBERNETES (K8s Ops) ---
alias k8s-pf="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-port-forward-manager.sh"
alias k8s-images="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-image-tags.sh"
alias k8s-secret="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-secret-extractor.sh"
alias k8s-exec="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-fast-exec.sh"
alias k8s-curl="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-cluster-curl.sh"
alias k8s-ns-analyze="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-namespace-analyzer.sh"
alias k8s-routes="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-httproute-mapper.sh"
alias k8s-kafka-test="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-pod-kafka-test.sh"
alias k8s-pod-clean="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-pod-cleaner.sh"
alias k8s-restart="$AN_TOOLS_SCRIPT_DIR/ops/k8s/k8s-smart-restart.sh"

# --- AN-TOOL-NY: LOCAL SYSTEM & MAINTENANCE ---
alias sys-install="$AN_TOOLS_SCRIPT_DIR/ops/local/install-dependencies.sh"
alias sys-update="$AN_TOOLS_SCRIPT_DIR/ops/local/update-dependencies.sh"

# --- AN-TOOL-NY SYSTEM CONTROL ---
alias an-tool-ny-cd="cd \$AN_TOOLS_DIR"
alias an-tool-ny-reload="source \$HOME/.bashrc 2>/dev/null || source \$HOME/.zshrc 2>/dev/null"