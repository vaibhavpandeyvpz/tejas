FROM ubuntu:noble

# Install all build dependencies
RUN apt update && \
    apt install -y --no-install-recommends \
    apt-utils \
    debootstrap \
    mtools \
    rsync \
    squashfs-tools \
    sudo \
    xorriso \
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
