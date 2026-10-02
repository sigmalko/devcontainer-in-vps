# devcontainer-in-vps

Base devcontainer image (`mcr.microsoft.com/devcontainers/java:25`) with JDK 25,
Node.js 22 + Yarn, Chromium, Python 3, Ruby, Docker Compose, network tools
(tcpdump, tshark), `glab`, `md-to-pdf`, the Claude and Codex CLIs, PostgreSQL
client, SSH server, cron, Neovim, `glow`, and `grpcurl`. The image is built from
the [`Dockerfile`](Dockerfile) and published to the GitHub Container Registry.

When the container's cron daemon is running, `/etc/cron.d/devcontainer-cli-updates`
updates Claude Code and Codex daily at 04:00 in the system timezone. The job logs to
`/var/log/devcontainer-cli-updates.log`; Claude is updated as `vscode`, while the
global Codex installation is updated as root. The consuming devcontainer must
start the cron daemon for the schedule to run.

## Pull the image

```bash
docker pull ghcr.io/sigmalko/devcontainer-in-vps:latest
```

Use it in `.devcontainer/Dockerfile`:

```dockerfile
FROM ghcr.io/sigmalko/devcontainer-in-vps:latest
```

Tags:

- `<MAJOR>.<BUILD>` — versioned build in the `01.001` format (two digits, dot, three digits). `MAJOR` is `VERSION_MAJOR` in the workflow, `BUILD` is the workflow run number.
- `latest` — the most recent build from `main`.
- `sha-<commit>` — build for a specific commit.

## Build and publish

The workflow [`.github/workflows/publish-image.yaml`](.github/workflows/publish-image.yaml)
builds the image on every pull request (without pushing) and publishes it on pushes to
`main` that change the `Dockerfile` or the workflow, and on manual `workflow_dispatch`.
It authenticates with the built-in `GITHUB_TOKEN`; no extra secrets are needed.

After the first publish, open the package page (Packages → `devcontainer-in-vps`) and
set its visibility to **Public** if it should be pullable without authentication.

Manual publish from a workstation:

```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u <user> --password-stdin
./build-and-push.sh 01.001
```
