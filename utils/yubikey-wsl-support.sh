#!/usr/bin/zsh

if [[ -n "${ZSH_VERSION:-""}" ]]; then
    setopt pipefail
elif [[ -n "${BASH_VERSION:-""}" ]]; then
    set -o pipefail
fi

set -eux

localAppData="$(wslpath "$(powershell.exe '$env:LOCALAPPDATA')" | tr -d '\r')"
roamingAppData="$(wslpath "$(powershell.exe '$env:APPDATA')" | tr -d '\r')"

if [[ ! -d "${roamingAppData}/npiperelay" ]]; then
    mkdir -p "${roamingAppData}/npiperelay"
    cp ./utils/windows/npiperelay/npiperelay.exe "${roamingAppData}/npiperelay/npiperelay.exe"
fi

if [[ ! -d "${roamingAppData}/wsl-ssh-pageant" ]]; then
    mkdir -p "${roamingAppData}/wsl-ssh-pageant"
    cp ./utils/windows/wsl-ssh-pageant/* "${roamingAppData}/wsl-ssh-pageant/"
fi

if [[ ! -d "${roamingAppData}/gnupg" ]]; then
    mkdir -p "${roamingAppData}/gnupg"
    cp "utils/windows/gnupg/*"
fi

if [[ ! -f "${HOME}/.local/bin/gpg-agent-relay" ]]; then
    mkdir -p "${HOME}/.local/bin"
    cp "utils/scripts/gpg-agent-relay" "${HOME}/.local/bin/gpg-agent-relay"
fi
