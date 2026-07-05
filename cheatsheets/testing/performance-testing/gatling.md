# Gatling Cheatsheet

> A practical guide to [Gatling](https://gatling.io/), a high-performance load testing tool built on an async (Akka) engine. Tests, called "simulations," are written as code in a **Scala / Java / Kotlin DSL**. For general concepts, see `performance-testing.md`.

---

## Setup & Run

```bash
# Maven
mvn gatling:test
mvn gatling:test -Dgatling.simulationClass=com.example.MySimulation

# Gradle
./gradlew gatlingRun
./gradlew gatlingRun-com.example.MySimulation

# Standalone bundle
./bin/gatling.sh        # (gatling.bat on Windows) — interactive picker
```

Results: each run generates a **self-contained HTML report** under `target/gatling/` or `results/`.

---

## Minimal Simulation (Java DSL)

```java
import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;
import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

public class BasicSimulation extends Simulation {

  HttpProtocolBuilder httpProtocol = http
    .baseUrl("https://test.gatling.io")
    .acceptHeader("application/json");

  ScenarioBuilder scn = scenario("Basic Load")
    .exec(http("Home").get("/"))
    .pause(1)                               // think-time
    .exec(http("List").get("/computers"));

  {
    setUp(
      scn.injectOpen(rampUsers(100).during(60))
    ).protocols(httpProtocol);
  }
}
```

* **Simulation** = the test class.
* **Scenario** = a user journey (chain of requests).
* **Injection profile** = how virtual users arrive over time.

---

## Injection Profiles

```java
// Open model — control the arrival RATE of new users
scn.injectOpen(
  nothingFor(5),                       // wait
  atOnceUsers(10),                     // 10 users instantly
  rampUsers(100).during(30),           // ramp to 100 over 30s
  constantUsersPerSec(20).during(60),  // 20 new users/sec
  rampUsersPerSec(10).to(50).during(120)
);

// Closed model — control CONCURRENT users (like a fixed pool)
scn.injectClosed(
  constantConcurrentUsers(50).during(60),
  rampConcurrentUsers(10).to(100).during(120)
);
```

> **Tip:** **Open** means you control the *rate of arrivals* for real-world web traffic. **Closed** means you control *concurrency*, which fits call centers or fixed thread pools.

---

## Checks & Assertions

```java
// Checks — validate individual responses
http("Get user").get("/users/1")
  .check(status().is(200))
  .check(jsonPath("$.name").is("Ana"))
  .check(responseTimeInMillis().lte(500))
  .check(jsonPath("$.id").saveAs("userId"));   // capture into session

// Assertions — global pass/fail (great for CI)
setUp(scn.injectOpen(rampUsers(100).during(60)))
  .protocols(httpProtocol)
  .assertions(
    global().responseTime().percentile(95).lt(300),
    global().failedRequests().percent().lt(1.0),
    forAll().responseTime().max().lt(5000)
  );
```
> **Tip:** Failed **assertions** make the build exit non-zero, so they work well as a CI gate.

---

## Sessions, Feeders & Correlation

```java
// Feeder — inject test data (CSV, JSON, arrays)
FeederBuilder<String> feeder = csv("users.csv").random();

ScenarioBuilder scn = scenario("Login flow")
  .feed(feeder)                                    // pulls a row per iteration
  .exec(http("Login")
    .post("/login")
    .formParam("user", "#{username}")              // Gatling EL from feeder
    .formParam("pass", "#{password}")
    .check(jsonPath("$.token").saveAs("token")))   // capture
  .exec(http("Profile")
    .get("/me")
    .header("Authorization", "Bearer #{token}"));  // reuse from session
```
Feeder strategies: `.queue()`, `.random()`, `.shuffle()`, `.circular()`.

---

## Control Flow

```java
.repeat(3).on( exec(http("ping").get("/ping")) )
.during(30).on( exec(...) )                        // loop for a duration
.doIf("#{loggedIn}").then( exec(...) )
.randomSwitch().on(
   percent(70.0).then(exec(http("browse").get("/list"))),
   percent(30.0).then(exec(http("search").get("/search")))
)
.pause(1, 3)                                        // random pause 1–3s
```

---

## HTTP Protocol Config

```java
http
  .baseUrl("https://api.example.com")
  .acceptHeader("application/json")
  .contentTypeHeader("application/json")
  .userAgentHeader("Gatling/perf")
  .shareConnections()          // reuse connections across VUs
  .disableCaching();
```

---

## Ecosystem

* **Gatling Enterprise (formerly FrontLine)** — distributed load, live dashboards, trends, CI integrations.
* DSLs: **Java, Kotlin, Scala** (Scala is the original; Java/Kotlin are first-class since Gatling 3.7+).
* Protocols: HTTP, WebSocket, SSE, JMS, MQTT, gRPC (via modules).
* Integrates with Maven, Gradle, sbt, and CI (Jenkins, GitLab, GitHub Actions).

---

## Notes & Gotchas

* Gatling excels at **high load from a single machine** thanks to its async, non-blocking engine (no thread-per-user).
* Prefer the **open model** for realistic web traffic (rate-based), and the closed model for fixed-concurrency systems.
* Gatling EL uses `#{var}` (older versions used `${var}`) — match your version.
* Checks validate responses; **assertions** are what gate CI, so set both.
* The HTML report is generated post-run; for live or trend dashboards, use Gatling Enterprise or a custom exporter.
* Keep simulation logic lean; heavy per-request Java code can limit the load generator.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
