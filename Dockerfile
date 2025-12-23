FROM ubuntu:noble

# Install all build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    grub-pc-bin \
    grub-common \
    shim-signed \
    casper \
    calamares \
    mtools \
    rsync \
    sudo \
    bash \
    grep \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Create a build user with sudo access (no password required)
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set working directory
WORKDIR /workspace

# Copy project files into the image
COPY --chown=builder:builder . /workspace

# Default to builder user
USER builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PROFILE=user

# Default command
CMD ["/bin/bash"]
