# Git Maintenance Utilities

This repository contains a collection of Bash scripts designed to automate and streamline daily Git repository maintenance. These tools help safeguard unpushed work by packaging it into portable Git bundles and securely clean up local branches that have already been merged into your main workflow.

---

## Scripts Overview

### 1. Backup Unpushed Commits (`git-backup-unpushed.sh`)
This script identifies all local branches that either contain unpushed commits relative to their upstream tracking branch or exist purely locally with no upstream configured. It packages these branches into a single, highly portable `.bundle` file.

* **Safety First:** Ensures you can safely clean up or reset your local workspace without losing work that has not yet reached the remote server.
* **Automatic Detection:** Evaluates all local branches against their tracking branches (`@{u}`).
* **Bundled Output:** Uses native `git bundle` execution to generate a self-contained backup file.

### 2. Purge Merged Branches (`git-purge-branches.sh`)
This script automates repository housekeeping by removing local branches that have already been integrated into your central codebase.

* **Remote Synchronization:** Runs a remote fetch and prunes stale remote-tracking references before checking local branches.
* **Dynamic Main Branch Detection:** Queries the remote repository to determine the primary branch (e.g., `main` or `master`).
* **Protected Branches:** Explicitly protects critical tracking branches (`main`, `master`, and `develop`) from accidental deletion.
* **Safe Deletion:** Employs `git branch -d` to ensure only fully merged branches are removed.

---

## Prerequisites

* A Unix-like environment (Linux, macOS, or WSL on Windows).
* `bash` shell (version 4.0 or higher recommended).
* `git` installed and configured in your system path.

---

## Installation and Setup

1. Clone or copy the scripts to a directory of your choice.
2. Make the scripts executable by running the following command in your terminal:

```bash
chmod +x git-backup-unpushed.sh git-purge-branches.sh
```

---

## Usage Guide

### Git Backup Unpushed

By default, the script target defaults to the current working directory, and outputs backups into a `results` directory relative to the script location.

```bash
./git-backup-unpushed.sh [--repo /path/to/repo] [--dest /path/to/backup/dir]
```

#### Arguments
* `--repo`: (Optional) The absolute or relative path to the target Git repository. Defaults to the current working directory.
* `--dest`: (Optional) The directory where the resulting `.bundle` file will be stored. Defaults to `./results`.

#### Example
```bash
./git-backup-unpushed.sh --repo ~/projects/my-app --dest ~/backups/git
```

---

### Git Purge Branches

The purge script can be executed directly inside a Git repository or pointed to one using an optional positional argument.

```bash
./git-purge-branches.sh [/path/to/repo]
```

#### Arguments
* `1`: (Optional) The first positional argument specifies the path to the target Git repository. If omitted, the script executes within the current working directory.

#### Example
```bash
./git-purge-branches.sh ~/projects/my-app
```

---

## Technical Details

### Git Bundle Recovery
The backup script outputs a standard `.bundle` file. If you ever need to recover a branch from this backup, you can treat the bundle file exactly like a remote repository URL.

To inspect the contents of a bundle:
```bash
git bundle verify /path/to/backup_file.bundle
```

To clone or fetch a specific branch directly from the bundle:
```bash
git fetch /path/to/backup_file.bundle branch_name:local_branch_name
```