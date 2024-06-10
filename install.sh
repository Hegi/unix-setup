#!/bin/bash

. ./src/install_lib.sh

main() {
    if [[ -z "${SUDO_USER:-""}" ]]; then
        >&2 echo "Script has to run in sudo"
        exit -1
    fi

    if [[ "${SUDO_USER:-""}" == 'root' ]]; then
        >&2 echo "Script can't run for the root user!"
        exit -2
    fi

    install_as_root "$@"
    sudo -E -u "${SUDO_USER}" -H /bin/bash -c ". ./src/install_lib.sh; install_as_user" "$@"
}

main "$@"
