# Terraform Architecture & Lifecycle Cheatsheet

This cheatsheet covers essential Terraform concepts, workflow commands, state management lifecycle, directory structures, and enterprise best practices.

---

## 1. Core Architecture & Concepts

Terraform uses a declarative approach to manage Infrastructure as Code (IaC). It reads your configuration files to build a dependency graph and safely provisions the defined infrastructure.

### The Dependency Graph
Terraform automatically builds a directed acyclic graph (DAG) of all resources defined in your configuration. It analyzes resource dependencies (e.g., a subnet requiring a VPC ID) to determine the exact order in which resources must be created, updated, or destroyed. This allows non-dependent resources to be processed in parallel, drastically reducing execution time.

### Provider Architecture
Terraform relies on an extensible plugin-based architecture. The core binary does not know how to interact with specific cloud providers. Instead, it talks to **Providers** via RPC (Remote Procedure Call).

* **Terraform Core:** Manages the lifecycle, state file, configuration parsing, and dependency graph generation.
* **Providers:** Implements the actual API calls to downstream platforms (AWS, GCP, Azure, Kubernetes, Cloudflare).

### State File Lifecycle
The state file (`terraform.tfstate`) serves as a single source of truth. It records the mapping between your configuration declarations and the real-world resource IDs returned by infrastructure APIs.

```
+------------------------+
|  Your Config (.tf)     |
+-----------+------------+
            |
            | Generates desired state
            v
+------------------------+       Refreshes status      +------------------------+
|    Terraform Core      |<--------------------------->|   Real Infrastructure  |
+-----------+------------+                             +------------------------+
            |
            | Persists actual mapping
            v
+------------------------+
|   State File (.tfstate)|
+------------------------+
```

---

## 2. Command Lifecycle Reference

| Command | Deep-Dive Mechanics & Behavior | Common Flags |
| :--- | :--- | :--- |
| `terraform init` | Initializes the working directory. Downloads provider plugins, configures backends, and updates child modules. Safe to run multiple times. | `-backend-config=path/to/backend.tfvars`<br>`-upgrade` |
| `terraform validate` | Checks configuration files for syntax correctness, internal consistency, and invalid attribute arguments. Does not call remote APIs. | None |
| `terraform plan` | Performs a speculative execution. It refreshes state against live infra, evaluates variables, analyzes dependencies via the graph, and outputs a delta action plan (Create, Update, Destroy). | `-out=tfplan`<br>`-refresh-only`<br>`-var-file="secrets.tfvars"` |
| `terraform apply` | Executes the actions proposed in the plan. By default, it runs a new implicit plan before execution unless a pre-computed plan file is passed. | `tfplan` (highly recommended)<br>`-auto-approve`<br>`-parallelism=n` |
| `terraform destroy` | Proposes and executes a plan to safely tear down all managed infrastructure defined within the state boundary. | `-auto-approve` |
| `terraform refresh` | **Deprecated** (Use `plan -refresh-only`). Reads the current real-world status of infrastructure and updates the state file to reconcile drift. | None |

---

## 3. State Management Commands

Directly modifying the JSON state file manually can corrupt data. Use these built-in management commands to manipulate state safely:

### Resource Moving & Renaming
If you rename a resource identifier in your `.tf` files, Terraform will default to destroying the old resource and creating a new one. To prevent this, inform Terraform that the resource has moved:
```bash
terraform state mv aws_instance.old_name aws_instance.new_name
```

### Importing Existing Infrastructure
To bring resources created outside of Terraform (via cloud console or CLI) under Terraform management, use the `import` block (recommended in modern versions) or CLI command:
```bash
terraform state import aws_subnet.public_subnet_1 subnet-0123456789abcdef0
```

### Removing Managed Resources From State
If you want to stop managing a resource without destroying it in the real cloud:
```bash
terraform state rm aws_iam_user.orphan_user
```

---

## 4. Standard Directory & Module Structure

Adhering to a predictable file layout separates concerns, improves readability, and maximizes code reuse across multiple environments.

### Root Module Configuration
```text
.
├── backend.tf          # Configures remote state storage and locking mechanisms
├── providers.tf        # Explicit provider requirements and version constraints
├── main.tf             # Primary orchestration layer and resource definitions
├── variables.tf        # Input variable declarations with types and descriptions
├── outputs.tf          # Exposes resource attributes to outputs or other modules
├── terraform.tfvars    # Environment-specific values (unencrypted, gitignored)
└── modules/            # Local encapsulated resource blueprints
    └── compute_cluster/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 5. Enterprise Best Practices

### Remote State Storage & State Locking
* **Never commit state files to version control.** They contain unencrypted secrets, certificates, and access tokens.
* **Enforce Remote Backends:** Store state in a durable object store (AWS S3, Google Cloud Storage, Azure Blob) with versioning enabled.
* **Implement Distributed State Locking:** Use a distributed lock database (like AWS DynamoDB) or native backend capabilities to prevent concurrent execution runs from corrupting the state file.

```hcl
# Example secure backend configuration
terraform {
  backend "s3" {
    bucket         = "production-terraform-state-bucket"
    key            = "compute/infrastructure.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### Variables and Secrets Safeguards
* **Strict Typing:** Always assign `type` constraints and clear `description` metadata to input variables.
* **Sensitive Flag:** Mask secret outputs and inputs within logs by appending the `sensitive = true` attribute.
* **Variable Priority Order:** Terraform evaluates variables from lowest to highest priority as follows:
    1. Environment variables (`TF_VAR_variable_name`)
    2. The `terraform.tfvars` file
    3. The `terraform.tfvars.json` file
    4. Any `*.auto.tfvars` or `*.auto.tfvars.json` files
    5. Command-line flags (`-var` and `-var-file`)

### Resource Safeguards & Lifecycle Meta-Arguments
Utilize resource lifecycle rules to protect business-critical infrastructure from accidental termination during deployments:

```hcl
resource "aws_db_instance" "production_database" {
  # ... configuration attributes ...

  lifecycle {
    # Prevents terraform destroy from executing on this resource
    prevent_destroy = true

    # Creates a replacement instance before destroying the old one to avoid downtime
    create_before_destroy = true

    # Ignores external changes to specific attributes (e.g., autoscaling adjustments)
    ignore_changes = [
      allocated_storage,
      tags["LastModifiedBy"]
    ]
  }
}
```