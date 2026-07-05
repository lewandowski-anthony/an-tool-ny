# Maven Gatekeeper

Maven Gatekeeper is a localized, containerized security and quality assurance tool designed for Java applications. It integrates secret scanning, dependency vulnerability analysis, and automated unit
testing into a single, isolated execution environment.

---

## Features

* **Secret Detection:** Scans the repository for hardcoded secrets, API keys, and credentials using Gitleaks.
* **Vulnerability Scanning:** Identifies critical and high-severity Common Vulnerabilities and Exposures (CVEs) within project dependencies using Trivy.
* **Automated Testing:** Compiles the application and executes the Spring Boot test suite using Maven.
* **Environment Isolation:** Runs entirely inside a Docker container, eliminating the need to install specific Java, Maven, or security CLI tools on the host machine.

---

## Prerequisites

* Docker installed and running on the host system.
* A Java/Maven project with a valid `pom.xml` file in the working directory.

---

## Building the Image

To construct the Maven Gatekeeper Docker image, execute the following command from the directory containing the `Dockerfile`:

```bash
docker build -t maven-gatekeeper .
```

_With Java version_
```bash
docker build --build-arg JAVA_VERSION=25 -t garde-barriere .
```

---

## Usage Guide

The container requires mounting the local project directory into the container environment. Depending on your artifact repository configuration or cloud provider setup, select the appropriate
execution command from the options below.

### Standard / Nexus Configuration

Use this command if your project relies on a standard environment or pulls private dependencies via a Nexus repository configured in your global Maven settings.

```bash
docker run --rm \
  -v "$(pwd)":/apps \
  -v "$HOME/.m2/settings.xml:/root/.m2/settings.xml" \
  -v "$HOME/.m2/repository:/root/.m2/repository" \
  maven-gatekeeper
```

### Google Cloud Platform (GCP) Configuration

Use this command if your Maven build requires authentication with Google Artifact Registry or other GCP services.

```bash
docker run --rm \
  -v "$(pwd)":/apps \
  -v "$HOME/.config/gcloud:/root/.config/gcloud" \
  -v "$HOME/.m2/settings.xml:/root/.m2/settings.xml" \
  -v "$HOME/.m2/repository:/root/.m2/repository" \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json \
  maven-gatekeeper
```

### Amazon Web Services (AWS) Configuration

Use this command if your Maven build interacts with AWS CodeArtifact or requires AWS credentials to access external resources.

```bash
docker run --rm \
  -v "$(pwd)":/apps \
  -v "$HOME/.aws:/root/.aws" \
  -v "$HOME/.m2/settings.xml:/root/.m2/settings.xml" \
  -v "$HOME/.m2/repository:/root/.m2/repository" \
  -e AWS_PROFILE=default \
  maven-gatekeeper
```

---

## Volume Mount Breakdown

| Mount Source             | Container Destination    | Purpose                                                                                               |
|:-------------------------|:-------------------------|:------------------------------------------------------------------------------------------------------|
| `$(pwd)`                 | `/apps`                  | Maps the current working directory containing the source code for scanning and testing.               |
| `$HOME/.m2/settings.xml` | `/root/.m2/settings.xml` | Provides access to host Maven settings, including repository mirrors and authentication credentials.  |
| `$HOME/.m2/repository`   | `/root/.m2/repository`   | Caches downloaded dependencies on the host machine to prevent downloading artifacts during every run. |
| `$HOME/.config/gcloud`   | `/root/.config/gcloud`   | Forwards local Google Cloud configurations for artifact registry access.                              |
| `$HOME/.aws`             | `/root/.aws`             | Forwards local AWS credentials and profiles for authenticated operations.                             |

---

## Pipeline Execution Details

When executed, the container sequentially runs the following verification phases:

1. **Git Configuration:** Configures the working directory as a safe zone within Git to allow analysis.
2. **Secret Scanning:** Executes Gitleaks to inspect the codebase history for exposed secrets.
3. **Test Automation:** Runs `mvn clean test` to compile code and verify core application logic.
4. **Dependency Audit:** Executes a Trivy filesystem scan targeted exclusively at high and critical severity vulnerabilities, terminating with an error exit code if any are discovered.