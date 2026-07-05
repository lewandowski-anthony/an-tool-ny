# Git Work Configuration (`.gitconfig-work`)

This repository includes a dedicated Git configuration for corporate work. It keeps your work identity separate from personal projects, includes useful daily aliases, and leaves room for common corporate networking settings.

---

## Key Features

* **Isolated Identity**: Keeps your professional name and corporate email limited to your work directories.
* **Smart Aliases**: Adds short daily aliases and `git lg` for a readable, color-coded commit history graph.
* **Safe Syncing**: Fetches and prunes deleted remote branches before pulling latest updates with `git sync`.
* **Corporate Network Ready**: Provides optional placeholders for corporate proxies and SSL verification settings when strict firewalls get in the way.

---

## Setup Guide

### 1. Create the Work Configuration File

Create a file named `.gitconfig-work` in your user home directory (`~`):

```bash
nano ~/.gitconfig-work
```

Copy and paste the entire content of the configuration into this file, then save it.

### 2. Link it conditionally in your Main Git Config

To prevent corporate settings or your work email from leaking into your personal GitHub repositories, use Git's `includeIf` feature.

Open your main global Git configuration file:

```bash
nano ~/.gitconfig
```

Append the following block at the very end of the file:

```ini

# Default Global Profile (Personal / Open Source)

[user]
name = Anthony Lewandowski
email = personal.email@gmail.com

# Conditional Work Profile Inclusion

[includeIf "gitdir:~/Developer/work/"]
path = ~/.gitconfig-work
```

> **Warning:** **CRITICAL STEP**: Replace `~/Developer/work/` with the absolute or tilde path to the folder where you store all your professional repositories. The trailing slash `/` is mandatory for Git to
> match the directory correctly.

---

## Quick Reference & Aliases

Once configured, any repository cloned inside your designated work folder will automatically inherit these productivity aliases:

| Alias          | Command                         | Description                                                                 |
|:---------------|:--------------------------------|:----------------------------------------------------------------------------|
| `git lg`       | `git log --graph --pretty=...`  | Displays a compact, colorful, graphical branch and commit history tree.     |
| `git st`       | `git status -s`                 | Shows a short, clean, non-verbose status of your working directory.         |
| `git co`       | `git checkout`                  | Switches branches or restores working tree files.                           |
| `git cm "msg"` | `git commit -m "msg"`           | Quickly records changes to the repository with a message.                   |
| `git ca`       | `git commit --amend --no-edit`  | Amends the latest commit staging new changes without changing the message.  |
| `git sync`     | `git fetch --prune && git pull` | Safely cleans up deleted remote tracking branches and pulls latest updates. |

---

## Verification

To verify that the conditional inclusion is active, navigate to one of your work project folders and check your active Git email config:

```bash
cd ~/Developer/work/any-corporate-repo
git config user.email
```

It should output your corporate email address (`anthony.lewandowski@entreprise.com`). If you navigate to any folder outside that path, it will fall back to your personal email address.
