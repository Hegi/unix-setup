#!/bin/bash

if [[ -n "${ZSH_VERSION:-""}" ]]; then
  setopt pipefail
elif [[ -n "${BASH_VERSION}" ]]; then
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

download_from_github() {
    local repo
    local binary_name
    local app_name
    repo="${1}"
    binary_name="${2}"
    app_name="${3}"

    local latest
    latest=$(get_latest_github_version "${repo}")

    curl -fsSLo "${app_name}" "https://github.com/${repo}/releases/download/${latest}/${binary_name}"
}

get_binary_from_github() {
    local app_name
    app_name="${3:-${1##*/}}"
    download_from_github "${1}" "${2}" "${app_name}"

    chmod +x ./"${app_name}"
    mv ./"${app_name}" /usr/bin/
}

get_targz_from_github() {
    local app_name
    app_name="${3:-${1##*/}}"
    download_from_github "${1}" "${2}" "${app_name}.tar.gz"
    tar -xzvf "${app_name}.tar.gz"

    chmod +x ./"${app_name}"
    mv ./"${app_name}" /usr/bin/

    rm "${app_name}.tar.gz"
}

get_deb_from_github() {
    local app_name
    app_name="${3:-${1##*/}}"
    download_from_github "${1}" "${2}" "${app_name}"

    sudo dpkg -i ./"${app_name}"
    rm ./"${app_name}"
}

is_not_wsl() {
    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        return 1
    elif grep -qEi "microsoft" /proc/sys/kernel/osrelease &> /dev/null; then
        return 1
    else
        return 0
    fi
}

is_gui_present() {
    # Check for the DISPLAY environment variable
    if [[ -n "$DISPLAY" ]]; then
        return 0
    fi

    # Check for the XDG_SESSION_TYPE environment variable (common in modern desktops)
    if [[ "$XDG_SESSION_TYPE" == "x11" || "$XDG_SESSION_TYPE" == "wayland" ]]; then
        return 0
    fi

    # Check for processes associated with common desktop environments
    if pgrep -x "gnome-session" &> /dev/null || \
       pgrep -x "startkde" &> /dev/null || \
       pgrep -x "plasmashell" &> /dev/null || \
       pgrep -x "xfce4-session" &> /dev/null || \
       pgrep -x "lxsession" &> /dev/null; then
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

    app_name="$1"
    key_url="$2"
    apt_source_path="$3"
    use_gpg="${4:-false}"
    arch=""
    if [[ -n "${5:-""}" ]]; then
        arch="arch=${5}"
    fi

    if [[ -f "/etc/apt/sources.list.d/${app_name}.list" ]]; then
        return
    fi

    key_path="/etc/apt/keyrings/${app_name}.gpg"

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

    echo -e "deb [${arch} signed-by=${key_path}] ${apt_source_path}" > "/etc/apt/sources.list.d/${app_name}.list"
}

prepare_ms_key() {
    if type powershell > /dev/null 2>&1; then
        return
    fi

    curl -fsSLo packages-microsoft-prod.deb \
      "https://packages.microsoft.com/config/$(. /etc/os-release && echo "$ID")/$(. /etc/os-release && echo "$VERSION_ID")/packages-microsoft-prod.deb"

    dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
}

install_starship() {
    if type starship  > /dev/null 2>&1; then
        return
    fi

    curl -fsSL https://starship.rs/install.sh | sh -s -- -y

    # Note for configuration management:
    # add eval to ~/.zshrc
}

install_zoxide() {
    if type zoxide  > /dev/null 2>&1; then
        return
    fi
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

    # Note for configuration management:
    # add eval "$(zoxide init --cmd cd zsh)" to ~/.zshrc
    # add/home/$USER/.local/bin to the path
}

install_yq() {
    get_binary_from_github "mikefarah/yq" "yq_linux_amd64"
}

install_jq() {
    get_binary_from_github "jqlang/jq" "jq-linux-amd64"
}

install_bat() {
    # Naming is bad here, never version will break, needs to be more dynamic.
    get_deb_from_github "sharkdp/bat" "bat-musl_0.24.0_amd64.deb"
}

