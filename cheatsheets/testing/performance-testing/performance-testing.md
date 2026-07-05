# Performance Testing Cheatsheet

> Performance testing helps you understand how a system behaves under real pressure: how fast it is, where it slows down, and how far it can scale. This guide covers the main test types, metrics, tools, and decision points. Tool-specific guides live in `jmeter.md`, `k6.md`, and `gatling.md`.

---

## What Is Performance Testing?

Performance testing measures how a system **behaves under load** — its speed, responsiveness, stability, and scalability — rather than whether it's functionally correct. You simulate virtual users (VUs) hitting your system and observe how it copes.

It answers questions like:
* How many concurrent users can we handle before response times degrade?
* Where is the bottleneck: CPU, DB, memory, network, or a specific endpoint?
* Does the system stay stable over hours or days of sustained traffic?
* What happens at 2× or 10× expected peak?

---

## Why Do It?

* **Protect user experience** — slow apps lose users; latency directly impacts conversion and retention.
* **Find bottlenecks before production** — issues are cheaper to fix in testing than during an outage.
* **Capacity planning** — know how much infrastructure you actually need and when to scale.
* **Validate SLAs/SLOs** — prove the system meets agreed latency and throughput targets.
* **Prevent regressions** — catch performance drops in CI before they ship.
* **Build confidence** — verify the system can handle launch spikes, sales events, or viral traffic.

---

## Types of Performance Tests

| Type              | Goal                                                        | Load pattern                          |
|-------------------|-------------------------------------------------------------|---------------------------------------|
| **Smoke / Shakeout** | Verify the test + system work under minimal load         | 1–few VUs, short                      |
| **Load test**     | Behavior at expected/normal peak                            | Ramp to target, hold                  |
| **Stress test**   | Find the breaking point                                     | Ramp beyond capacity until it fails   |
| **Spike test**    | Reaction to sudden, sharp traffic bursts                    | Instant jump to high load             |
| **Soak / Endurance** | Stability over long duration (leaks, degradation)        | Moderate load, hours/days             |
| **Scalability test** | How performance changes as you add resources/load        | Incremental steps                     |
| **Volume test**   | Behavior with large amounts of data                         | Big datasets                          |

---

## Key Metrics

* **Response time / Latency** — time to serve a request. Report **percentiles** (p90, p95, p99), *not just averages*; averages hide outliers.
* **Throughput** — requests/sec (RPS) or transactions/sec (TPS).
* **Concurrency / VUs** — simultaneous virtual users.
* **Error rate** — % of failed requests (timeouts, 5xx, assertion failures).
* **Saturation** — resource usage (CPU, memory, I/O, DB connections) under load.
* **Time to First Byte (TTFB)** and **tail latency** (p99) — often where pain hides.

> **Tip:** **Percentiles matter most.** A p50 of 100ms with a p99 of 8s means 1 in 100 users has a terrible experience.

---

## Best Practices

* **Define goals first** — set SLOs (e.g. "p95 < 300ms at 500 RPS, error rate < 1%").
* **Test in a production-like environment** — use similar infrastructure, data volume, and network conditions.
* **Isolate variables** — change one thing at a time and keep the environment stable.
* **Model realistic scenarios** — include real user journeys, think-time, ramp-up, and pacing.
* **Warm up** the system (JIT, caches, connection pools) before measuring.
* **Monitor the system under test**, not just the load generator (APM, metrics, DB stats).
* **Automate in CI** with pass/fail thresholds to catch regressions.
* **Avoid making the load generator the bottleneck** — distribute load if needed.

---

## The Tools Landscape

| Tool          | Script language        | Model            | Best for                                            |
|---------------|------------------------|------------------|-----------------------------------------------------|
| **k6**        | JavaScript (ES6)       | Goroutine-based (Go engine) | Developer-friendly, CI/CD, code-as-tests, cloud output |
| **Gatling**   | Scala / Java / Kotlin DSL | Async (Akka)   | High load per machine, expressive DSL, great HTML reports |
| **JMeter**    | GUI + XML (`.jmx`)     | Thread-per-VU    | GUI users, huge protocol/plugin ecosystem, mature   |
| **Locust**    | Python                 | Greenlet-based   | Python shops, code-based scenarios                  |
| **Artillery** | YAML / JavaScript      | Node.js          | Quick YAML tests, serverless/websocket              |
| **wrk / hey / vegeta** | CLI flags     | Lightweight      | Quick micro-benchmarks of a single endpoint         |

### How to choose
* **Want tests as code + CI-first + JS?** → **k6**.
* **Need max load from few machines + rich reports?** → **Gatling**.
* **Prefer a GUI, or need exotic protocols/plugins?** → **JMeter**.
* **Python team?** → **Locust**. **Just hammer one URL quickly?** → `hey`/`wrk`/`vegeta`.

---

## A Typical Workflow

1. **Define SLOs** and the scenario (user journey, target load).
2. **Script** the scenario in your chosen tool.
3. **Smoke test** with 1 VU to validate the script.
4. **Ramp up** to target load; run load, stress, or soak tests as needed.
5. **Observe** metrics on both the load generator and the system under test.
6. **Analyze** percentiles, error rate, and resource saturation to locate bottlenecks.
7. **Fix, re-test, compare** against the baseline.
8. **Automate** in CI with thresholds.

---

## Common Pitfalls

* Reporting **averages** instead of percentiles.
* Testing against a **non-representative environment** or empty database.
* Letting the **load generator saturate** first and skew the results.
* **No think-time/pacing** → unrealistic hammering that no real user produces.
* **Ignoring warm-up** → first requests skew latency.
* Not **monitoring the target system**, so you see symptoms but not causes.
* Running once and trusting it — performance is noisy; repeat and compare.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
