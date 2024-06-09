#!/bin/bash

if [[ -n "${ZSH_VERSION}" ]]; then
  setopt pipefail
elif [[ -n "${BASH_VERSION}" ]]; then
  set -o pipefail
fi

set -eux

. ./src/install_lib.sh

if [[ -n "${ZSH_VERSION}" ]]; then # shebang is zsh, so this should be the default
  setopt pipefail
elif [[ -n "${BASH_VERSION}" ]]; then # to keep it portable bash flavour is also supported
  set -o pipefail
fi

set -eux

main() {
    if [[ -z "${SUDO_USER}" ]]; then
        >&2 echo "Script has to run in sudo"
        exit -1
    fi

    if [[ "${SUDO_USER}" == 'root' ]]; then
        >&2 echo "Script can't run for the root user!"
        exit -2
    fi

    install_as_root "$@"
    sudo -E -u "${SUDO_USER}" -H zsh -c ". ./src/install_lib.sh; install_as_user" "$@"
}

main "$@"
