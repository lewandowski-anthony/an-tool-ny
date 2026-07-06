#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

OS_TYPE="$(uname -s)"
DURATION=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--time) DURATION="$2"; shift ;;
        *) log_error "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

clear
log_info "Caffeine mode activated. Keeping your system awake."
if [ -n "$DURATION" ]; then
    log_info "Timer set: System will stay awake for ${DURATION}."
else
    log_warn "No timer set. Close this terminal or press CTRL+C to stop."
fi
echo "--------------------------------------------------"

case "${OS_TYPE}" in
    Darwin*)
        log_success "Running on macOS. Triggering 'caffeinate'..."
        if [ -n "$DURATION" ]; then
            IFS=3
            case $DURATION in
                *s) SECONDS=${DURATION%s} ;;
                *m) SECONDS=$(( ${DURATION%m} * 60 )) ;;
                *h) SECONDS=$(( ${DURATION%h} * 3600 )) ;;
                *) SECONDS=$DURATION ;;
            esac
            caffeinate -idt "$SECONDS"
        else
            caffeinate -id
        fi
        ;;

    Linux*)
        log_success "Running on Linux."
        TIMEOUT_CMD=""
        if [ -n "$DURATION" ]; then
            TIMEOUT_CMD="timeout $DURATION"
        fi

        if command -v systemd-inhibit &> /dev/null; then
            log_info "Using systemd-inhibit to block sleep..."
            if [ -n "$DURATION" ]; then
                systemd-inhibit --why="Caffeine script active" --what=idle:sleep sleep "$DURATION"
            else
                systemd-inhibit --why="Caffeine script active" --what=idle:sleep sleep infinity
            fi
        elif command -v xset &> /dev/null; then
            log_warn "systemd-inhibit not found. Disabling screen blanking via xset..."
            xset s off
            xset -dpms
            trap "xset s on; xset +dpms; exit" INT TERM EXIT

            if [ -n "$DURATION" ]; then
                sleep "$DURATION"
            else
                while true; do sleep 60; done
            fi
        else
            log_error "No compatible power management tool found (systemd-inhibit or xset)."
            exit 1
        fi
        ;;

    CYGWIN*|MINGW*|MSYS*)
        log_success "Running on Windows (Bash environment)."
        log_info "Using PowerShell to prevent system sleep..."

        TOTAL_SECONDS=999999
        if [ -n "$DURATION" ]; then
            case $DURATION in
                *s) TOTAL_SECONDS=${DURATION%s} ;;
                *m) TOTAL_SECONDS=$(( ${DURATION%m} * 60 )) ;;
                *h) TOTAL_SECONDS=$(( ${DURATION%h} * 3600 )) ;;
                *) TOTAL_SECONDS=$DURATION ;;
            esac
        fi

        powershell.exe -Command "
            \$WshShell = New-Object -ComObject WScript.Shell;
            \$totalSeconds = $TOTAL_SECONDS;
            \$elapsed = 0;
            Write-Host 'Simulating keypress to keep Windows awake...' -ForegroundColor Cyan;
            while (\$elapsed -lt \$totalSeconds) {
                Start-Sleep -Seconds 60;
                \$WshShell.SendKeys('{F15}');
                \$elapsed += 60;
            }
        "
        ;;

    *)
        log_error "Unsupported Operating System: ${OS_TYPE}"
        exit 1
        ;;
esac

log_success "Caffeine mode finished. System can now sleep dynamically."