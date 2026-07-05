# OpenAPI Performance Testing Toolkit

This specialized extension of the toolkit introduces comprehensive performance, load, and stress testing automation. It provides scripts to parse OpenAPI/Swagger specifications (JSON or YAML) and automatically bootstrap functional performance project architectures for three leading industry frameworks: Apache JMeter, Gatling, and Grafana k6.

---

## Technical Architecture Overview

The scripts utilize Node.js package execution layers to handle schema conversion, followed by inline file manipulation to inject dynamic configuration parameters. This converts static API snapshots into ready-to-execute load testing suites that accept dynamic runtime values.

### Framework Matrix

| Script | Engine / Generator | Target Platform | Core Deliverables |
| :--- | :--- | :--- | :--- |
| `generate-gatling-from-swagger.sh` | `@openapitools/openapi-generator-cli` | Gatling (Scala) | Complete Maven-backed Gatling simulation project |
| `generate-jmeter-from-swagger.sh` | `@openapitools/openapi-generator-cli` | Apache JMeter | Parameterized `.jmx` Test Plan XML |
| `generate-k6-from-swagger.sh` | `@grafana/openapi-to-k6` | Grafana k6 (TypeScript) | Tag-grouped client modules with a consolidated `main.ts` orchestration layer |

---

## Prerequisites

Ensure the following runtimes and execution command-line boundaries are available on the host machine:

* **Bash Environment**: Optimized for standard Unix/Linux shells or macOS terminals.
* **Node.js & npx**: Required across all three scripts to run the containerized ecosystem generators via `npx`.
* **Sed Toolchain**: Standard utility used for stream editing during properties injection.
* **Java Runtime Environment (JRE)**: Necessary for final execution of the generated Gatling and JMeter suites.

---

## Script Breakdown & Command Reference

All scripts accept standardized flags for setting input schemas and target outputs. If the output parameter is omitted, files default to a `results` directory within the script's root execution space.

### 1. Gatling Test Suite Generator (`generate-gatling-from-swagger.sh`)

This script orchestrates the generation of a production-ready Scala-based Gatling performance workspace.

* **Automation Mechanism**: Instructs the OpenAPITools engine to compile the target specification into a `scala-gatling` module blueprint.
* **Dynamic Property Overrides**: It programmatically scans the target workspace for the generated `*Simulation.scala` script. It intercepts the default static single-user baseline (`atOnceUsers(1)`) and swaps it out with an optimized dynamic user ramp configuration block:
  $$\text{rampUsers}(\text{vusers}).\text{during}(\text{duration})$$
  This leverages fallback defaults ($\text{vusers} = 5$, $\text{duration} = 10\text{ seconds}$) if no environmental properties are declared at execution time.

#### Execution Syntax
```bash
./generate-gatling-from-swagger.sh --swagger ./path/to/api-spec.yaml -o ./gatling-suite
```

#### Running the Generated Tests
Navigate into the generated target directory and execute using the Apache Maven wrapper properties:
```bash
cd ./gatling-suite
mvn gatling:test -Dvusers=20 -Dduration=60
```

### 2. JMeter Test Plan Generator (`generate-jmeter-from-swagger.sh`)

This utility builds an XML-based test configuration plan ready to open in the JMeter GUI or run headlessly inside continuous integration (CI) environments.

* **Automation Mechanism**: Provisions standard endpoints via the OpenAPITools `jmeter` archetype.
* **Dynamic Property Overrides**: Uses targeted stream replacements to configure properties within the underlying XML tree:
    * Modifies `ThreadGroup.num_threads` from a static 1 to the dynamic JMeter property context `${__P(vusers,5)}`.
    * Sets `ThreadGroup.scheduler` explicitly to `true` to enable time-boxed configurations.
    * Maps `ThreadGroup.duration` to resolve dynamically via `${__P(duration,10)}`.

#### Execution Syntax
```bash
./generate-jmeter-from-swagger.sh --swagger ./path/to/api-spec.json -o ./jmeter-suite
```

#### Running the Generated Tests
Run the output plan file headlessly using the CLI execution flags, passing your custom load configurations via the `-J` prefix:
```bash
jmeter -n -t ./jmeter-suite/Apis.jmx -l ./jmeter-suite/results.jtl -j ./jmeter-suite/jmeter.log -Jvusers=20 -Jduration=60
```

### 3. Grafana k6 Script Generator (`generate-k6-from-swagger.sh`)

This utility utilizes the Grafana conversion engine to establish modern JavaScript/TypeScript testing structures.

* **Automation Mechanism**: Invokes `@grafana/openapi-to-k6` with tag-mode flag parameters to separate endpoints cleanly into individual functional TypeScript file components.
* **Dynamic Property Overrides**: Automatically builds a centralized `main.ts` runner. It parses all generated API sub-modules, writes clean `import` blocks, instantiates the underlying client objects, and builds a comprehensive execution template.
* **Service Level Objectives**: Employs baseline options defining standard virtual user parameters ($\text{vus} = 5$, $\text{duration} = 10\text{s}$) alongside strict verification thresholds:
    * $\text{http\_req\_failed} < 0.02$ (Error rate strictly below $2\%$).
    * $\text{http\_req\_duration} < 1000$ (The $95\text{-th}$ percentile response duration must stay under $1000\text{ ms}$).

#### Execution Syntax
```bash
./generate-k6-from-swagger.sh --swagger ./path/to/api-spec.yaml -o ./k6-suite
```

#### Running the Generated Tests
Execute the compiled typescript test profile directly using the k6 runtime toolchain:
```bash
k6 run ./k6-suite/main.ts
```

---

## Error Avoidance and Guardrails

* **Shell Protections**: The Gatling and JMeter scripts are compiled with strict shell behaviors (`set -euo pipefail`). This means the script execution halts instantly if any command fails or if a command references an unassigned environment variable, shielding directory files from malformed state adjustments.
* **Output Isolation**: Always make sure your destination paths are separate from core source code directories, as the target code generators recreate structure trees from scratch within the given output destination directories.