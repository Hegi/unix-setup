FROM debian:latest

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libcurl4-gnutls-dev \
    libexpat1-dev \
    gettext \
    libz-dev \
    libssl-dev \
    asciidoc \
    xmlto \
    docbook2x \
    install-info \
    dh-make \
    devscripts \
    fakeroot \
    curl \
    git

# Create a non-root user
RUN useradd -m builder

# Switch to non-root user
USER builder
WORKDIR /home/builder

# Shallow clone the Git repository at the specific tag
RUN git clone --depth 1 --branch v2.45.2 https://github.com/git/git.git /home/builder/git

# Set working directory
WORKDIR /home/builder/git

# Set the version manually based on the tag
ENV GIT_VERSION=2.45.2

# Build Git
RUN make configure && \
    ./configure --prefix=/usr && \
    make all doc info

# Install Git to a temporary directory
RUN make install DESTDIR=/tmp/git-install

RUN mkdir -p /tmp/git-deb/DEBIAN && \
    echo "Package: git" > /tmp/git-deb/DEBIAN/control && \
    echo "Version: $GIT_VERSION" >> /tmp/git-deb/DEBIAN/control && \
    echo "Section: vcs" >> /tmp/git-deb/DEBIAN/control && \
    echo "Priority: optional" >> /tmp/git-deb/DEBIAN/control && \
    echo "Architecture: amd64" >> /tmp/git-deb/DEBIAN/control && \
    echo "Maintainer: builder <builder@unknown>" >> /tmp/git-deb/DEBIAN/control && \
    echo "Description: Git version control system" >> /tmp/git-deb/DEBIAN/control

# Create a tarball of the installed files
RUN mkdir -p /tmp/git-tarball && \
    cd /tmp/git-install && \
    tar czf /tmp/git-tarball/git.tar.gz .

ENV USER=builder

# Create a Debian package
RUN mkdir -p /tmp/git-deb && cd /tmp/git-deb && \
    tar xzf /tmp/git-tarball/git.tar.gz && \
    dh_make --createorig -y -s -p git_$GIT_VERSION && \
    dpkg-deb --build /tmp/git-deb /home/builder

# Switch back to root to copy the package
USER root

# Copy the Debian package to a known location
RUN mv /home/builder/git_*.deb /home/builder/git.deb

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home/builder

# Set entrypoint to bash for manual inspection (optional)
ENTRYPOINT ["/bin/cp", "./git.deb", "/output"]

# docker run --rm -v $(pwd):/output git-builder
# sudo dpkg -i git.deb
