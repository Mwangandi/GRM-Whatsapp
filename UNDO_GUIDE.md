# Git Undo Cheat Sheet

## Quick Answer: Remove Something You Committed (But Haven't Pushed)

### ✅ Best Solution: Undo & Re-commit
```bash
# Undo last commit, changes go back to staging area
./git.sh reset soft 1

# Remove the unwanted file
./git.sh unstage unwanted-file.js

# Re-commit without that file
./git.sh commit "Fixed commit"

# Now push
./git.sh push
```

---

## All Undo Scenarios

### 1️⃣ Remove a File from Last Commit

**Quick way:**
```bash
./git.sh remove-file src/wrong-file.js
# File removed from commit, still in your directory
# Ready to commit again
```

**Detailed way:**
```bash
./git.sh reset soft 1           # Undo last commit
./git.sh unstage src/wrong-file.js  # Unstage the file
./git.sh commit "Fixed"         # Re-commit
./git.sh push                   # Push
```

---

### 2️⃣ Fix Commit Message

**Wrong message? Fix it:**
```bash
./git.sh amend "Correct message here"
./git.sh push
```

**Don't change message, just add more changes:**
```bash
git add more-files.js
./git.sh amend
```

---

### 3️⃣ Undo Last 1 Commit (Keep Changes)

**Option A: Keep changes staged (ready to commit again)**
```bash
./git.sh reset soft 1
./git.sh commit "New message"
./git.sh push
```

**Option B: Keep changes unstaged (in your editor)**
```bash
./git.sh reset mixed 1
# Changes are now unstaged, review them
./git.sh status
./git.sh add selective-files.js
./git.sh commit "Fixed"
./git.sh push
```

---

### 4️⃣ Undo Multiple Commits

**Keep changes (safest):**
```bash
# Undo last 3 commits
./git.sh reset mixed 3

# Review what changed
./git.sh status

# Recommit properly
./git.sh acp . "Fixed all three"
```

---

### 5️⃣ Delete Commit Completely (⚠️ DESTRUCTIVE!)

**Discard last commit AND all changes:**
```bash
# This asks for confirmation!
./git.sh reset hard 1

# Or discard last 3 commits
./git.sh reset hard 3
```

**WARNING**: This is irreversible! Only use if you're sure.

---

## Decision Tree

```
Did you commit something wrong?
│
├─→ Is the file/content wrong?
│   └─→ ./git.sh remove-file src/wrong-file.js
│
├─→ Is the message wrong?
│   └─→ ./git.sh amend "Correct message"
│
├─→ Did you commit too much?
│   └─→ ./git.sh reset soft 1
│       ./git.sh unstage unwanted-files.js
│       ./git.sh commit "Fixed"
│
├─→ Multiple commits wrong?
│   └─→ ./git.sh reset mixed 3
│       ./git.sh acp . "Fixed"
│
└─→ Delete everything? (no recovery!)
    └─→ ./git.sh reset hard 1
```

---

## Before vs After

### BEFORE (Committed & Staged to Push)
```
Commit 3: "Add feature" ← YOU ARE HERE
Commit 2: "Fix bug"
Commit 1: "Init"
```

### AFTER (Using `reset soft 1`)
```
Commit 2: "Fix bug"
Changes from Commit 3: STAGED (ready to commit again)
```

### AFTER (Using `reset mixed 1`)
```
Commit 2: "Fix bug"
Changes from Commit 3: UNSTAGED (in working directory)
```

---

## The 3 Reset Modes Explained

| Mode | What Happens | When to Use |
|------|-------------|-----------|
| **soft** | Undo commit, changes go to staging area | Want to re-commit with different message |
| **mixed** | Undo commit, changes in working directory | Want to pick & choose what to commit |
| **hard** | Undo commit AND delete all changes | Commit was completely wrong |

---

## Common Mistakes & Fixes

### ❌ "I committed the wrong file!"
```bash
./git.sh remove-file wrong-file.js
./git.sh push
```

### ❌ "Typo in commit message"
```bash
./git.sh amend "Correct message"
./git.sh push
```

### ❌ "Committed too much stuff"
```bash
./git.sh reset soft 1
./git.sh unstage stuff-i-didnt-want.js
./git.sh commit "Only the right stuff"
./git.sh push
```

### ❌ "Committed debug code I wanted to remove"
```bash
# Remove it from the commit
./git.sh remove-file debug-code.js

# Clean it up
rm debug-code.js

# Re-commit
./git.sh commit "Removed debug"
./git.sh push
```

### ❌ "I want to completely discard the last commit"
```bash
./git.sh reset hard 1  # Requires confirmation
```

---

## IMPORTANT: Works ONLY Before Pushing!

These commands work when you've committed but **HAVEN'T PUSHED YET**.

Once you push to the server:
- ❌ Don't use these commands
- ✅ Use `git revert` instead (creates a new commit that undoes the old one)
- ✅ Tell your team before making changes

---

## Recovery (If Something Goes Wrong)

### "What if I did `reset hard` by accident?"
```bash
# Git keeps a log of everything
git reflog

# Find the commit you want
git reset --hard abc123def
```

### "Can I undo a undo?"
```bash
git reflog
git reset --hard <SHA-of-previous-state>
```

---

## Pro Tips

✅ Always check status before pushing:
```bash
./git.sh status
./git.sh log 3
```

✅ Use `reset soft` by default (safest):
```bash
./git.sh reset soft 1
```

✅ Only use `hard` when you're 100% sure:
```bash
./git.sh reset hard 1  # Asks for confirmation
```

✅ Commit often, push regularly:
This way if something goes wrong, you've only lost a little bit of work.

---

## Reference Card

```bash
# Remove file from staging BEFORE commit
./git.sh unstage src/file.js

# Undo commit, keep changes staged
./git.sh reset soft 1

# Undo commit, keep changes unstaged
./git.sh reset mixed 1

# Remove specific file from last commit
./git.sh remove-file src/file.js

# Fix commit message
./git.sh amend "New message"

# Discard last commit completely
./git.sh reset hard 1

# View what commits are available
./git.sh log 10
```
