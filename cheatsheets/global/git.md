# Git Cheatsheet

> A practical collection of Git commands, tips, and recovery tricks for everyday work, from the basics to those "how do I undo this?" moments. Commands are cross-platform (macOS, Windows, Linux); OS-specific
> notes are called out where relevant.

---

## Setup & Configuration

```bash
git config --global user.name "Anthony Lewandowski"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main      # default branch name
git config --global pull.rebase true             # rebase instead of merge on pull
git config --global core.editor "code --wait"    # VS Code as commit editor
git config --global push.autoSetupRemote true    # auto-create upstream on first push
git config --list                                 # show all settings
```

> **Tip:** **Line endings** — avoids the classic cross-OS diff noise:
> * macOS / Linux: `git config --global core.autocrlf input`
> * Windows: `git config --global core.autocrlf true`

---

## The Essentials

| Action                 | Command                                      |
|------------------------|----------------------------------------------|
| Clone a repo           | `git clone <url>`                            |
| Status                 | `git status` / `git status -s`               |
| Stage a file           | `git add <file>`                             |
| Stage everything       | `git add -A`                                 |
| Commit                 | `git commit -m "message"`                    |
| Stage + commit tracked | `git commit -am "message"`                   |
| Push                   | `git push`                                   |
| Pull                   | `git pull`                                   |
| Fetch (no merge)       | `git fetch --all --prune`                    |
| Show history           | `git log --oneline --graph --decorate --all` |

---

## Branching

```bash
git branch                         # list local branches
git branch -a                      # list all (incl. remote)
git switch <branch>                # switch (modern)
git switch -c <branch>             # create + switch
git checkout -b <branch>           # create + switch (classic)
git branch -d <branch>            # delete (safe, merged only)
git branch -D <branch>            # force delete
git branch -m <old> <new>          # rename
git push -u origin <branch>        # push + set upstream
git push origin --delete <branch>  # delete remote branch
```

> **Tip:** Prune stale remote-tracking branches with `git fetch --prune` (or see `scripts/git/git-purge-branches.sh` in this repo to auto-delete merged local branches).

---

## Merging & Rebasing

```bash
git merge <branch>                 # merge branch into current
git merge --no-ff <branch>         # always create a merge commit
git rebase <branch>                # replay current branch onto <branch>
git rebase -i HEAD~3               # interactive: squash/reword/reorder last 3
git rebase --continue              # after resolving conflicts
git rebase --abort                 # bail out
git cherry-pick <commit>           # apply a single commit here
```

### Interactive rebase commands (`git rebase -i`)

| Command  | Effect                                |
|----------|---------------------------------------|
| `pick`   | keep the commit as-is                 |
| `reword` | keep changes, edit the message        |
| `squash` | merge into previous commit (keep msg) |
| `fixup`  | merge into previous commit (drop msg) |
| `drop`   | delete the commit                     |
| `edit`   | pause to amend the commit             |

> **Warning:** **Golden rule**: never rebase or force-push a branch other people are working on (for example, `main`). Rebase only your own unpushed or feature branches.

---

## Stashing

```bash
git stash                          # stash tracked changes
git stash -u                       # include untracked files
git stash push -m "wip: feature"   # named stash
git stash list                     # list stashes
git stash pop                      # apply + drop latest
git stash apply stash@{2}          # apply a specific stash (keep it)
git stash drop stash@{0}           # delete a stash
git stash clear                    # delete all stashes
```

---

## Inspecting

```bash
git log --oneline --graph --all         # visual history
git log -p <file>                        # history with diffs for a file
git log --author="Anthony"               # filter by author
git log --since="2 weeks ago"            # filter by date
git show <commit>                        # details of a commit
git diff                                  # unstaged changes
git diff --staged                        # staged changes
git diff <branchA>..<branchB>             # compare branches
git blame <file>                          # who changed each line
git shortlog -sn                          # commit count per author
```

> **Tip:** Search history for when a string appeared or disappeared with `git log -S "someFunction" --oneline` ("pickaxe").

---

## Undoing Things (the panic section)

| Situation                               | Command                                    |
|-----------------------------------------|--------------------------------------------|
| Unstage a file (keep changes)           | `git restore --staged <file>`              |
| Discard local changes in a file         | `git restore <file>`                       |
| Discard **all** local changes           | `git restore .`                            |
| Amend last commit (message/content)     | `git commit --amend`                       |
| Undo last commit, keep changes staged   | `git reset --soft HEAD~1`                  |
| Undo last commit, keep changes unstaged | `git reset HEAD~1`                         |
| Undo last commit, **discard** changes   | `git reset --hard HEAD~1`                  |
| Revert a commit (safe, new commit)      | `git revert <commit>`                      |
| Recover a "lost" commit/branch          | `git reflog` then `git reset --hard <sha>` |
| Clean untracked files (dry run)         | `git clean -nd`                            |
| Clean untracked files (for real)        | `git clean -fd`                            |

