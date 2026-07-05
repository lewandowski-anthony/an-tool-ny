# Dockerfile Template - Spring Boot High-Performance Image

This directory contains a production-oriented `Dockerfile` for containerizing **Spring Boot** applications (Java 25).

It uses a **Multi-Stage Build** with Spring Boot **Layer Tools** to keep builds fast, make Docker caching effective, and avoid running the application as root.

---

## Key Features of the Dockerfile

* **Multi-Stage Build**: Separates the file extraction stage from the final execution stage, keeping the production image as lean as possible.
* **Spring Boot Layers**: Breaks down the application JAR into 4 distinct layers (`dependencies`, `spring-boot-loader`, `snapshot-dependencies`, `application`). If you modify a single line of code, Docker skips downloading third-party dependencies, speeding up subsequent builds by up to 90%.
* **Non-Root Security**: The application runs under a dedicated, low-privilege system user named `spring` instead of running as `root`.
* **Observability (Datadog)**: Embeds the Datadog Java APM Agent (`dd-java-agent.jar`) for performance monitoring.
* **Proxy / AWS Network Bypass**: Provides an environment variable slot for enterprise proxy configuration, custom certificates, or specific AWS endpoints.

---

## Application Prerequisites

Before triggering the Docker build, configure your Spring Boot application to support layer splitting.

Ensure that your `pom.xml` includes the layering configuration within the Spring Boot plugin block:

```xml
<plugin>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-maven-plugin</artifactId>
<configuration>
<layers>
<enabled>true</enabled>
</layers>
</configuration>
</plugin>
```

---

## Usage Guide

### 1. Compile the Application Locally
Generate your application's JAR file using Maven:
```bash
mvn clean install -DskipTests
```

### 2. Build the Docker Image

#### Standard Usage (Defaulting to version 1.0.0):
```bash
docker build \
--build-arg APP_NAME="my-app-service" \
-t my-app-service:1.0.0 .
```

#### Advanced Usage (CI/CD with Git traceability):
You can dynamically inject the short Git commit SHA to tag your image and automatically configure Datadog version tracking:
```bash
docker build \
--build-arg APP_NAME="my-app-service" \
--build-arg GIT_COMMIT=$(git rev-parse --short HEAD) \
-t my-app-service:$(git rev-parse --short HEAD) .
```

---

## Run the Container

### Simple Local Run
To start your application and map port `8080`:
```bash
docker run -d -p 8080:8080 --name my-running-app my-app-service:1.0.0
```

### Run with JVM Tuning & Corporate Proxy Configuration
If you need to configure JVM memory allocation constraints (`JAVA_OPTS`) or inject system networking properties for a corporate proxy (`PROXY_JAVA_AWS`):
```bash
docker run -d -p 8080:8080 \
-e JAVA_OPTS="-Xms512m -Xmx1024m -Djava.net.useSystemProxies=true" \
-e PROXY_JAVA_AWS="-Dhttp.proxyHost=proxy.my-company.com -Dhttp.proxyPort=8080" \
--name my-running-app my-app-service:1.0.0
```

---

## Extracted Layers Breakdown (Under the Hood)

During the build phase, the intermediate builder image unpacks and categorizes your app as follows:
* `dependencies/`: All third-party library dependencies (Spring Framework, Hibernate, etc., which rarely change).
* `spring-boot-loader/`: Internal Spring Boot classes required to bootstrap and launch the fat JAR.
* `snapshot-dependencies/`: Project dependencies currently in SNAPSHOT versions.
* `application/`: Your compiled custom code (`.class` files) and environment properties (`application.yml`).
