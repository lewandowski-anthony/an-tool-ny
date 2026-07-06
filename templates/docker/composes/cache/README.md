# Distributed Caching and In-Memory Data Sandbox via Docker Compose

This repository provides separate, modular Docker Compose configurations to deploy major high-performance caching platforms, in-memory databases, and distributed data grids. Each setup runs in an isolated network environment and includes administrative management consoles where available, making them ideal for local development, architectural benchmarking, and cache strategy evaluation.

---

## Quick Reference Table

| Caching Technology | Compose File | Host Access Port | Internal Service Port | Management GUI Web URL |
| :--- | :--- | :--- | :--- | :--- |
| **Valkey** (Redis Fork) | `valkey-compose.yaml` | `6379` | `6379` | `http://localhost:8001` (RedisInsight) |
| **Memcached** | `memcached-compose.yaml` | `15442` | `11211` | `http://localhost:15447` (phpMemcachedAdmin) |
| **Hazelcast** | `hazelcast-compose.yaml` | `15443` | `5701` | `http://localhost:15446` (Management Center) |
| **Apache Ignite** | `ignite-compose.yaml` | `15444` | `10800` | N/A (Thin Client Port) |
| **Couchbase** (Community) | `couchbase-compose.yaml` | `15445` | `8091` | `http://localhost:15445` (Web Console) |

---

## Cache Usage Profiles and Architectural Use Cases

Each caching engine in this sandbox has unique features optimized for specific technical requirements. Below is an overview of how and when to leverage each system.

### 1. Valkey (High-Performance Redis Fork)
* **Overview:** Valkey is an open-source, high-performance, in-memory key-value data store created as a fully compatible fork of Redis (v7.2+).
* **Core Caching Use Cases:**
    * **Rich Data Structure Caching:** Ideal when your application requires more than basic string keys. It natively supports Hashes, Lists, Sets, Sorted Sets, Bitmaps, and Geospatial indexes directly in memory.
    * **Pub/Sub Messaging and Rate Limiting:** Often used to handle real-time application messaging queues, state broadcasting, or implementing token-bucket API rate limiters.
    * **Persistent Caching:** Provides optional disk snapshots (RDB) and append-only logs (AOF), ensuring that cached data or sessions survive a sudden container crash or system restart.

### 2. Memcached
* **Overview:** Memcached is a minimalist, highly optimized, multi-threaded memory object caching system designed entirely for speed and simplicity.
* **Core Caching Use Cases:**
    * **Transient Look-aside Caching:** Best suited for pure key-value string caching where data structure manipulation is unnecessary and keys are completely independent.
    * **Database Query Cache Reduction:** Used to store heavy, computed relational database results, pre-rendered HTML snippets, or raw API response payloads to minimize database processor strain.
    * **High-Concurrency Multi-Threading:** Performs exceptionally well under large multi-core architectures because its internal engine is multi-threaded, scaling linearly with available CPU cores.

### 3. Hazelcast
* **Overview:** Hazelcast is an In-Memory Data Grid (IMDG) engineered to distribute application data, calculations, and transactional state horizontally across a cluster of nodes.
* **Core Caching Use Cases:**
    * **Distributed Application State:** Used in microservice clusters to provide thread-safe, distributed data structures like distributed maps, queues, multimaps, and cluster-wide execution locks.
    * **Web Session Replication:** Provides low-latency, transactional session replication across elastic clusters of web application servers to achieve seamless user session failover.
    * **Real-Time Stream Processing:** Acts as an analytical caching layer capable of processing high-velocity data streams and event pipelines directly within the memory grid layer.

### 4. Apache Ignite
* **Overview:** Apache Ignite is a distributed database, caching, and in-memory computing platform capable of scaling out across thousands of high-performance transactional layers.
* **Core Caching Use Cases:**
    * **Distributed ACID Transactional Caching:** Chosen when the caching layer must enforce strict Two-Phase Commit (2PC) ACID guarantees across multiple distributed network nodes.
    * **In-Memory SQL Accelerators:** Provides full ANSI-99 SQL compliance, enabling developers to build secondary indexes and execute complex SQL queries directly against cached memory structures.
    * **Write-Through and Write-Behind Integration:** Acts as an intelligent acceleration layer directly on top of legacy underlying databases (e.g., Oracle, PostgreSQL). It manages automatic read-throughs and batch writes to the underlying data store transparently.

### 5. Couchbase (Community Edition)
* **Overview:** Couchbase is a distributed NoSQL document database that embeds a managed caching layer built directly on Memcached architecture into its underlying data engine.
* **Core Caching Use Cases:**
    * **JSON Document Caching:** Purpose-built for caching structured JSON objects, allowing developers to index and query cached data using a declarative, SQL-like syntax (N1QL).
    * **Memory-First Data Management:** Automatically handles all reads and writes in-memory at sub-millisecond speeds, while asynchronously committing changes to disk persistence layers in the background.
    * **Cross-Datacenter Replication (XDCR):** Used when the caching layer must handle partition tolerances and synchronize documents across multi-region geo-clusters automatically.

---

## Deployment Instructions

Each caching environment is isolated inside its own Docker Compose configuration file. Use the `-f` flag to target and manage a specific database or cache stack.

### Launch Valkey and RedisInsight
```bash
docker compose -f valkey-compose.yaml up -d
```
* Access the **RedisInsight** web administration dashboard at `http://localhost:8001` to view your data keys, monitor execution commands, and optimize performance.

### Launch Memcached and phpMemcachedAdmin
```bash
docker compose -f memcached-compose.yaml up -d
```
* Access the **phpMemcachedAdmin** web UI at `http://localhost:15447` to monitor hit/miss ratios, inspect allocated slabs, and audit live memory usage.

### Launch Hazelcast and Management Center
```bash
docker compose -f hazelcast-compose.yaml up -d
```
* Access the **Hazelcast Management Center** dashboard at `http://localhost:15446`.
* Credentials are preconfigured via environment initialization variables: Username `admin`, Password `ChangeMe123!`.

### Launch Apache Ignite
```bash
docker compose -f ignite-compose.yaml up -d
```
* Connect external client applications, microservices, or thick binary frameworks directly using the thin-client protocol port at `localhost:15444`.

### Launch Couchbase Community
```bash
docker compose -f couchbase-compose.yaml up -d
```
* Open the **Couchbase Web Console** administrative panel at `http://localhost:15445` to perform initial cluster definitions, build data buckets, and configure user security parameters.

---

## Infrastructure Lifecycle and Administrative Management

### Monitor Active Cache Containers
To verify the health, container names, and current port allocations of your operational infrastructure:
```bash
docker ps
```

### Safely Stopping an Environment
To pause an active engine without risking data structure loss for engines utilizing persistent state:
```bash
docker compose -f <filename>-compose.yaml stop
```

### Tearing Down Containers and Networks
To completely stop cache container runtimes and clear the associated virtual bridge networks:
```bash
docker compose -f <filename>-compose.yaml down
```

To entirely wipe out persistent data stores kept on your host machine disk (such as Couchbase document shards or Valkey database dumps), append the volume deletion flag:
```bash
docker compose -f <filename>-compose.yaml down -v
```
> **Warning:** Appending `-v` permanently removes all historical caching records, buckets, and persistent configurations.