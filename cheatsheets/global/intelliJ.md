# 🧠 IntelliJ IDEA Cheatsheet

> A practical collection of IntelliJ IDEA shortcuts, tips, and tricks to code faster and stop fighting the IDE. Shortcuts are given for **macOS**, **Windows**, and **Linux** (Windows/Linux are usually
> identical).

---

## 📖 How to Read This

| Symbol | Key          |
|--------|--------------|
| ⌘      | Cmd (mac)    |
| ⌥      | Option / Alt |
| ⌃      | Control      |
| ⇧      | Shift        |
| ↩      | Enter        |
| ⇥      | Tab          |

> 💡 On Windows/Linux, `⌘` ≈ `Ctrl` and `⌥` ≈ `Alt` most of the time — but not always. The tables below list every platform explicitly.

---

## 🚀 The Essentials (learn these first)

| Action                               | macOS | Windows / Linux  |
|--------------------------------------|-------|------------------|
| **Search Everything** (double)       | ⇧ ⇧   | Shift Shift      |
| **Find Action** (run any command)    | ⌘ ⇧ A | Ctrl Shift A     |
| **Go to File**                       | ⌘ ⇧ O | Ctrl Shift N     |
| **Go to Class**                      | ⌘ O   | Ctrl N           |
| **Go to Symbol**                     | ⌘ ⌥ O | Ctrl Alt Shift N |
| **Recent Files**                     | ⌘ E   | Ctrl E           |
| **Recent Locations**                 | ⌘ ⇧ E | Ctrl Shift E     |
| **Show Context Actions** (quick-fix) | ⌥ ↩   | Alt Enter        |
| **Settings / Preferences**           | ⌘ ,   | Ctrl Alt S       |

> 🎯 **The 3 shortcuts that matter most:** `Shift Shift` (find anything), `Alt/⌥ Enter` (fix anything), and `⌘/Ctrl Shift A` (do anything). If you only memorize three, memorize these.

---

## ✏️ Editing

| Action                       | macOS      | Windows / Linux       |
|------------------------------|------------|-----------------------|
| Duplicate line / selection   | ⌘ D        | Ctrl D                |
| Delete line                  | ⌘ ⌫        | Ctrl Y                |
| Move line up / down          | ⌥ ⇧ ↑ / ↓  | Alt Shift ↑ / ↓       |
| Move statement up / down     | ⌘ ⇧ ↑ / ↓  | Ctrl Shift ↑ / ↓      |
| Comment line                 | ⌘ /        | Ctrl /                |
| Comment block                | ⌘ ⌥ /      | Ctrl Shift /          |
| Extend / shrink selection    | ⌥ ↑ / ↓    | Ctrl W / Ctrl Shift W |
| Column (multi-cursor) select | ⌥ ⌥ + drag | Alt Alt + drag        |
| Add caret to next occurrence | ⌃ G        | Alt J                 |
| Select all occurrences       | ⌃ ⌘ G      | Ctrl Alt Shift J      |
| Clone caret above / below    | ⌥ ⌥ ↑ / ↓  | Ctrl Ctrl ↑ / ↓       |
| Join lines                   | ⌃ ⇧ J      | Ctrl Shift J          |
| Complete current statement   | ⌘ ⇧ ↩      | Ctrl Shift Enter      |

---

## 🧭 Navigation

| Action                   | macOS         | Windows / Linux      |
|--------------------------|---------------|----------------------|
| Go to declaration        | ⌘ B / ⌘ click | Ctrl B / Ctrl click  |
| Go to implementation     | ⌘ ⌥ B         | Ctrl Alt B           |
| Go to type declaration   | ⌃ ⇧ B         | Ctrl Shift B         |
| Find usages              | ⌥ F7          | Alt F7               |
| Quick definition (peek)  | ⌥ Space       | Ctrl Shift I         |
| Quick documentation      | F1            | Ctrl Q               |
| Back / Forward           | ⌘ [ / ⌘ ]     | Ctrl Alt ← / →       |
| Last edit location       | ⌘ ⇧ ⌫         | Ctrl Shift Backspace |
| Go to line               | ⌘ L           | Ctrl G               |
| File structure (outline) | ⌘ F12         | Ctrl F12             |
| Next / previous method   | ⌃ ↓ / ↑       | Alt ↓ / ↑            |
| Jump to matching brace   | ⌘ ⇧ M         | Ctrl Shift M         |
| Bookmark (toggle)        | F3            | F11                  |
| Show bookmarks           | ⌘ F3          | Shift F11            |

