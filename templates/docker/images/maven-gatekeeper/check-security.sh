#!/bin/bash
set -e

echo "====================================================="
echo "🛡️  STARTING SECURITY & QUALITY CHECK SHIELD 🛡️"
echo "====================================================="

git config --global --add safe.directory /apps

echo -e "\nAnalyzing with Gitleaks..."
gitleaks detect --source=. --verbose --redact

echo -e "\nCompiling Spring Boot Application (Skipping Tests)..."
mvn clean compile -DskipTests -Dmaven.test.skip=true

echo -e "\nTrivy Analysis: Searching for vulnerabilities (CVE) in dependencies..."
trivy fs --insecure --severity HIGH,CRITICAL --exit-code 1 .

echo -e "\n====================================================="
echo "✅ ALL CLEAR! Your code is clean and secure."
echo "====================================================="