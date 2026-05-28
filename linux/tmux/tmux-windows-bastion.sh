#!/bin/bash
## Creates the tmux session and attaches to all the target linux hosts I have
## Run from GCP jump host

SESSION="bastion-windows"

# Kill existing session
tmux kill-session -t $SESSION 2>/dev/null

############################################
# CREATE BASE SESSION
############################################

tmux new-session -d -s $SESSION -n "kali-dev"

############################################
# DEFINE TARGETS
############################################

NAMES=(
"kali-dev"
"kast3-dev"
"kali-dev2"
"kali-install-test"
"ss-portal"
"ELK2"
"ELK3"
"az-redwebvuln"
"az-bluewebvuln"
)

CMDS=(
"~/aws-kali-dev.sh"
"~/gcp-kast3-dev.sh"
"~/aws-kali-dev-2.sh"
"~/aws-kali-install-test.sh"
"~/aws-ssportal-useast2.sh"
"~/aws-elk2-useast2.sh"
"~/aws-elk3-useast2.sh"
"~/az-redwebvuln.sh"
"~/az-bluewebvuln.sh"
)

############################################
# CREATE WINDOWS
############################################

# First window already exists (index 0)
for i in "${!NAMES[@]}"; do

    NAME="${NAMES[$i]}"
    CMD="${CMDS[$i]}"

    if [ "$i" -eq 0 ]; then
        TARGET="$SESSION:0"
    else
        tmux new-window -t $SESSION -n "$NAME"
        TARGET="$SESSION:$i"
    fi

    # Run connection script
    tmux send-keys -t "$TARGET" "$CMD" Enter

    # Slight delay for ssh handshake / prompt
    sleep 0.8

    # Send second Enter (handles oh-my-zsh update prompt)
    tmux send-keys -t "$TARGET" Enter
done

############################################
# SET FIRST WINDOW ACTIVE
############################################

tmux select-window -t $SESSION:0

############################################
# ATTACH
############################################

tmux attach -t $SESSION
