# Git Operations Quick Reference

## Basic Commands

### Check Status
```bash
./git.sh status
```
Shows modified, staged, and untracked files.

### Add Files
```bash
# Add all files
./git.sh add

# Add specific file
./git.sh add src/index.js

# Add directory
./git.sh add src/
```

### Commit
```bash
./git.sh commit "Your commit message"
```
Commits all staged changes with the provided message.

### Push
```bash
# Push to main branch (default)
./git.sh push

# Push to specific branch
./git.sh push develop

# Push to different remote
./git.sh push main upstream
```

### Pull
```bash
# Pull from main branch (default)
./git.sh pull

# Pull from specific branch
./git.sh pull develop

# Pull from different remote
./git.sh pull main upstream
```

---

## Combined Operations (Faster Workflow)

### Add + Commit (ac)
```bash
# All files
./git.sh ac . "Fix bug"

# Specific file
./git.sh ac src/index.js "Add feature"
```

### Add + Commit + Push (acp) ⭐ MOST USEFUL
```bash
# Default (all files, main branch, origin remote)
./git.sh acp . "Update"

# All files to develop
./git.sh acp . "Add feature" develop

# Specific file
./git.sh acp src/index.js "Fix bug" main origin
```

---

## View History

### View Recent Commits
```bash
# Last 10 commits (default)
./git.sh log

# Last 20 commits
./git.sh log 20

# Last 50 commits
./git.sh log 50
```

---

## Utilities

### View Git Configuration
```bash
./git.sh config
```
Shows user name, email, remote URL, and current branch.

### Stash Changes
```bash
./git.sh stash
```
Temporarily save uncommitted changes. Use `git stash pop` to restore.

---

## Undo/Fix Commands (Before Pushing!)

### Remove File from Staging (Before Commit)
```bash
./git.sh unstage src/index.js
```
Removes a file from the staging area. File stays in working directory.

### Undo Last Commit (But Keep Changes)
```bash
# Soft: Keep changes staged (ready to commit again)
./git.sh reset soft 1

# Mixed: Keep changes unstaged (in working directory)
./git.sh reset mixed 1

# Undo last 2 commits
./git.sh reset soft 2
```

### Amend Last Commit
```bash
# Fix the commit message
./git.sh amend "Corrected message"

# Add more changes to last commit
./git.sh add .
./git.sh amend
```

### Remove File from Last Commit
```bash
./git.sh remove-file src/wrong-file.js
```
Removes a specific file from the last commit. File stays in working directory.

### Discard Last Commit Completely ⚠️ DESTRUCTIVE
```bash
# Discard last commit AND all changes
./git.sh reset hard 1

# Discard last 3 commits and changes
./git.sh reset hard 3
```
**WARNING**: This removes all changes! Requires confirmation.

---

## Clear Git Cache
```bash
./git.sh clear-cache
```
Cleans up and optimizes the git object database. Run occasionally for maintenance.

---

## Common Workflows

### Workflow 1: Add, Commit, Push All at Once
```bash
./git.sh acp . "Your commit message"
```

### Workflow 2: Add Changes, Commit, Then Push Later
```bash
./git.sh add
./git.sh commit "Your message"
# ... review changes ...
./git.sh push
```

### Workflow 3: Update Your Local Copy
```bash
./git.sh pull
```

### Workflow 4: Stage Specific Files
```bash
./git.sh add src/index.js
./git.sh add public/dashboard.html
./git.sh commit "Update UI and server"
./git.sh push
```

---

## ⭐ What if I Committed But Haven't Pushed Yet?

### Scenario 1: Wrong File in Commit
```bash
# Remove the wrong file from the commit
./git.sh remove-file src/wrong-file.js

# Commit again without that file
./git.sh acp . "Correct commit"
```

### Scenario 2: Wrong Commit Message
```bash
# Fix the message
./git.sh amend "Correct message"

# Then push
./git.sh push
```

### Scenario 3: Committed Too Much
```bash
# Undo last commit, keep all changes in staging
./git.sh reset soft 1

# Now cherry-pick what you want to commit
./git.sh unstage src/unwanted-file.js
./git.sh commit "Corrected commit"
./git.sh push
```

