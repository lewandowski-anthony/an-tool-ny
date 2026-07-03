# ==============================================================================
#  an-tool-ny - SWISS ARMY KNIFE ALIASES (Java / Spring / Docker / Git)
# ==============================================================================

# --- MAVEN (Daily time-savers) ---
alias mci="mvn clean install"
alias mcist="mvn clean install -DskipTests"         # Fast build without running tests
alias mt="mvn test"
alias mcv="mvn clean verify"
alias mboot="mvn spring-boot:run"                   # Run Spring Boot app directly
alias mboot-debug="mvn spring-boot:run -Dspring-boot.run.jvmArguments='-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005'" # Ready for IntelliJ remote debugging

# --- GRADLE ---
alias gcb="./gradlew clean build"
alias gcbst="./gradlew clean build -x test"
alias gboot="./gradlew bootRun"

# --- DOCKER & DOCKER COMPOSE ---
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" # Readable docker ps output
alias dlo="docker logs -f --tail 100"                                      # Follow logs from the last 100 lines
alias ddown="docker compose down --v"                                      # Stop and clean volumes (goodbye corrupted data)
alias dup="docker compose up -d"                                           # Launch containers (DB, Kafka, Keycloak) in background
alias dnuke="docker stop \$(docker ps -aq) && docker rm \$(docker ps -aq)" # Stop and remove EVERYTHING (panic mode)

# --- GIT PRO ---
alias gs="git status"
alias gaa="git add ."
alias gc="git commit -m"
alias gpush="git push origin \$(git branch --show-current)"              # Push current branch without thinking
alias gpull="git pull origin \$(git branch --show-current)"              # Pull current branch
alias gl="git log --oneline --graph --decorate -n 10"                    # Visual and compact Git history
# Delete all local branches whose remote counterparts have been merged and deleted:
alias git-clean-branches="git branch -vv | grep 'gone]' | awk '{print \$1}' | xargs -r git branch -D"

# --- UTILITIES & SHORTCUTS ---
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."
alias myip="curl ifconfig.me && echo"                                    # Get your public IP in one command

# --- AN-TOOL-NY SPECIFIC ---
alias an-tool-ny-cd="cd $HOME/an-tool-ny"                                # Go directly to your toolbox root
alias an-tool-ny-reload="source \$HOME/.bashrc 2>/dev/null || source \$HOME/.zshrc 2>/dev/null" # Reload aliases after modification