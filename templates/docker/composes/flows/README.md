# Event-Driven Architecture and Messaging via Docker Compose

This repository collects modular Docker Compose configurations to instantiate asynchronous messaging platforms and event-driven architecture components. It covers the foundational infrastructure for
both **Apache Kafka** (distributed event streaming, schema registry, and third-party connectors) and **ActiveMQ Artemis** (an enterprise-grade message broker compliant with JMS standards).

---

## 📋 Infrastructure Reference Table

### Apache Kafka Ecosystem

| Component           | Compose File                     | Host Port           | Primary Usage / Description                                                 |
|:--------------------|:---------------------------------|:--------------------|:----------------------------------------------------------------------------|
| **Kafka Broker**    | `docker-compose-kafka.yaml`      | `9092`              | High-performance distributed event streaming broker.                        |
| **Zookeeper**       | `docker-compose-kafka.yaml`      | *Internal (`2181`)* | Cluster coordinator and metadata management layer.                          |
| **Schema Registry** | `docker-compose-kafka.yaml`      | `8085`              | Centralized registry for data schemas (Avro, JSON, etc.).                   |
| **Kafka Connect**   | `docker-compose.yaml`            | `8083`              | Integration framework to stream data between Kafka and external datastores. |
| **AKHQ UI**         | `docker-compose-kafka-akhq.yaml` | `8080`              | Advanced web console to manage topics, consumer groups, and schemas.        |
| **Kafka UI**        | `docker-compose-kafka-kui.yaml`  | `8080`              | Alternative lightweight and dynamic web console for cluster monitoring.     |

### ActiveMQ Artemis Ecosystem

| Component            | Compose File                   | Web UI Port | Protocol Ports                 | Automatically Initialized Queues                      |
|:---------------------|:-------------------------------|:------------|:-------------------------------|:------------------------------------------------------|
| **ActiveMQ Artemis** | `docker-compose-activemq.yaml` | `8161`      | `61616` (CORE) / `5672` (AMQP) | `myapp.queue`, `myapp.queue.RETRY`, `myapp.queue.DLQ` |

---

## 🎯 Usage Profiles and Core Concepts

### 1. Apache Kafka: High-Throughput Event Streaming

* **Log-Centric Architecture:** Unlike traditional message queues, Kafka handles incoming events as an append-only, distributed record log written straight to disk.
* **Decoupled Consumers:** Messages are not dropped immediately when a consumer reads them. Instead, consumers track their position via an offset, allowing systems to reread historical data on demand.
* **Target Use Cases:**
    * Real-time stream processing and event ingestion pipelines.
    * Application log aggregation and telemetry matrix routing.
    * Implementing Event Sourcing and CQRS patterns within complex microservice boundaries.

### 2. ActiveMQ Artemis: Enterprise Message Broker

* **Standard Specifications:** Strictly conforms to Java Message Service (JMS) 1.1 and 2.0 standards, including enterprise integration patterns (EIP).
* **Strict Communication Models:** Natively enforces standard point-to-point queues (single receiver) and publish-subscribe topics (multiple individual subscribers).
* **Target Use Cases:**
    * Highly transactional operations that dictate strict Exactly-Once delivery execution guarantees.
    * Connecting legacy Service-Oriented Architectures (SOA) with modern components.
    * Multi-protocol topologies requiring immediate out-of-the-box support for MQTT, STOMP, or AMQP.

---

## ⚙️ Included Automation Details

### Automatic Kafka Topic Provisioning

The primary setup relies on a companion service container named `myapp_kafka_init`. On startup, this utility verifies the broker availability and proceeds to create required production-grade
communication channels:

* `myapp.events`: A multi-partitioned topic for handling high-volume operational application traffic.
* `myapp.events.RETRY`: An isolation stream to stagger, delay, or retry messages experiencing intermittent processing errors.
* `myapp.events.DLT` (*Dead Letter Topic*): A terminal queue to trap corrupted data or records that fail repeated execution steps.

### ActiveMQ Address Provisioning via Mounting

The Artemis engine processes initialization files directly from a mounted external configuration manifest (`broker-config.xml`). This maps the root `myapp.queue` domain alongside dedicated recovery
anycast targets:

* `myapp.queue`: The core point-to-point workload queue.
* `myapp.queue.RETRY`: Dedicated holding queue for transaction retry patterns.
* `myapp.queue.DLQ` (*Dead Letter Queue*): Isolation queue for poisoning messages requiring engineering auditing.

---

## 🚀 Deployment Instructions

### Running ActiveMQ Artemis

To deploy the message broker with preconfigured targets:

```bash
docker compose -f docker-compose-activemq.yaml up -d
```

* **Web Management Console:** Open `http://localhost:8161` in your browser.
* **Default Credentials:** Username: `admin` / Password: `admin`.

### Running Apache Kafka with a Visual Management Console

The extension configurations rely on the native Docker Compose `include` block to dynamically pull core services (Zookeeper, Kafka, Schema Registry) before instantiating the UI layout.

#### Option A: Running with AKHQ UI

```bash
docker compose -f docker-compose-kafka-akhq.yaml up -d
```

* **Web Portal:** Navigate to `http://localhost:8080`. This environment is optimized for viewing raw binary content payloads, tracking schema changes, and looking up topic configurations.

#### Option B: Running with Kafka-UI

```bash
docker compose -f docker-compose-kafka-kui.yaml up -d
```

* **Web Portal:** Navigate to `http://localhost:8080`. This dashboard gives real-time runtime views regarding partition assignments and tracking active Consumer Group lags.

---

## 🛠️ Infrastructure Operations

### Verifying Resource and Initialization States

Check the container operational state and port conflicts across active infrastructure components:

```bash
docker ps
```

To review automatic topic creation or to diagnose broker availability barriers:

```bash
docker logs -f myapp_kafka_init
```

### Shutdown and Data Cleanup

To stop your message architecture services without dropping your unread data states:

```bash
docker compose -f <compose-filename>.yaml stop
```

To fully dismantle container runtime environments, drop isolated networks, and completely wipe out all retained message logs, schemas, or diagnostic history (destructive clean slate):

```bash
docker compose -f <compose-filename>.yaml down -v
```

```