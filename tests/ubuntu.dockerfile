FROM ubuntu:latest

RUN useradd -s /bin/bash -m -U -u 1001 -p '$6$G3v.CB7SjMSP2IMP$giMSeGOun/txXObSkG3jK6vGUmiUBNIhA60sDg0ds/W2pldOFMgSYK5r2GgErvZxmzJhADrCdE.dc7s/OYDr6.' hegi \
    && apt update && apt install -y vim sudo curl gnupg ca-certificates unzip \
    && echo "hegi ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hegi \
    &&

USER hegi

WORKDIR /unix-setup

RUN sudo ./install.sh

ENTRYPOINT ["/usr/bin/zsh"]

# docker build -t heguntu -f ./tests/debian.dockerfile .
# docker run --rm -it -v $(pwd):$(pwd) -v /var/run/docker.sock:/var/run/docker.sock heguntu
