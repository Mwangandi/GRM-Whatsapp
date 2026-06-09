#!/bin/bash

################################################################################
# GRM-WhatsApp Git Management Script
# Simplified git operations: add, commit, push, pull, clear-cache
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║ $1"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Check if git repository
check_git_repo() {
    if [ ! -d ".git" ]; then
        log_error "Not a git repository"
        exit 1
    fi
}

################################################################################
# Git Operations
################################################################################

# Git add
git_add() {
    print_header "Git Add"
    
    check_git_repo
    
    local files="${1:-.}"
    
    log_info "Adding files: $files"
    git add "$files"
    
    log_success "Files staged for commit"
    git status --short
}

# Git commit
git_commit() {
    print_header "Git Commit"
    
    check_git_repo
    
    local message="$1"
    
    if [ -z "$message" ]; then
        log_error "Commit message is required"
        echo "Usage: $0 commit 'Your commit message'"
        exit 1
    fi
    
    log_info "Checking for staged changes..."
    if ! git diff --cached --quiet; then
        log_info "Committing: $message"
        git commit -m "$message"
        log_success "Commit successful"
    else
        log_warning "No staged changes to commit"
        log_info "Use '$0 add' to stage changes first"
    fi
}

# Git push
git_push() {
    print_header "Git Push"
    
    check_git_repo
    
    local branch="${1:-main}"
    local remote="${2:-origin}"
    
    log_info "Getting current branch..."
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    log_info "Current branch: $current_branch"
    log_info "Pushing to: $remote/$branch"
    
    if git push "$remote" "$current_branch:$branch"; then
        log_success "Push successful"
        git log --oneline -1
    else
        log_error "Push failed"
        exit 1
    fi
}

# Git pull
git_pull() {
    print_header "Git Pull"
    
    check_git_repo
    
    local branch="${1:-main}"
    local remote="${2:-origin}"
    
    log_info "Pulling from: $remote/$branch"
    
    if git pull "$remote" "$branch"; then
        log_success "Pull successful"
        git log --oneline -1
    else
        log_error "Pull failed"
        exit 1
    fi
}

# Git status
git_status() {
    print_header "Git Status"
    
    check_git_repo
    
    git status
}

# Clear git cache
git_clear_cache() {
    print_header "Clearing Git Cache"
    
    check_git_repo
    
    log_info "Clearing local git cache..."
    git gc --aggressive --prune=now
    log_success "Git cache cleared"
    
    log_info "Git statistics:"
    du -sh .git
}

# Combined add and commit
git_add_commit() {
    print_header "Git Add & Commit"
    
    check_git_repo
    
    local files="${1:-.}"
    local message="$2"
    
    if [ -z "$message" ]; then
        log_error "Commit message is required"
        echo "Usage: $0 add-commit '<files>' 'Your commit message'"
        exit 1
    fi
    
    log_info "Adding files: $files"
    git add "$files"
    
    log_info "Committing: $message"
    git commit -m "$message"
    
    log_success "Add and commit successful"
}

# Combined add, commit, and push
git_acp() {
    print_header "Git Add, Commit & Push"
    
    check_git_repo
    
    local files="${1:-.}"
    local message="$2"
    local branch="${3:-main}"
    local remote="${4:-origin}"
    
    if [ -z "$message" ]; then
        log_error "Commit message is required"
        echo "Usage: $0 acp '<files>' 'Your commit message' [branch] [remote]"
        exit 1
    fi
    
    # Add
    log_info "Adding files: $files"
    git add "$files"
    
    # Commit
    log_info "Committing: $message"
    git commit -m "$message"
    
    # Push
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    log_info "Pushing $current_branch to $remote/$branch"
    git push "$remote" "$current_branch:$branch"
    
    log_success "Add, commit, and push successful"
}

# View git log
git_log() {
    print_header "Git Log"
    
    check_git_repo
    
    local count="${1:-10}"
    
    log_info "Last $count commits:"
    git log --oneline -n "$count" --graph --decorate
}

# Stash changes
git_stash() {
    print_header "Git Stash"
    
    check_git_repo
    
    log_info "Stashing uncommitted changes..."
    git stash
    log_success "Changes stashed"
    
    log_info "Use 'git stash pop' to restore"
}

# Unstage file (remove from staging area)
git_unstage() {
    print_header "Git Unstage"
    
    check_git_repo
    
    local file="$1"
    
    if [ -z "$file" ]; then
        log_error "File path is required"
        echo "Usage: $0 unstage <file>"
        exit 1
    fi
    
    log_info "Unstaging: $file"
    git reset HEAD "$file"
    log_success "File unstaged"
    log_info "File remains in working directory"
}

# Reset (undo commits)
git_reset() {
    print_header "Git Reset"
    
    check_git_repo
    
    local mode="${1:-soft}"
    local commits="${2:-1}"
    
    if [[ ! "$mode" =~ ^(soft|hard|mixed)$ ]]; then
        log_error "Invalid mode: $mode (must be soft, hard, or mixed)"
        exit 1
    fi
    
    if ! [[ "$commits" =~ ^[0-9]+$ ]]; then
        log_error "Invalid number of commits: $commits"
        exit 1
    fi
    
    case $mode in
        soft)
            log_warning "Undoing last $commits commit(s) - keeping changes staged"
            git reset --soft HEAD~$commits
            log_success "Changes kept in staging area"
            ;;
        mixed)
            log_warning "Undoing last $commits commit(s) - keeping changes in working directory"
            git reset --mixed HEAD~$commits
            log_success "Changes kept in working directory (unstaged)"
            ;;
        hard)
            log_error "HARD RESET - This will discard all changes!"
            echo -n "Are you sure? (type 'yes' to confirm): "
            read -r confirmation
            if [ "$confirmation" = "yes" ]; then
                git reset --hard HEAD~$commits
                log_success "Changes discarded"
            else
                log_warning "Reset cancelled"
            fi
            ;;
    esac
    
    log_info "Current status:"
    git log --oneline -3
}

