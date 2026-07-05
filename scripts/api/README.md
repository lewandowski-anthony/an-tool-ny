# API Utilities

A collection of lightweight, dependency-conscious Bash scripts designed to parse OpenAPI/Swagger specifications (both JSON and YAML) and generate native configuration files for popular API clients:
Bruno, IntelliJ HTTP Client, and Postman.

These tools eliminate the tedious manual work of bootstrapping API requests by organizing endpoints logically based on their OpenAPI tags, handling path parameter syntax conversions, and
pre-populating query parameters and request bodies.

---

## Prerequisites

Before running the scripts, ensure your system has the following command-line tools installed:

* **jq**: Required by all scripts for parsing and manipulating JSON data.
* **yq**: Required only if you plan to process YAML (`.yaml` or `.yml`) OpenAPI specifications.

### Installation Example

On macOS (using Homebrew):

```bash
brew install jq yq
```

On Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install jq
# For yq, follow the official documentation or use snap:
sudo snap install yq
```

---

## Core Features Across All Scripts

* **Format Auto-Detection**: Accepts both JSON and YAML input files automatically.
* **Tag-Based Organization**: Groups generated endpoint files into subdirectories named after their primary OpenAPI tags.
* **Parameter Translation**: Automatically maps OpenAPI path parameters (`{userId}`) to the specific client format (`:userId` or `{{userId}}`).
* **Boilerplate Generation**: Detects methods requiring a request body (`POST`, `PUT`, `PATCH`) and stubs out empty JSON payloads and content headers.

---

## Usage

All scripts share a unified command-line interface.

### Command-Line Arguments

| Short Flag | Long Flag  | Description                                                                                                     |
|:-----------|:-----------|:----------------------------------------------------------------------------------------------------------------|
| `-i`       | `--input`  | **Required.** Path to the OpenAPI/Swagger specification file (JSON or YAML).                                    |
| `-o`       | `--output` | **Optional.** The target directory for generated files. Defaults to a `results` directory in the script's root. |
| `-h`       | `--help`   | Displays usage instructions.                                                                                    |

### Execution Setup

Ensure the scripts have execution privileges before running them:

```bash
chmod +x openapi-to-bruno.sh openapi-to-intellij.sh openapi-to-postman.sh
```

---

## Utility Breakdown

### 1. Bruno Converter (`openapi-to-bruno.sh`)

Generates a fully compatible directory structure for **Bruno**, an open-source, git-friendly API client.

```bash
./openapi-to-bruno.sh -i path/to/openapi.yaml -o ./bruno-collection
```

**Output Structure:**

* Creates a root `bruno.json` defining the collection name.
* Generates a folder per tag.
* Creates individual `.bru` files for each endpoint containing metadata, standard layout rules, query parameters, and a `{{baseUrl}}` variable prefix.

### 2. IntelliJ HTTP Client Converter (`openapi-to-intellij.sh`)

Generates `.http` files compatible with the built-in HTTP client found in **IntelliJ IDEA**, **PyCharm**, **WebStorm**, and other JetBrains IDEs.

```bash
./openapi-to-intellij.sh -i path/to/openapi.json -o ./intellij-requests
```

**Output Structure:**

* Generates a folder per tag.
* Creates independent `.http` files for each request.
* Translates path variables to standard JetBrains syntax: `{{variable}}`.
* Appends inline query parameter placeholders directly to the URL string.

### 3. Postman Converter (`openapi-to-postman.sh`)

Unlike the file-per-endpoint strategy of the previous scripts, this utility outputs a single monolithic JSON file adhering to the official Postman Collection v2.1.0 schema.

```bash
./openapi-to-postman.sh -i path/to/openapi.yaml -o ./postman-output
```

**Output Structure:**

* Outputs a single file named after the API title: `<api_title>.postman_collection.json`.
* Preserves tag groupings natively as multi-level folders inside the Postman workspace UI once imported.

---

## Configuration Variables

The generated requests utilize a `{{baseUrl}}` placeholder variable for the target domain. To execute requests successfully inside your chosen environment, define this variable within your client
application settings.

> **Note:** Endpoint names are derived dynamically from the OpenAPI configuration. The script evaluates the schema fields in the following order of priority: `summary` $\rightarrow$
`operationId` $\rightarrow$ `[METHOD] /path`. Characters that are invalid for file paths are automatically converted to underscores (`_`).