---

## 🔍 Search & Replace

| Action                      | macOS                               | Windows / Linux |
|-----------------------------|-------------------------------------|-----------------|
| Find in file                | ⌘ F                                 | Ctrl F          |
| Replace in file             | ⌘ R                                 | Ctrl R          |
| Find in path (project-wide) | ⌘ ⇧ F                               | Ctrl Shift F    |
| Replace in path             | ⌘ ⇧ R                               | Ctrl Shift R    |
| Find next / previous        | ⌘ G / ⌘ ⇧ G                         | F3 / Shift F3   |
| Search structurally         | Find Action → "Search Structurally" | same            |

> 💡 In Find in Path, toggle **Regex** and use capture groups (`$1`, `$2`) in Replace for powerful refactors.

---

## 🔧 Refactoring

| Action               | macOS | Windows / Linux  |
|----------------------|-------|------------------|
| Rename               | ⇧ F6  | Shift F6         |
| Refactor this (menu) | ⌃ T   | Ctrl Alt Shift T |
| Extract variable     | ⌘ ⌥ V | Ctrl Alt V       |
| Extract method       | ⌘ ⌥ M | Ctrl Alt M       |
| Extract field        | ⌘ ⌥ F | Ctrl Alt F       |
| Extract constant     | ⌘ ⌥ C | Ctrl Alt C       |
| Extract parameter    | ⌘ ⌥ P | Ctrl Alt P       |
| Inline               | ⌘ ⌥ N | Ctrl Alt N       |
| Change signature     | ⌘ F6  | Ctrl F6          |
| Move                 | F6    | F6               |
| Optimize imports     | ⌃ ⌥ O | Ctrl Alt O       |
| Reformat code        | ⌘ ⌥ L | Ctrl Alt L       |
| Auto-indent lines    | ⌃ ⌥ I | Ctrl Alt I       |

---

## 🐞 Run & Debug

| Action               | macOS  | Windows / Linux |
|----------------------|--------|-----------------|
| Run                  | ⌃ R    | Shift F10       |
| Debug                | ⌃ D    | Shift F9        |
| Run… (choose config) | ⌃ ⌥ R  | Alt Shift F10   |
| Toggle breakpoint    | ⌘ F8   | Ctrl F8         |
| Step over            | F8     | F8              |
| Step into            | F7     | F7              |
| Step out             | ⇧ F8   | Shift F8        |
| Resume program       | ⌥ ⌘ R  | F9              |
| Evaluate expression  | ⌥ F8   | Alt F8          |
| View breakpoints     | ⌘ ⇧ F8 | Ctrl Shift F8   |

---

## 🪟 Tool Windows & UI

| Action                             | macOS                                 | Windows / Linux |
|------------------------------------|---------------------------------------|-----------------|
| Project view                       | ⌘ 1                                   | Alt 1           |
| Version Control                    | ⌘ 9                                   | Alt 9           |
| Terminal                           | ⌥ F12                                 | Alt F12         |
| Run window                         | ⌘ 4                                   | Alt 4           |
| Debug window                       | ⌘ 5                                   | Alt 5           |
| Problems                           | ⌘ 6                                   | Alt 6           |
| Hide all tool windows              | ⌘ ⇧ F12                               | Ctrl Shift F12  |
| Maximize editor / distraction-free | Find Action → "Distraction Free Mode" | same            |
| Split editor vertically            | Right-click tab → Split Right         | same            |
| Switcher (open tabs/panels)        | ⌃ ⇥                                   | Ctrl Tab        |