### Scenario 4: Multiple Bad Commits
```bash
# Undo last 3 commits, keep changes unstaged
./git.sh reset mixed 3

# Review changes
./git.sh status

# Commit properly
./git.sh add .
./git.sh commit "Fixed commits"
./git.sh push
```

### Scenario 5: Discard Everything (Last Commit Was Bad)
```bash
# Completely discard last commit (IRREVERSIBLE!)
./git.sh reset hard 1

# Or undo last 2 commits
./git.sh reset hard 2
```

---

## Common Workflows

### Workflow 1: Add, Commit, Push All at Once
```bash
./git.sh acp . "Your commit message"
```

### Workflow 2: Add Changes, Commit, Then Push Later
```bash
./git.sh add
./git.sh commit "Your message"
# ... review changes ...
./git.sh push
```

### Workflow 3: Update Your Local Copy
```bash
./git.sh pull
```

### Workflow 4: Stage Specific Files
```bash
./git.sh add src/index.js
./git.sh add public/dashboard.html
./git.sh commit "Update UI and server"
./git.sh push
```

---

## Troubleshooting

### "Not a git repository"
Run the script from the repository root:
```bash
cd /home/pantech-support/Desktop/GRM-whatsapp
./git.sh status
```

### "No staged changes to commit"
Stage files first:
```bash
./git.sh add .
./git.sh commit "Your message"
```

### "Push rejected"
Pull latest changes first:
```bash
./git.sh pull
./git.sh push
```

### "Merge conflicts"
Handle conflicts in editor, then:
```bash
./git.sh add .
./git.sh commit "Resolve conflicts"
./git.sh push
```

### "I committed the wrong thing!"
```bash
# Quick fix: Undo and recommit
./git.sh reset soft 1     # Undo, keep changes staged
./git.sh unstage wrong-file.js  # Remove unwanted file
./git.sh commit "Fixed message"
```

### "I accidentally committed sensitive data!"
```bash
# Soft reset (changes go back to staging)
./git.sh reset soft 1

# Remove the sensitive file
./git.sh unstage secret-file.txt

# Recommit without it
./git.sh commit "Clean commit"

# Add to .gitignore
echo "secret-file.txt" >> .gitignore
./git.sh acp . "Add to gitignore"
```

### "I want to undo multiple commits"
```bash
# See what commits you want to undo
./git.sh log 10

# Undo last 3 commits, keep changes
./git.sh reset mixed 3

# Review and recommit
./git.sh status
./git.sh acp . "Fixed"
```

---

## VPS Usage

Same commands work on your VPS:
```bash
cd /home/frappe/GRM/GRM-Whatsapp
./git.sh status
./git.sh acp . "Production update"
./git.sh log 5
```

---

## Keyboard Shortcuts (Optional)

Add to your `.bashrc` or `.zshrc`:
```bash
alias ga='cd /home/pantech-support/Desktop/GRM-whatsapp && ./git.sh add'
alias gc='cd /home/pantech-support/Desktop/GRM-whatsapp && ./git.sh commit'
alias gp='cd /home/pantech-support/Desktop/GRM-whatsapp && ./git.sh push'
alias gl='cd /home/pantech-support/Desktop/GRM-whatsapp && ./git.sh pull'
alias gs='cd /home/pantech-support/Desktop/GRM-whatsapp && ./git.sh status'
alias gacp='cd /home/pantech-support/Desktop/GRM-whatsapp && ./git.sh acp . '
```

Then use:
```bash
gs              # status
ga .            # add all
gc "message"    # commit
gp              # push
gl              # pull
gacp "Update"   # add, commit, push
```

---

## Tips

1. **Keep commits small**: Commit logically grouped changes
2. **Clear messages**: Use descriptive commit messages
3. **Pull before push**: Always pull latest changes first
4. **Review changes**: Use `git status` before committing
5. **Regular pushes**: Don't let changes pile up locally
6. **Clear cache**: Run `./git.sh clear-cache` monthly for maintenance

---

## Script Features

✅ Colored output for easy reading  
✅ Error handling and validation  
✅ Default sensible values (main branch, origin remote)  
✅ Works from any subdirectory  
✅ Fast combined operations  
✅ Git optimization included  
✅ Cross-platform compatible  
