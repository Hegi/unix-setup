FROM ubuntu:latest

RUN useradd -s /bin/bash -m -U -u 1001 -p '$6$G3v.CB7SjMSP2IMP$giMSeGOun/txXObSkG3jK6vGUmiUBNIhA60sDg0ds/W2pldOFMgSYK5r2GgErvZxmzJhADrCdE.dc7s/OYDr6.' hegi \
    && apt update && apt install -y vim sudo curl gnupg ca-certificates unzip \
    && echo "hegi ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hegi \

RUN mkdir -p /etc/apt/keyrings && chmod 0755 /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt update && apt install -y docker-ce-cli

USER hegi

WORKDIR /unix-setup

RUN sudo ./install.sh

ENTRYPOINT ["/usr/bin/zsh"]

# docker build -t heguntu -f ./tests/debian.dockerfile .
# docker run --rm -it -v $(pwd):$(pwd) -v /var/run/docker.sock:/var/run/docker.sock heguntu
