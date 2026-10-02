FROM mcr.microsoft.com/devcontainers/java:25
# Base image pulls in Yarn repo which we do not need and whose missing key breaks apt.
RUN rm -f /etc/apt/sources.list.d/yarn.list
RUN apt-get update -y && apt-get install -y \
    xz-utils \
    iputils-ping \
    telnet \
    gcc \
    g++ \
    make \
    libc-dev \
    cmake \
    bash \
    git \
    build-essential \
    dos2unix \
    libpcap-dev \
    patchelf \
    net-tools \
    tcpdump \
    wget \
    netcat-openbsd \
    ca-certificates \
    glab \
    python3 \
    python3-pip \
    python3-yaml \
    yq \
    yamllint \
    ruby-full \
    tmux \
    openjdk-25-jdk \
    tshark

# Install Node.js 22 + Yarn (via corepack) + Chromium for frontend tests
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs chromium && \
    ln -sf /usr/bin/chromium /usr/bin/chromium-browser && \
    corepack enable && \
    corepack prepare yarn@stable --activate

ENV CHROME_BIN=/usr/bin/chromium-browser
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Install md-to-pdf globally (uses system Chromium via PUPPETEER_EXECUTABLE_PATH)
RUN npm install -g md-to-pdf

# Add vscode user to docker group for Docker socket access
RUN groupadd -f docker && usermod -aG docker vscode

# Install latest Docker Compose (standalone)
RUN LATEST_COMPOSE_VERSION=$(wget -qO- "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" && \
    chmod +x /usr/local/bin/docker-compose

# Install Claude AI CLI as vscode user (so binary lands in /home/vscode/.local/bin/)
USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash
USER root



ENV TZ=Europe/Warsaw
WORKDIR /workspace