---

## 🌱 Version Control (Git)

| Action                     | macOS                            | Windows / Linux |
|----------------------------|----------------------------------|-----------------|
| Commit                     | ⌘ K                              | Ctrl K          |
| Push                       | ⌘ ⇧ K                            | Ctrl Shift K    |
| Update project (pull)      | ⌘ T                              | Ctrl T          |
| VCS operations popup       | ⌃ V                              | Alt \`          |
| Show diff                  | ⌘ D (in VCS)                     | Ctrl D          |
| Annotate / blame           | Right-click gutter → Annotate    | same            |
| Rollback local changes     | ⌘ ⌥ Z                            | Ctrl Alt Z      |
| Show history for selection | Right-click → Git → Show History | same            |

> 💡 The **Local History** feature (`Right-click → Local History → Show History`) saves you even when you never committed — IntelliJ tracks changes independently of Git.

---

## 💡 Tips & Tricks

* **Postfix completion**: type `something.` then `.for`, `.if`, `.null`, `.nn`, `.var`, `.sout` → expands into the full construct. E.g. `list.for↩` builds a for-loop.
* **Live templates**: `psvm`↩ → `main` method, `sout`↩ → print, `fori`↩ → indexed loop. Manage them in *Settings → Editor → Live Templates*.
* **Smart completion**: `⌃ ⇧ Space` (mac) / `Ctrl Shift Space` filters completion to type-compatible suggestions only.
* **Type-then-complete**: just start typing a class name in a new file and hit ↩ — IntelliJ adds the import automatically.
* **Paste history**: `⌘ ⇧ V` / `Ctrl Shift V` opens the clipboard stack.
* **Multiple cursors fast**: select a word, then `⌃ G` (mac) / `Alt J` to add the next match; `⌃ ⌘ G` / `Ctrl Alt Shift J` selects all.
* **Run anything**: press `⌃ ⌃` / `Ctrl Ctrl` to run configs, Gradle/Maven tasks, or even shell commands.
* **Scratch files**: `⌘ ⇧ N` / `Ctrl Alt Shift Insert` creates a throwaway file (JSON, SQL, HTTP, Markdown…) for quick experiments.
* **HTTP client**: create a `.http` scratch file to fire REST requests directly from the editor.
* **Database tools**: use the built-in Database tool window; when running SQL scripts against a datasource, prefer **"Run SQL Script…"** on the datasource rather than an open editor tab, since
  IntelliJ caches the editor buffer.
* **Bookmarks with mnemonics**: `⌥ F3` (mac) / `Ctrl F11` assigns a digit/letter you can jump back to instantly.
* **Frozen UI?** Use *Find Action → "Invalidate Caches / Restart"* to fix weird indexing or stale-state issues.
* **Presentation Assistant**: enable it (plugin) to display the shortcut you just pressed on screen — great for learning muscle memory.

---

## ⚙️ Keymap Notes

* Change or discover any shortcut in *Settings → Keymap* (search by action name or by pressing the shortcut).
* On **Linux**, some IDE shortcuts collide with the OS/window manager (e.g. `⌘/Super`-based, or `Alt F7`). Remap either the IDE or the desktop environment if a shortcut does nothing.
* Prefer a familiar keymap? IntelliJ ships presets: *Settings → Keymap → dropdown* (VS Code, Eclipse, Emacs, Sublime, Vim via the **IdeaVim** plugin).
* macOS users: enable *"Use ⌥ as Meta"* in terminal settings if you rely on Alt-based editor shortcuts.

---

## 📚 Further Reading

* Official keymap PDFs: *Help → Keymap Reference* inside the IDE (exports the exact map for your OS).
* Tip of the Day: *Help → Tip of the Day* — genuinely useful, not just filler.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