> **Note:** **`git reflog` is your safety net.** Almost nothing is truly lost: reflog records where HEAD has been, so you can `reset --hard` back to any recent state (even after a bad rebase or hard reset).

> **Warning:** `git reset --hard` and `git clean -fd` **permanently delete** work. Double-check before running.

---

## Tags

```bash
git tag                            # list tags
git tag v1.2.0                     # lightweight tag
git tag -a v1.2.0 -m "Release"     # annotated tag
git push origin v1.2.0             # push one tag
git push origin --tags             # push all tags
git tag -d v1.2.0                  # delete local tag
git push origin --delete v1.2.0    # delete remote tag
```

---

## Remotes

```bash
git remote -v                              # list remotes
git remote add origin <url>                # add a remote
git remote set-url origin <url>            # change URL
git remote rename origin upstream          # rename
git fetch upstream                          # fetch a fork's upstream
```

### Sync a fork with upstream

```bash
git remote add upstream <original-repo-url>
git fetch upstream
git switch main
git merge upstream/main        # or: git rebase upstream/main
git push origin main
```

---

## Commit Message Conventions

Use **Conventional Commits** to keep history clear and friendly to tooling:

```
<type>(<scope>): <short summary>

<optional body>

<optional footer>
```

| Type       | Use for…                             |
|------------|--------------------------------------|
| `feat`     | a new feature                        |
| `fix`      | a bug fix                            |
| `docs`     | documentation only                   |
| `refactor` | code change that isn't a fix/feature |
| `perf`     | performance improvement              |
| `test`     | adding/adjusting tests               |
| `chore`    | tooling, deps, config                |
| `ci`       | CI/CD pipeline changes               |

Example: `feat(auth): add refresh-token rotation`

---

## Tips & Tricks

* **Aliases** save keystrokes — add to `~/.gitconfig`:
  ```bash
  git config --global alias.st "status -s"
  git config --global alias.co "checkout"
  git config --global alias.br "branch"
  git config --global alias.lg "log --oneline --graph --decorate --all"
  git config --global alias.last "log -1 HEAD"
  git config --global alias.unstage "restore --staged"
  ```
* **Partial staging**: `git add -p` lets you stage individual hunks — great for splitting a messy working tree into clean commits.
* **Fixup workflow**: `git commit --fixup <sha>` then `git rebase -i --autosquash <base>` auto-arranges fixups into their target commits.
* **`.gitignore` not working?** The file is already tracked. Run `git rm --cached <file>` then commit.
* **Worktrees**: `git worktree add ../hotfix main` gives you a second working directory on another branch — no stashing needed.
* **Bisect** to find the commit that broke something:
  ```bash
  git bisect start
  git bisect bad                 # current is broken
  git bisect good <old-sha>      # known-good commit
  # test, then mark each step good/bad; git converges on the culprit
  git bisect reset
  ```
* **Sign your commits**: `git commit -S` (GPG/SSH) for verified badges on GitHub.
* **Empty commit** (trigger CI, etc.): `git commit --allow-empty -m "ci: retrigger"`.
* **Amend author on last commit**: `git commit --amend --author="Name <email>"`.
* **See what a pull will do first**: `git fetch` then `git log HEAD..origin/main --oneline`.

---

## Cross-Platform Notes

* **Line endings**: configure `core.autocrlf` (see Setup) to avoid whole-file diffs between Windows and macOS/Linux teammates.
* **Case sensitivity**: macOS (default) and Windows filesystems are case-**insensitive**; Linux is case-**sensitive**. Renaming `File.js` → `file.js` may not register — use
  `git mv -f File.js file.js`.
* **File permissions / exec bit**: Windows doesn't track the executable bit. If it causes noisy diffs, set `git config core.fileMode false`.
* **Credentials**: use a credential helper — `osxkeychain` (macOS), `manager` (Windows), or `libsecret`/`cache` (Linux).

---

## Quick Reference: "How Do I…?"

| I want to…                          | Do this                                 |
|-------------------------------------|-----------------------------------------|
| Save work without committing        | `git stash -u`                          |
| See what I'm about to commit        | `git diff --staged`                     |
| Fix my last commit message          | `git commit --amend`                    |
| Undo a public commit safely         | `git revert <sha>`                      |
| Recover after a bad `reset --hard`  | `git reflog` → `git reset --hard <sha>` |
| Grab one commit from another branch | `git cherry-pick <sha>`                 |
| Update my feature branch with main  | `git rebase main`                       |
| Throw away all local changes        | `git reset --hard` + `git clean -fd`    |

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
