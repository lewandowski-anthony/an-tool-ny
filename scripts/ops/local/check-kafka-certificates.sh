#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

CERT=""
KEY=""
CA=""

usage() {
    echo "Usage: $0 -c <cert_file> -k <key_file> -a <ca_file>"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--cert) CERT="$2"; shift 2 ;;
        -k|--key) KEY="$2"; shift 2 ;;
        -a|--ca) CA="$2"; shift 2 ;;
        *) usage ;;
    esac
done

if [ -z "$CERT" ] || [ -z "$KEY" ] || [ -z "$CA" ]; then
    usage
fi

echo -e "${BLUE}${BOLD}=== KAFKA CERTIFICATE STRUCTURE AUDIT ===${NC}\n"

if [ ! -f "$CA" ]; then echo -e "${RED}Error: CA file not found at '$CA'${NC}"; exit 1; fi
if [ ! -f "$CERT" ]; then echo -e "${RED}Error: Certificate file not found at '$CERT'${NC}"; exit 1; fi
if [ ! -f "$KEY" ]; then echo -e "${RED}Error: Private Key file not found at '$KEY'${NC}"; exit 1; fi

echo -e "${BLUE}[1/4] Authority (CA) Information:${NC}"
echo -e "  • Subject     : $(openssl x509 -noout -subject -in "$CA" | sed 's/subject=//')"
echo -e "  • Expiration  : $(openssl x509 -noout -enddate -in "$CA" | sed 's/notAfter=//')"
if openssl x509 -checkend 0 -noout -in "$CA" &>/dev/null; then
    echo -e "  • Status      : ${GREEN}VALID${NC}"
else
    echo -e "  • Status      : ${RED}EXPIRED${NC}"
fi
echo ""

echo -e "${BLUE}[2/4] Client Certificate Information:${NC}"
echo -e "  • Subject     : $(openssl x509 -noout -subject -in "$CERT" | sed 's/subject=//')"
echo -e "  • Issuer      : $(openssl x509 -noout -issuer -in "$CERT" | sed 's/issuer=//')"
echo -e "  • Expiration  : $(openssl x509 -noout -enddate -in "$CERT" | sed 's/notAfter=//')"
if openssl x509 -checkend 0 -noout -in "$CERT" &>/dev/null; then
    echo -e "  • Status      : ${GREEN}VALID${NC}"
else
    echo -e "  • Status      : ${RED}EXPIRED${NC}"
fi
echo ""

echo -e "${BLUE}[3/4] Cryptographic Key-Pair Match:${NC}"

CERT_MD5=$(openssl x509 -noout -modulus -in "$CERT" | openssl md5 | awk '{print $1}')
KEY_MD5=$(openssl rsa -noout -modulus -in "$KEY" 2>/dev/null | openssl md5 | awk '{print $1}')

if [ "$CERT_MD5" = "$KEY_MD5" ]; then
    echo -e "  └── ${GREEN}SUCCESS: Private key matches the client certificate exactly!${NC}"
else
    echo -e "  └── ${RED}CRITICAL ERROR: Key mismatch! Private key does not belong to this certificate.${NC}"
fi
echo ""

echo -e "${BLUE}[4/4] Chain Verification (CA -> Cert):${NC}"
if openssl verify -CAfile "$CA" "$CERT" &>/dev/null; then
    echo -e "  └── ${GREEN}SUCCESS: Certificate signature is valid and trusted by the provided CA.${NC}"
else
    echo -e "  └── ${RED}CRITICAL ERROR: Trust chain broken! This CA did not sign this certificate.${NC}"
fi
echo ""