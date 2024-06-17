#!/bin/bash

if [[ -n "${ZSH_VERSION:-""}" ]]; then
    setopt pipefail
elif [[ -n "${BASH_VERSION:-""}" ]]; then
    set -o pipefail
fi

set -eux

is_app_installed() {
    local app_name
    app_name="${1}"
    apt list --installed 2>/dev/null | grep -q "^${app_name}/"
}

get_latest_github_version() {
    local repo
    repo="${1}"

    local latest
    latest="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"

    echo "${latest}"
}

get_artifact_from_github() {
    local repo
    local binary_name
    local app_name
    repo="${1}"
    binary_name="${2}"
    app_name="${3:-${1##*/}}"

    curl -fsSLo "${binary_name}" "https://github.com/${repo}/releases/latest/download/${binary_name}"

    if [[ "${binary_name}" == *.tar.gz ]]; then
        tar -xzvf "${binary_name}"
    elif [[ "${binary_name}" == *.tar.xz ]]; then
        tar -xJvf "${binary_name}"
    elif [[ "${binary_name}" == *.zip ]]; then
        unzip "${binary_name}"
    elif [[ "${binary_name}" == *.deb ]]; then
        dpkg -i ./"${binary_name}"
        rm "${binary_name}"
        return
    else
        cp ./"${binary_name}" ./"${app_name}"
    fi

    local file_name
    file_name="$(find -type f -name ${app_name})"
    if [[ "$(realpath "$(dirname $file_name)")" != "$(pwd)" ]]; then
        mv "${file_name}" "$(pwd)"
        rm -rf "$(realpath "$(dirname $file_name)")"
    fi

    chmod +x ./"${app_name}"
    mv ./"${app_name}" /usr/local/bin/

    rm "${binary_name}"
}

is_not_wsl() {
    if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        return 1
    elif grep -qEi "microsoft" /proc/sys/kernel/osrelease &>/dev/null; then
        return 1
    else
        return 0
    fi
}

is_gui_present() {
    # Check for the DISPLAY environment variable
    if [[ -n "${DISPLAY:-""}" ]]; then
        return 0
    fi

    # Check for the XDG_SESSION_TYPE environment variable (common in modern desktops)
    if [[ "${XDG_SESSION_TYPE:-""}" == "x11" || "${XDG_SESSION_TYPE:-""}" == "wayland" ]]; then
        return 0
    fi

    # Check for processes associated with common desktop environments
    if pgrep -x "gnome-session" &>/dev/null ||
        pgrep -x "startkde" &>/dev/null ||
        pgrep -x "plasmashell" &>/dev/null ||
        pgrep -x "xfce4-session" &>/dev/null ||
        pgrep -x "lxsession" &>/dev/null; then
        return 0
    fi

    return 1
}

prepare_apt_key() {
    local app_name
    local key_url
    local key_path
    local arch
    local use_gpg
    local apt_source_path
    local file_extension

    app_name="$1"
    key_url="$2"
    apt_source_path="$3"
    use_gpg="${4:-false}"
    arch=""
    if [[ -n "${5:-""}" ]]; then
        arch="arch=${5}"
    fi
    file_extension="${6:-"gpg"}"

    if [[ -f "/etc/apt/sources.list.d/${app_name}.list" ]]; then
        return
    fi

    key_path="/etc/apt/keyrings/${app_name}.${file_extension}"

    if [[ "$use_gpg" = true ]]; then
        curl -fsSL "$key_url" | gpg --dearmor -o "$key_path"
    else
        curl -fsSLo "$key_path" "$key_url"
    fi

    chmod go+r "$key_path"

    if [ $? -ne 0 ]; then
        echo "Failed to download GPG key for $app_name"
        return 1
    fi

    echo -e "deb [${arch} signed-by=${key_path}] ${apt_source_path}" >"/etc/apt/sources.list.d/${app_name}.list"
}

prepare_ms_key() {
    if type powershell >/dev/null 2>&1; then
        return
    fi

    curl -fsSLo packages-microsoft-prod.deb \
        "https://packages.microsoft.com/config/$(. /etc/os-release && echo "$ID")/$(. /etc/os-release && echo "$VERSION_ID")/packages-microsoft-prod.deb"

    dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
}