install_powershell() {
    # Naming is bad here, never version will break, needs to be more dynamic.
    get_deb_from_github "PowerShell/PowerShell" "powershell_7.4.2-1.deb_amd64.deb"
}

install_fzf() {
    # Naming is bad here, never version will break, needs to be more dynamic.
    get_targz_from_github "junegunn/fzf" "fzf-0.53.0-linux_amd64.tar.gz"
}

install_aws_cli() {
    mkdir -p aws-installer
    cd aws-installer
    curl -fsSLo "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    unzip awscliv2.zip
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    cd ..
    rm -rf aws-installer

    # Note for configuration management:
    # [ -f "/usr/local/bin/aws_completer" ] && complete -C "/usr/local/bin/aws_completer" aws
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

# Missing:
# https://github.com/basecamp/omakub/blob/master/install/app-zellij.sh
# https://github.com/basecamp/omakub/blob/master/install/app-neovim.sh - ??
# sudo install: shellcheck, flameshot, neovim, btop, ripgrep, gitsign, spotify
# sudo optional: lazygit, lazydocker, redis-tools mariadb-client build-essential
install_as_root() {
    local -a apps_to_install=()
    local arch
    arch="$(dpkg --print-architecture)"

    mkdir -p -m 755 /etc/apt/keyrings
    apt install -y curl gnupg ca-certificates unzip tar procps

    apps_to_install+=("zsh" "zip")

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
    # Note for configuration management: shall this be aliased as `alias ls='eza'` ?

    if is_not_wsl; then
        prepare_apt_key "docker" "https://download.docker.com/linux/debian/gpg" \
          "https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
          false "${arch}"
        apps_to_install+=("docker-ce-cli")
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

        prepare_apt_key "ulauncher" \
        "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xFAF1020699503176" \
        "http://ppa.launchpad.net/agornostal/ulauncher/ubuntu jammy main"
        apps_to_install+=("ulauncher")

        apps_to_install+=("vlc")

        install_zoom
        install_vscode

        # Set monospace font
        cp ./10-monospace-fonts.conf /etc/fonts/conf.d/

    else
        echo "No need to install GUI applications and packages"
    fi

    apt update && apt upgrade -y
    apt install -y --no-install-recommends "${apps_to_install[@]}"
    # Temporarily turning off powershell due to: https://github.com/PowerShell/PowerShell/issues/23197
    # install_powershell
    install_starship
    install_jq
    install_yq
    install_fzf
    install_aws_cli
    install_bat

    chsh -s /bin/zsh "${SUDO_USER}" # if user is not root, this command requires authentication
}

install_as_user() {

    install_zoxide

    # Note for configuration management:
    # 	&& echo 'if [ -f ~/.bash_local ]; then' >>/home/vscode/.bashrc \
    #   && echo '  . ~/.bash_local' >>/home/vscode/.bashrc \
    # 	&& echo 'fi' >>/home/vscode/.bashrc \
    # 	&& sed -i -e 's/HISTSIZE=[0-9]*/HISTISZE=100000/' -e 's/HISTFILESIZE=[0-9]*/HISTFILESIZE=200000/' /home/vscode/.bashrc \
    # 	&& echo 'eval "$(zoxide init bash)"' >>/home/vscode/.bashrc && echo 'eval "$(starship init bash)"' >>/home/vscode/.bashrc \
    # 	&& echo 'eval "$(zoxide init zsh)"' >>/home/vscode/.zshrc && echo 'eval "$(starship init zsh)"' >>/home/vscode/.zshrc \
    # 	&& terraform -install-autocomplete

    # Note: make nodejs installation optional. Opt in/out?
    if ! type nvm  > /dev/null 2>&1; then
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh" | bash

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
        local latest_node_version_number
        set +euxo pipefail
        latest_node_version_number="$(nvm ls-remote | tail -1 | sed 's/^[[:space:]]*v//' | awk '{$1=$1; print}')"
        echo "latest_node_version_number: ${latest_node_version_number}"
        nvm install "${latest_node_version_number}" --latest-npm
        set -euxo pipefail
        npm config set fund false --location=global
    	# npm install -g @nestjs/cli jest vercel prettier
    fi

    if is_not_wsl && is_gui_present; then
        install_fonts
    fi
}
