#!/bin/bash

SESSION="Nested-Linux-tmux-session-name-here"

# Kill existing session if it exists
tmux kill-session -t $SESSION 2>/dev/null

############################################
# CREATE BASE SESSION
############################################

tmux new-session -d -s $SESSION -n "win 0"

############################################
# CREATE WINDOWS
############################################

for i in {0..9}; do

    WIN_NAME="win $i"

    if [ "$i" -eq 1 ]; then
        TARGET="$SESSION:0"
    else
        tmux new-window -t $SESSION -n "$WIN_NAME"
        TARGET="$SESSION:$((i-1))"
    fi

    # Send initial CR (empty enter)
    tmux send-keys -t "$TARGET" Enter

    # Small delay to ensure prompt is ready
    sleep 0.2

    # Move to home directory
    tmux send-keys -t "$TARGET" "cd ~" Enter

done

############################################
# SET FIRST WINDOW ACTIVE
############################################

tmux select-window -t $SESSION:0

############################################
# ATTACH
############################################

tmux attach -t $SESSION
