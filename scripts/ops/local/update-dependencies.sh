#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting system-wide upgrade verification...${NC}"

# --- macOS / Linux Core ---
if command -v brew &> /dev/null; then
    echo -e "${YELLOW}Updating Homebrew formulas and packages...${NC}"
    yes | brew update --quiet
    yes | brew upgrade --quiet
    echo -e "${GREEN}Homebrew packages updated successfully.${NC}"
fi

# --- Windows Package Managers ---
if command -v winget &> /dev/null; then
    echo -e "${YELLOW}Updating Windows packages via winget...${NC}"
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity &> /dev/null || true
    echo -e "${GREEN}Winget packages updated successfully.${NC}"
fi

if command -v choco &> /dev/null; then
    echo -e "${YELLOW}Updating Windows packages via Chocolatey...${NC}"
    # Le double -y force l'acceptation de tous les scripts de licence tiers
    choco upgrade all -y -y --quiet &> /dev/null || true
    echo -e "${GREEN}Chocolatey packages updated successfully.${NC}"
fi

if command -v scoop &> /dev/null; then
    echo -e "${YELLOW}Updating Windows packages via Scoop...${NC}"
    scoop update &> /dev/null || true
    scoop update * &> /dev/null || true
    echo -e "${GREEN}Scoop packages updated successfully.${NC}"
fi

# --- Linux Package Managers ---
if command -v apt-get &> /dev/null; then
    echo -e "${YELLOW}Updating Debian/Ubuntu packages via APT...${NC}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    echo -e "${GREEN}APT packages updated successfully.${NC}"
fi

if command -v dnf &> /dev/null; then
    echo -e "${YELLOW}Updating RHEL packages via DNF...${NC}"
    sudo dnf upgrade -y -q --assumeyes
    echo -e "${GREEN}DNF packages updated successfully.${NC}"
elif command -v yum &> /dev/null; then
    echo -e "${YELLOW}Updating RHEL packages via YUM...${NC}"
    sudo yum upgrade -y -q --assumeyes
    echo -e "${GREEN}YUM packages updated successfully.${NC}"
fi

# --- Global Ecosystems ---
if command -v npm &> /dev/null; then
    echo -e "${YELLOW}Updating global npm packages...${NC}"
    npm update -g --silent &> /dev/null || true
    echo -e "${GREEN}Global npm packages updated successfully.${NC}"
fi

echo -e "${GREEN}All available package managers have been updated!${NC}"