# Amend last commit
git_amend() {
    print_header "Git Amend"
    
    check_git_repo
    
    local message="$1"
    
    if [ -z "$message" ]; then
        log_info "Amending last commit with staged changes (no message change)..."
        git commit --amend --no-edit
    else
        log_info "Amending last commit: $message"
        git commit --amend -m "$message"
    fi
    
    log_success "Last commit amended"
    git log --oneline -1
}

# Remove file from last commit
git_remove_from_commit() {
    print_header "Git Remove File from Last Commit"
    
    check_git_repo
    
    local file="$1"
    
    if [ -z "$file" ]; then
        log_error "File path is required"
        echo "Usage: $0 remove-file <file>"
        exit 1
    fi
    
    log_info "Removing '$file' from last commit..."
    log_warning "This file will be moved to staging area"
    
    git reset --soft HEAD~1
    git reset HEAD "$file"
    
    log_success "File removed from last commit"
    log_info "File remains in working directory (unstaged)"
    log_info "You can re-commit without this file"
}

# Show git config
git_config() {
    print_header "Git Configuration"
    
    check_git_repo
    
    log_info "User name: $(git config user.name)"
    log_info "User email: $(git config user.email)"
    log_info "Remote origin: $(git config --get remote.origin.url)"
    log_info "Current branch: $(git rev-parse --abbrev-ref HEAD)"
}

# Show usage
usage() {
    cat << 'EOF'
Git Management Script - Simplified git operations

Usage: ./git.sh [COMMAND] [OPTIONS]

Commands:
    add [files]               Stage files for commit (default: all)
    commit 'message'          Commit staged changes
    push [branch] [remote]    Push to remote (default: main, origin)
    pull [branch] [remote]    Pull from remote (default: main, origin)
    
    acp [files] 'msg' ...     Add, commit, and push in one command
    ac [files] 'message'      Add and commit in one command
    
    status                    Show git status
    log [count]               Show recent commits (default: 10)
    stash                     Stash uncommitted changes
    config                    Show git configuration
    
    UNDO/FIX COMMANDS:
    unstage <file>            Remove file from staging area
    amend ['message']          Modify the last commit
    reset [mode] [count]      Undo commits (soft/hard/mixed, default: soft 1)
    remove-file <file>        Remove file from last commit
    
    clear-cache               Clear git object cache
    help                      Show this help message

Examples:
    # Stage all changes
    ./git.sh add
    
    # Stage specific file
    ./git.sh add src/index.js
    
    # Commit staged changes
    ./git.sh commit "Add new feature"
    
    # Push to main branch
    ./git.sh push main origin
    
    # Pull latest changes
    ./git.sh pull main origin
    
    # Add, commit, and push in one command
    ./git.sh acp . "Add new feature" main origin
    
    # View last 20 commits
    ./git.sh log 20
    
    # Clear git cache
    ./git.sh clear-cache
    
    # UNDO/FIX EXAMPLES:
    # Remove file from staging area before commit
    ./git.sh unstage src/index.js
    
    # Fix last commit message
    ./git.sh amend "Fixed message"
    
    # Undo last 1 commit, keep changes in staging
    ./git.sh reset soft 1
    
    # Undo last 2 commits, keep changes in working directory
    ./git.sh reset mixed 2
    
    # Discard last commit completely (WARNING!)
    ./git.sh reset hard 1
    
    # Remove a file from last commit
    ./git.sh remove-file src/wrong-file.js

Quick Operations:
    ./git.sh acp . "Update"         # Add all, commit, push to origin/main
    ./git.sh ac . "Update"          # Add all, commit
    ./git.sh status                 # Check status
    ./git.sh log                    # View commits

EOF
}

################################################################################
# Main Script
################################################################################

# Ensure we're in a git repository directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Parse command
COMMAND=${1:-help}

case $COMMAND in
    add)
        shift
        git_add "$@"
        ;;
    commit)
        shift
        git_commit "$@"
        ;;
    push)
        shift
        git_push "$@"
        ;;
    pull)
        shift
        git_pull "$@"
        ;;
    acp)
        shift
        git_acp "$@"
        ;;
    ac)
        shift
        git_add_commit "$@"
        ;;
    status)
        git_status
        ;;
    log)
        shift
        git_log "$@"
        ;;
    stash)
        git_stash
        ;;
    unstage)
        shift
        git_unstage "$@"
        ;;
    amend)
        shift
        git_amend "$@"
        ;;
    reset)
        shift
        git_reset "$@"
        ;;
    remove-file)
        shift
        git_remove_from_commit "$@"
        ;;
    config)
        git_config
        ;;
    clear-cache)
        git_clear_cache
        ;;
    help)
        usage
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        echo ""
        usage
        exit 1
        ;;
esac