install_starship() {
    if type starship >/dev/null 2>&1; then
        return
    fi

    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

install_zoxide() {
    if type zoxide >/dev/null 2>&1; then
        return
    fi
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_yq() {
    get_artifact_from_github "mikefarah/yq" "yq_linux_amd64"
}

install_jq() {
    get_artifact_from_github "jqlang/jq" "jq-linux-amd64"
}

install_bat() {
    # Naming is bad here, never version will break, needs to be more dynamic.
    get_artifact_from_github "sharkdp/bat" "bat-musl_0.24.0_amd64.deb"
}

install_powershell() {
    # Naming is bad here, never version will break, needs to be more dynamic.
    get_artifact_from_github "PowerShell/PowerShell" "powershell_7.4.2-1.deb_amd64.deb"
}

install_fzf() {
    # Naming is bad here, never version will break, needs to be more dynamic.
    get_artifact_from_github "junegunn/fzf" "fzf-0.53.0-linux_amd64.tar.gz"
}

install_aws_cli() {
    mkdir -p aws-installer
    cd aws-installer
    curl -fsSLo "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    unzip awscliv2.zip
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    cd ..
    rm -rf aws-installer
}

install_vscode() {
    curl -fsSLo vscode.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
    dpkg -i ./vscode.deb
    rm ./vscode.deb
}

install_zoom() {
    curl -fsSLo zoom.deb https://zoom.us/client/latest/zoom_amd64.deb
    dpkg -i ./zoom.deb
    rm zoom.deb
}

download_and_install_sauce_code_pro() {
    # Download Font
    local FONT="SourceCodePro"
    local LATEST_RELEASE=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep "tag_name" | cut -d '"' -f 4)
    local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/$LATEST_RELEASE/$FONT.zip"
    curl -fsSLo "${FONT}.zip" $FONT_URL

    unzip "${FONT}.zip" -d ~/.local/share/fonts

    # Cleanup extra variants, only for SauceCodePro
    rm ~/.local/share/fonts/*Propo-* ~/.local/share/fonts/*Mono-*

    rm "${FONT}.zip"
}

download_and_install_roboto() {
    ## Roboto
    FONT_URL="https://fonts.google.com/download?family=Roboto"
    curl -fsSLo Roboto.zip "${FONT_URL}"

    unzip Roboto.zip -d ~/.local/share/fonts

    rm Roboto.zip
}

install_fonts() {
    mkdir -p ~/.local/share/fonts

    download_and_install_sauce_code_pro
    download_and_install_roboto

    # Apply new font
    fc-cache -fv
}

install_zellij() {
    get_artifact_from_github "zellij-org/zellij" "zellij-x86_64-unknown-linux-musl.tar.gz"
}

install_shellcheck() {
    get_artifact_from_github "koalaman/shellcheck" "shellcheck-v0.10.0.linux.x86_64.tar.xz"
}

install_ripgrep() {
    get_artifact_from_github "BurntSushi/ripgrep" "ripgrep_14.1.0-1_amd64.deb"
}

install_pnpm() {
    curl -fsSL https://get.pnpm.io/install.sh | sh -
}

build_and_install_git() {
    docker build -t git-builder -f ./utils/git.dockerfile .
    docker run --rm -v $(pwd):/output git-builder
    docker image rm git-builder
    apt remove -y git git-man # There is currently a bug with the local git build. This is a workaround line
    dpkg -i git.deb
    apt install -y gh terraform  git-remote-gcrypt # There is currently a bug with the local git build. This is a workaround line
    rm git.deb
}

build_and_install_stow() {
    docker build -t stow-builder -f ./utils/stow.dockerfile .
    docker run --rm -v $(pwd):/output stow-builder
    docker image rm stow-builder
    sudo dpkg -i stow.deb
    rm stow.deb
}

install_nvm() {
    if type nvm >/dev/null 2>&1; then
        return
    fi

    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh" | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
    local latest_node_version_number
    set +euxo pipefail
    latest_node_version_number="$(nvm ls-remote | tail -1 | sed 's/^[[:space:]]*v//' | awk '{$1=$1; print}')"
    echo "latest_node_version_number: ${latest_node_version_number}"
    nvm install "${latest_node_version_number}" --latest-npm
    set -euxo pipefail
    npm config set fund false --location=global
    # npm install -g @nestjs/cli jest vercel prettier
}

# Missing:
# sudo install: neovim,
# sudo optional: lazygit, lazydocker
install_as_root() {
    local -a apps_to_install=()
    local -a apps_to_remove=()
    local arch
    local distro
    arch="$(dpkg --print-architecture)"
    distro="$(. /etc/os-release && echo "${ID}")"

    mkdir -p -m 755 /etc/apt/keyrings
    if [[ "${distro}" == "ubuntu" ]]; then
        apt install -y zip procps gnupg2
    else
        apt install -y curl wget gnupg2 ca-certificates unzip tar xz-utils procps
    fi

    apps_to_install+=("zsh" "zip" "stow" "btop")

    prepare_apt_key "httpie" "https://packages.httpie.io/deb/KEY.gpg" "https://packages.httpie.io/deb ./" true "${arch}"
    apps_to_install+=("httpie")

    prepare_apt_key "charm" "https://repo.charm.sh/apt/gpg.key" "https://repo.charm.sh/apt/ * *" true
    apps_to_install+=("gum")

    prepare_apt_key "hashicorp" "https://apt.releases.hashicorp.com/gpg" \
        "https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" true
    apps_to_install+=("terraform")

    prepare_ms_key
    # Temporarily turning off powershell due to: https://github.com/PowerShell/PowerShell/issues/23197
    #apps_to_install+=("libicu74")
    #apps_to_install+=("libicu72")

    prepare_apt_key "githubcli-archive-keyring" "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
        "https://cli.github.com/packages stable main" false "${arch}"
    apps_to_install+=("gh")

    prepare_apt_key "gierens" https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        "http://deb.gierens.de stable main" true "${arch}"
    apps_to_install+=("eza")

    if is_not_wsl; then
        prepare_apt_key "docker" "https://download.docker.com/linux/debian/gpg" \
            "https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
            false "${arch}" "asc"
        apps_to_remove+=("docker.io" "docker-doc" "docker-compose" "podman-docker" "containerd" "runc")
        apps_to_install+=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")

    fi

    if is_not_wsl && is_gui_present; then
        prepare_apt_key "brave-browser" \
            "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" \
            "https://brave-browser-apt-release.s3.brave.com/ stable main"
        apps_to_install+=("brave-brwoser")

        prepare_apt_key "signal-desktop" \
            "https://updates.signal.org/desktop/apt/keys.asc" "https://updates.signal.org/desktop/apt xenial main" \
            true "${arch}"
        apps_to_install+=("signal-desktop")

        prepare_apt_key "spotify" "https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg" \
        "http://repository.spotify.com stable non-free" true true
        apps_to_install+=("spotify-client")

        if [[ "${distro}" == "ubuntu" ]]; then
            add-apt-repository universe -y
            add-apt-repository ppa:agornostal/ulauncher -y
        else
            prepare_apt_key "ulauncher" \
                "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xFAF1020699503176" \
                "http://ppa.launchpad.net/agornostal/ulauncher/ubuntu jammy main"
        fi
        apps_to_install+=("ulauncher")

        apps_to_install+=("vlc" "flameshot")

        install_zoom
        install_vscode

        # Set monospace font
        cp ./10-monospace-fonts.conf /etc/fonts/conf.d/

    else
        echo "No need to install GUI applications and packages"
    fi

    apps_to_install+=("stow") # latest stow build is fragile. Using default one instead.

    if [[ "${distro}" == "ubuntu" ]]; then
        add-apt-repository ppa:git-core/ppa
        apt update
    fi
    apt update && apt upgrade -y
    apt remove -y "${apps_to_remove[@]}"
    apt install -y --no-install-recommends "${apps_to_install[@]}"
    # Temporarily turning off powershell due to: https://github.com/PowerShell/PowerShell/issues/23197
    # install_powershell
    install_starship
    install_jq
    install_yq
    install_fzf
    install_aws_cli
    install_bat
    install_zellij
    install_shellcheck
    install_ripgrep
    if [[ "${distro}" != "ubuntu" ]]; then
        build_and_install_git
    fi
    # build_and_install_stow # latest stow build is fragile. Using default one instead.


    chsh -s /bin/zsh "${SUDO_USER}" # if user is not root, this command requires authentication
}

download_dotfiles() {
    local dotfiles_repo
    local dotfiles_key_file

    dotfiles_repo="${1:-"https://github.com/Hegi/dotfiles-public.git"}"
    dotfiles_key_file="$(realpath ${2:-""})"

    if [[ -n "${dotfiles_key_file}" ]]; then
        if [[ "${dotfiles_repo}" != "gcrypt::"* ]]; then
            dotfiles_repo="gcrypt::${dotfiles_repo}"
        fi
        gpg --import-options restore --import "${dotfiles_key_file}"
    fi

    cd ~
    git clone "${dotfiles_repo}" dotfiles
    cd dotfiles
    if [[ -n "${dotfiles_key_file}" ]]; then
        local gpg_key_id
        gpg_key_id="$(gpg --show-keys "${dotfiles_key_file}" | grep -E '^[[:space:]]+[0-9A-F]{4}' | tr -d ' ')"
        git config remote.origin.gcrypt-participants "${gpg_key_id}" # "$(git config user.signingkey)"
        git config user.signingkey "${gpg_key_id}"
    fi
    stow .
}

download_zinit() {
    local ZINIT_HOME
    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git" # has to be the same as in your .zshrc file
    if [[ -d "${ZINIT_HOME}" ]]; then
        return
    fi

    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone --depth 1 "https://github.com/zdharma-continuum/zinit.git" "$ZINIT_HOME"
}

install_as_user() {

    install_zoxide
    install_nvm
    download_dotfiles "${1}" "${2}"
    download_zinit

    if is_not_wsl && is_gui_present; then
        install_fonts
    fi
}
