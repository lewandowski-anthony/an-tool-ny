#!/bin/bash

set -e

DETECT_OS() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]] || [[ "$OSTYPE" == "mingw"* ]]; then
        echo "windows"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ] || [ -f /etc/system-release ]; then
        echo "rhel"
    else
        echo "unknown"
        exit 1
    fi
}

WIN_INSTALL() {
    local bin=$1
    local winget_id=$2
    if ! command -v "$bin" &> /dev/null; then
        if command -v winget &> /dev/null; then
            echo "Installing $bin via winget..."
            winget install --id "$winget_id" --silent --accept-source-agreements --accept-package-agreements || echo "Failed to install $bin"
        else
            echo "Warning: winget not found. Please install $bin manually."
        fi
    else
        echo "$bin is already installed."
    fi
}

INSTALL_MAC() {
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update

    for dep in curl jq yq openssl lsof node kubectl; do
        if ! command -v "$dep" &> /dev/null; then
            brew install "$dep"
        else
            echo "$dep is already installed."
        fi
    done

    if ! command -v trivy &> /dev/null; then
        brew install aquasecurity/trivy/trivy
    else
        echo "trivy is already installed."
    fi
}

INSTALL_WINDOWS() {
    WIN_INSTALL "curl" "CURL.CURL"
    WIN_INSTALL "jq" "jqlang.jq"
    WIN_INSTALL "yq" "mikefarah.yq"
    WIN_INSTALL "openssl" "OpenSSL.OpenSSL"
    WIN_INSTALL "node" "NodeJS.NodeJS"
    WIN_INSTALL "kubectl" "Kubernetes.kubectl"
    WIN_INSTALL "trivy" "AquaSecurity.Trivy"
    echo "Note: lsof is not natively supported on Windows environments."
}

INSTALL_DEBIAN() {
    sudo apt-get update
    for dep in curl jq openssl lsof nodejs npm gpg; do
        if ! command -v "$dep" &> /dev/null; then
            sudo apt-get install -y "$dep"
        else
            echo "$dep is already installed."
        fi
    done

    if ! command -v yq &> /dev/null; then
        sudo curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq
        sudo chmod +x /usr/local/bin/yq
    fi

    if ! command -v kubectl &> /dev/null; then
        sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi

    if ! command -v trivy &> /dev/null; then
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
        echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb stable main" | sudo tee /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install -y trivy
    fi
}

INSTALL_RHEL() {
    PKG_MAN="yum"
    command -v dnf &> /dev/null && PKG_MAN="dnf"

    for dep in curl jq openssl lsof nodejs npm; do
        if ! command -v "$dep" &> /dev/null; then
            sudo $PKG_MAN install -y "$dep"
        else
            echo "$dep is already installed."
        fi
    done

    if ! command -v yq &> /dev/null; then
        sudo curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq
        sudo chmod +x /usr/local/bin/yq
    fi

    if ! command -v kubectl &> /dev/null; then
        sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi

    if ! command -v trivy &> /dev/null; then
        echo -e "[trivy]\nname=Trivy repository\nbaseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/\ngpgcheck=1\nenabled=1\ngpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key" | sudo tee /etc/yum.repos.repositories.d/trivy.repo
        sudo $PKG_MAN makecache
        sudo $PKG_MAN install -y trivy
    fi
}

OS=$(DETECT_OS)
echo "Detected operating system environment: $OS"

if [ "$OS" = "macos" ]; then
    INSTALL_MAC
elif [ "$OS" = "windows" ]; then
    INSTALL_WINDOWS
elif [ "$OS" = "debian" ]; then
    INSTALL_DEBIAN
elif [ "$OS" = "rhel" ]; then
    INSTALL_RHEL
fi

echo "All setup handles processed successfully!"