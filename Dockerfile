FROM mcr.microsoft.com/devcontainers/java:25
# Base image pulls in Yarn repo which we do not need and whose missing key breaks apt.
RUN rm -f /etc/apt/sources.list.d/yarn.list

# Shared tools used by VPS development containers: PostgreSQL client, inbound SSH,
# cron, Neovim, and terminal Markdown rendering.
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    openssh-server \
    cron \
    util-linux \
    neovim \
    glow \
    && rm -rf /var/lib/apt/lists/*

# gRPC reflection CLI used by test and diagnostics scripts.
ARG GRPCURL_VERSION=1.9.3
RUN curl -fsSL "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz" \
      | tar -xz -C /usr/local/bin grpcurl \
 && chmod a+rx /usr/local/bin/grpcurl \
 && grpcurl -version

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

# Codex CLI for local developer sessions in the Dev Container.
ARG CODEX_CLI_VERSION=latest
RUN npm install -g "@openai/codex@${CODEX_CLI_VERSION}" && \
    codex --version

# Keep both agent CLIs current in containers that run cron.
COPY scripts/update-devcontainer-cli-tools.sh /usr/local/sbin/update-devcontainer-cli-tools
COPY cron/devcontainer-cli-updates /etc/cron.d/devcontainer-cli-updates
RUN chmod 0755 /usr/local/sbin/update-devcontainer-cli-tools \
    && chmod 0644 /etc/cron.d/devcontainer-cli-updates \
    && touch /var/log/devcontainer-cli-updates.log

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
