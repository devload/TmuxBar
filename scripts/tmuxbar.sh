#!/bin/bash
# TmuxBar Shell Functions
# Add to your .zshrc or .bashrc: source /path/to/tmuxbar.sh

# ============================================
# Quick Commands
# ============================================
# ts  - Select and attach to session (requires fzf)
# ta  - Attach to session by name
# tl  - List all sessions
# tn  - New session
# tk  - Kill session
# td  - Detach from current session
# tw  - List windows in current session
# ============================================

# Check if fzf is installed
_has_fzf() {
    command -v fzf &> /dev/null
}

# List sessions with formatting
tl() {
    if ! tmux list-sessions 2>/dev/null; then
        echo "No tmux sessions running"
        return 1
    fi
}

# Select and attach to session using fzf
ts() {
    if ! _has_fzf; then
        echo "fzf is required for ts. Install with: brew install fzf"
        echo "Use 'ta <session>' instead"
        return 1
    fi

    local sessions
    sessions=$(tmux list-sessions -F "#{session_name}|#{session_windows} windows|#{?session_attached,attached,}" 2>/dev/null)

    if [[ -z "$sessions" ]]; then
        echo "No tmux sessions. Create one with: tn <name>"
        return 1
    fi

    local selected
    selected=$(echo "$sessions" | column -t -s '|' | fzf --height=40% --reverse --header="Select tmux session (Enter to attach, Ctrl-C to cancel)")

    if [[ -n "$selected" ]]; then
        local session_name
        session_name=$(echo "$selected" | awk '{print $1}')
        tmux attach -t "$session_name"
    fi
}

# Attach to session by name (with tab completion)
ta() {
    local session="${1:-}"

    if [[ -z "$session" ]]; then
        # If no argument, show available sessions
        echo "Usage: ta <session_name>"
        echo ""
        echo "Available sessions:"
        tl
        return 1
    fi

    if tmux has-session -t "$session" 2>/dev/null; then
        tmux attach -t "$session"
    else
        echo "Session '$session' not found"
        echo ""
        echo "Available sessions:"
        tl
        return 1
    fi
}

# New session
tn() {
    local name="${1:-}"
    local dir="${2:-$(pwd)}"

    if [[ -z "$name" ]]; then
        # Generate name from current directory
        name=$(basename "$dir")
    fi

    if tmux has-session -t "$name" 2>/dev/null; then
        echo "Session '$name' already exists. Attaching..."
        tmux attach -t "$name"
    else
        echo "Creating session '$name' in $dir"
        tmux new-session -d -s "$name" -c "$dir"
        tmux attach -t "$name"
    fi
}

# Kill session
tk() {
    local session="${1:-}"

    if [[ -z "$session" ]]; then
        if _has_fzf; then
            # Use fzf to select session to kill
            local sessions
            sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

            if [[ -z "$sessions" ]]; then
                echo "No tmux sessions to kill"
                return 1
            fi

            session=$(echo "$sessions" | fzf --height=40% --reverse --header="Select session to kill")

            if [[ -z "$session" ]]; then
                return 0
            fi
        else
            echo "Usage: tk <session_name>"
            echo ""
            echo "Available sessions:"
            tl
            return 1
        fi
    fi

    if tmux has-session -t "$session" 2>/dev/null; then
        read -r "confirm?Kill session '$session'? [y/N] "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$session"
            echo "Session '$session' killed"
        fi
    else
        echo "Session '$session' not found"
        return 1
    fi
}

# Detach from current session
td() {
    tmux detach-client 2>/dev/null || echo "Not in a tmux session"
}

# List windows in current/specified session
tw() {
    local session="${1:-}"

    if [[ -n "$session" ]]; then
        tmux list-windows -t "$session" 2>/dev/null || echo "Session '$session' not found"
    elif [[ -n "$TMUX" ]]; then
        tmux list-windows
    else
        echo "Not in a tmux session. Usage: tw <session_name>"
    fi
}

# Quick switch between recent sessions (when inside tmux)
tswitch() {
    if [[ -z "$TMUX" ]]; then
        echo "Not in a tmux session. Use 'ts' to select a session."
        return 1
    fi

    if _has_fzf; then
        local current_session
        current_session=$(tmux display-message -p '#S')

        local session
        session=$(tmux list-sessions -F "#{session_name}" | grep -v "^${current_session}$" | fzf --height=40% --reverse --header="Switch to session")

        if [[ -n "$session" ]]; then
            tmux switch-client -t "$session"
        fi
    else
        tmux switch-client -n
    fi
}

# ============================================
# Tab Completion (zsh)
# ============================================
if [[ -n "$ZSH_VERSION" ]]; then
    _tmux_sessions() {
        local sessions
        sessions=(${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"})
        _describe 'sessions' sessions
    }

    compdef _tmux_sessions ta tk tw
fi

# ============================================
# Tab Completion (bash)
# ============================================
if [[ -n "$BASH_VERSION" ]]; then
    _tmux_session_complete() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        COMPREPLY=($(compgen -W "$(tmux list-sessions -F '#{session_name}' 2>/dev/null)" -- "$cur"))
    }

    complete -F _tmux_session_complete ta tk tw
fi

# ============================================
# Aliases
# ============================================
alias tmuxls='tl'
alias tmuxnew='tn'
alias tmuxattach='ta'
alias tmuxkill='tk'

echo "TmuxBar shell functions loaded! Commands: ts, ta, tl, tn, tk, td, tw"
