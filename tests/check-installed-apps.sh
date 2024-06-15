#!/bin/zsh

if [[ -n "${ZSH_VERSION:-""}" ]]; then
    setopt pipefail
elif [[ -n "${BASH_VERSION:-""}" ]]; then
    set -o pipefail
fi

set -eux

test_installed_apps() {
    zip --version > /dev/null
    gpg --version > /dev/null
    curl --version > /dev/null
    wget --version > /dev/null
    zip --version > /dev/null
    tar --version > /dev/null
    xz --version > /dev/null
    zsh --version > /dev/null
    stow --version > /dev/null
    http --version > /dev/null  # httpie
    https --version > /dev/null # httpie
    gum --version > /dev/null
    terraform --version > /dev/null
    #powershell -- version > /dev/null
    gh --version > /dev/null
    eza --version > /dev/null
    docker --version > /dev/null
    git --version > /dev/null
    starship --version > /dev/null
    jq --version > /dev/null
    yq --version > /dev/null
    fzf --version > /dev/null
    aws --version > /dev/null
    bat --version > /dev/null
    zellij --version > /dev/null
    shellcheck --version > /dev/null
    zoxide --version > /dev/null
    rgrep --version > /dev/null
    type zinit
    nvm --version > /dev/null
}

test_installed_apps
