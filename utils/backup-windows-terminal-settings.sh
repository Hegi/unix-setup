#!/bin/zsh

if [[ -n "${ZSH_VERSION:-""}" ]]; then
    setopt pipefail
elif [[ -n "${BASH_VERSION:-""}" ]]; then
    set -o pipefail
fi

set -eux

terminalAppFolder="$(find "$(wslpath "$(powershell.exe '$env:LOCALAPPDATA')" | tr -d '\r')/Packages" -maxdepth 1 -type d -name "Microsoft.WindowsTerminal_*")"

mkdir -p "utils/windows-terminal"
cp "${terminalAppFolder}/LocalState/settings.json" "utils/windows-terminal/settings.json"
chmod -x "utils/windows-terminal/settings.json"
