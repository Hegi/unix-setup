FROM debian:latest

# Set the environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
    wget \
    tar \
    build-essential \
    perl \
    dh-make \
    && apt-get clean

# Download and extract the latest GNU Stow source code
RUN wget http://ftp.gnu.org/gnu/stow/stow-latest.tar.gz && \
    tar -xzf stow-latest.tar.gz && \
    cd stow-* && \
    ./configure && \
    make && \
    make install DESTDIR=/tmp/stow-package && \
    cd .. && \
    rm stow-latest.tar.gz

# Create the directory structure for the Debian package
RUN mkdir -p /tmp/stow-package/DEBIAN

# Add control file for the package
RUN echo "Package: stow" > /tmp/stow-package/DEBIAN/control && \
    echo "Version: 2.4.0" >> /tmp/stow-package/DEBIAN/control && \
    echo "Section: utils" >> /tmp/stow-package/DEBIAN/control && \
    echo "Priority: optional" >> /tmp/stow-package/DEBIAN/control && \
    echo "Architecture: all" >> /tmp/stow-package/DEBIAN/control && \
    echo "Maintainer: builder <builder@example.com>" >> /tmp/stow-package/DEBIAN/control && \
    echo "Description: GNU Stow - A symlink farm manager" >> /tmp/stow-package/DEBIAN/control

# Build the Debian package
RUN dpkg-deb --build /tmp/stow-package /tmp/stow.deb

RUN mkdir -p /output

# Set the entry point
ENTRYPOINT ["/bin/cp", "/tmp/stow.deb", "/output"]

# docker build -t stow-builder .
# docker run --rm -v $(pwd):/output stow-builder
# sudo dpkg -i stow.deb
