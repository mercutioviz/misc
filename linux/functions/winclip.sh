# For use with terminals that support OSC 52 (i.e. Windows Terminal)
# add to .bashrc or .zshrc or whatever you use
winclip() {
    local data

    usage() {
        cat <<'EOF'
Usage: winclip [FILE]
       command | winclip

Copies text from a Linux terminal into the Windows clipboard using OSC 52.

Arguments:
  FILE        Read clipboard content from FILE.
              If no FILE is provided, winclip reads from stdin.

Options:
  -h, --help  Show this help message.

Examples:
  winclip file.txt
  cat file.txt | winclip
  ip addr show | winclip
  kubectl get pods -A | winclip
EOF
    }

    if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
        usage
        return 0
    fi

    if [ "$#" -eq 0 ]; then
        data="$(cat | base64 -w0)"
    elif [ "$#" -eq 1 ]; then
        if [ ! -r "$1" ]; then
            echo "winclip: cannot read file: $1" >&2
            return 1
        fi
        data="$(base64 -w0 "$1")"
    else
        usage >&2
        return 1
    fi

    printf '\033]52;c;%s\a' "$data"
}
