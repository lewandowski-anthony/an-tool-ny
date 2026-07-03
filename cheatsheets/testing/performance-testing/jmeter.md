# JMeter Cheatsheet

> A practical guide to [Apache JMeter](https://jmeter.apache.org/), a mature GUI-driven load testing tool with a huge plugin ecosystem. Test plans are `.jmx` (XML) files. For general concepts, see `performance-testing.md`.

---

## Install & Run

```bash
brew install jmeter                       # macOS

# GUI mode (design/debug ONLY — never for real load)
jmeter

# Non-GUI / CLI mode (use this for actual load tests)
jmeter -n -t test.jmx -l results.jtl
jmeter -n -t test.jmx -l results.jtl -e -o ./report   # + HTML dashboard
jmeter -n -t test.jmx -Jusers=100 -Jrampup=60         # pass properties
```

> **Warning:** **Always run load tests in non-GUI mode** (`-n`). The GUI consumes huge resources and skews results, so use it only to build or debug the plan.

---

## Test Plan Structure

A JMeter test plan is a tree of elements:

```
Test Plan
└── Thread Group            (the virtual users)
    ├── HTTP Request Defaults    (base URL, shared config)
    ├── HTTP Header Manager      (headers, auth)
    ├── HTTP Request             (a sampler = one request)
    │   └── Response Assertion   (pass/fail check)
    ├── CSV Data Set Config      (test data feeder)
    ├── Timer                    (think-time / pacing)
    └── Listener                 (collect/report results)
```

---

## Thread Group (load model)

Key settings on a Thread Group:
* **Number of Threads (users)** — concurrent virtual users.
* **Ramp-up period (s)** — time to start all threads (100 users / 100s = 1 user/s).
* **Loop count** — iterations per thread, or "infinite" with a duration.
* **Duration / Scheduler** — run for a fixed time.

> **Tip:** For advanced profiles (spikes, steps, arrival rate), use plugins: **Ultimate Thread Group**, **Concurrency Thread Group**, **Throughput Shaping Timer**.

---

## Common Elements

| Element                      | Purpose                                         |
|------------------------------|-------------------------------------------------|
| **HTTP Request**             | The sampler — sends a request                   |
| **HTTP Request Defaults**    | Shared server/base path for all requests        |
| **HTTP Header Manager**      | Headers (Content-Type, Authorization…)          |
| **HTTP Cookie Manager**      | Session cookies                                 |
| **CSV Data Set Config**      | Feed data from CSV (parameterization)           |
| **Response Assertion**       | Validate status/body → pass/fail                |
| **Timer**                    | Add think-time / pacing                         |
| **Listener**                 | Collect results (see below)                     |
| **Logic Controllers**        | If/Loop/Transaction/Once-Only flow control      |

---

## Variables & Correlation

```
# Reference a variable / property / function
${username}                 # variable (e.g. from CSV)
${__P(users,10)}            # property from -J (default 10)
${__Random(1,100)}          # random number
${__UUID}                   # random UUID
${__time(yyyy-MM-dd)}       # timestamp
```

### Extract from a response (correlation)
* **JSON Extractor** → `$.token` into `${token}`.
* **Regular Expression Extractor** → capture with a regex group.
* **Boundary Extractor** → capture text between left/right boundaries.

Then reuse it: `Authorization: Bearer ${token}`.

---

## Assertions

* **Response Assertion** — check response code (`200`), contains text, matches pattern.
* **Duration Assertion** — fail if response took longer than N ms.
* **JSON Assertion** — validate a JSON path value.
* **Size Assertion** — check response size.

---

## Timers (think-time & pacing)

* **Constant Timer** — fixed delay.
* **Uniform Random Timer** — random delay in a range.
* **Gaussian Random Timer** — bell-curve delay.
* **Constant Throughput Timer** / **Throughput Shaping Timer** — target a request rate.

---

## Listeners & Reporting

* Design/debug: **View Results Tree** (per-request detail — heavy, GUI only).
* **Summary Report** / **Aggregate Report** — throughput, avg, percentiles, error %.
* **CLI:** write raw results to `.jtl`, then generate the HTML dashboard:
  ```bash
  jmeter -n -t test.jmx -l results.jtl -e -o ./report
  # or from an existing jtl:
  jmeter -g results.jtl -o ./report
  ```

> **Warning:** Disable or remove heavy listeners (View Results Tree, graphs) during real load runs; they consume memory and distort numbers.

---

## Ecosystem

* **JMeter Plugins Manager** — install community plugins (Ultimate/Concurrency Thread Groups, Throughput Shaping Timer, custom graphs, Dummy Sampler…).
* Protocols: HTTP(S), JDBC (databases), JMS, FTP, SMTP, TCP, LDAP, gRPC (plugin), WebSocket (plugin).
* **Distributed testing**: a controller drives multiple remote "server" (slave) JMeter nodes for higher load.
* CI: run headless in Jenkins/GitLab; the **Performance Plugin** trends results.
* Record scenarios with the **HTTP(S) Test Script Recorder** (browser proxy).

---

## Notes & Gotchas

* **GUI ≠ load runner.** Design in the GUI, then run with `-n` on the CLI.
* The thread-per-VU model is heavier than k6 or Gatling, so you may need more RAM, more machines, or distributed mode for very high load.
* Tune the JVM heap (`HEAP="-Xms1g -Xmx4g"`) for large tests.
* Heavy listeners are the #1 cause of skewed or limited results; strip them for real runs.
* `.jmx` is XML → diffs are noisy, but you should still keep it in version control.
* Correlate dynamic tokens (CSRF, session IDs) or requests will fail under load.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
