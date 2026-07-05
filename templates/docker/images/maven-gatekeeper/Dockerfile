ARG JAVA_VERSION=25
FROM eclipse-temurin:${JAVA_VERSION}-jdk-alpine

ARG JAVA_VERSION
ARG GITLEAKS_VERSION=8.18.2
ARG TRIVY_VERSION=0.49.1

RUN echo "Building the Gatekeeper for Java ${JAVA_VERSION}..."

RUN apk add --no-cache git curl bash ca-certificates maven && update-ca-certificates

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then GITLEAKS_ARCH="x64"; else GITLEAKS_ARCH="arm64"; fi && \
    curl -k -sSL https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${GITLEAKS_ARCH}.tar.gz \
    | tar -xz -C /usr/local/bin gitleaks

RUN apk add --no-cache trivy --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

WORKDIR /apps

COPY check-security.sh /usr/local/bin/check-security.sh
RUN chmod +x /usr/local/bin/check-security.sh

ENTRYPOINT ["/usr/local/bin/check-security.sh"]