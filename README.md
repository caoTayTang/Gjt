
# Gjt - A Minimal Backup Utility in Bash

**Gjt** (Git Just There) is a lightweight backup and version control utility written entirely in Bash. Inspired by Git, it allows users to track changes to files using Linux's built-in `diff` and `patch` tools. While it doesn't offer a full commit history or branching, it supports reverting to the **previous** state of a tracked file — perfect for simple, local version tracking needs.

---

## ✨ Features

- 📝 Initialize `gjt init <filename>`
- 📝 Track changes to files via `gjt add <filename>`
- 💾 Save changes using `gjt commit`
- 🔁 View commit history `gjt history`
- 🔁 Revert to the previous committed state with `gjt restore`
-    Compare working files to the last committed version with `gjt status`
-    Schedule commit with cronjob `gjt schedule`
- 🧠 Written in pure Bash, no external dependencies beyond standard Unix tools
---

## 📦 Installation

```bash
git clone https://github.com/caoTayTang/gjt.git
cd gjt
chmod +x ./setup.sh
./setup.sh --install
```

