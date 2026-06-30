---
name: apple-container
description: >-
  Operate Apple's `container` CLI to build, run, and manage Linux containers as
  lightweight VMs on macOS 26+ Apple silicon. Use when working with the
  `container` command, building OCI images from a Dockerfile on macOS,
  running/exec-ing/inspecting Linux containers via Apple's tool, or managing its
  images, builder, networks, volumes, registries, or the `container system`
  service. Not for Docker Desktop, the `docker` CLI, Podman, Kubernetes, or
  non-Apple container runtimes.
---

# Apple `container` CLI

Apple's `container` is a Swift CLI that creates and runs Linux containers as
lightweight virtual machines on Apple silicon, producing and consuming
OCI-compatible images that work with standard registries. Each container runs in
its own lightweight VM rather than sharing the host kernel.

## When to use

- The user runs the `container` command on macOS (build, run, exec, inspect, etc.).
- Building an OCI image from a Dockerfile with Apple's `container build`.
- Managing images, the BuildKit builder, networks, volumes, registries, or the
  `container system` service.

## When not to use

- Docker Desktop or the `docker` CLI, Podman, `nerdctl`, or Kubernetes.
- Container runtimes on Linux or Windows.

These are different tools; defer to the matching runtime instead.

## Prerequisites

- **macOS 26 or newer** on an **Apple silicon** Mac (required for the
  virtualization and networking features).
- Install the signed installer package from the GitHub releases page, then start
  the service:

```sh
container system start          # starts services, optionally installs a default kernel
container system status         # confirm services are healthy
container system version        # CLI and server version
```

- Optionally install/refresh the Linux kernel:

```sh
container system kernel set --recommended
```

## Core workflow

A typical build → run → inspect → cleanup cycle. The builder is a BuildKit
container that may need starting before the first `build`:

```sh
# Start the BuildKit builder (sized as needed)
container builder start --cpus 8 --memory 32g

# Build an OCI image from a Dockerfile in the current context
container build -t myapp:latest -f Dockerfile .
# Multi-arch: container build --arch arm64 --arch amd64 -t myapp:latest .

# Run it (detach, publish a port, mount a volume, set env)
container run --rm -it -p 8080:8080 myapp:latest
# Common flags: -d/--detach, -e/--env, -v/--volume, --cpus, --memory

# Observe
container ls --all
container logs --follow <id>
container exec -it <id> /bin/sh

# Stop and clean up
container stop <id>
container rm <id>
container prune                 # remove all stopped containers
```

## Command reference

Many groups expose `list`/`ls`, `delete`/`rm`, `prune`, and `inspect` aliases.

### Container lifecycle

| Command | Purpose |
|---------|---------|
| `container run` | Run a container from an image (`-i`, `-t`, `-d`, `-e`, `-p`, `-v`, `--cpus`, `--memory`) |
| `container create` | Create without starting (same flags as `run`) |
| `container start` | Boot a stopped container (`--attach`, `--interactive`) |
| `container stop` | Graceful stop via signal (default 5s timeout) |
| `container kill` | Immediate SIGKILL |
| `container delete` (`rm`) | Remove containers (`-f/--force` for running) |
| `container list` (`ls`) | List containers (`--all`, `--format`) |
| `container exec` | Run a command in a running container |
| `container logs` | Container output (`--follow`, `--boot` for boot logs) |
| `container inspect` | Detailed JSON info |
| `container stats` | Live resource usage (`--no-stream` for a snapshot) |
| `container export` | Export a stopped container's filesystem as a tar |
| `container copy` (`cp`) | Copy files between host and container |
| `container prune` | Remove stopped containers |

### Build & builder

| Command | Purpose |
|---------|---------|
| `container build` | Build an OCI image from a context (`-t`, `-f`, `--build-arg`, `--no-cache`, `--target`, `--arch`/`--platform`) |
| `container builder start` | Launch the BuildKit builder (`--cpus`, `--memory`) |
| `container builder status` | Check builder state |
| `container builder stop` | Halt the builder |
| `container builder delete` (`rm`) | Remove the builder (`-f` stops it first) |

### Images

`container image list` (`ls`), `pull` (`--platform`), `push`, `save`, `load`
(`--input`), `tag`, `delete` (`rm`, `-f`), `prune` (`-a`), `inspect`.

### Networks (macOS 26+)

`container network create` (`--subnet`, `--subnet-v6`, `--internal`), `delete`
(`rm`), `list` (`ls`), `prune`, `inspect`.

### Volumes

`container volume create` (`--opt journal=`), `delete` (`rm`), `list` (`ls`),
`prune`, `inspect`.

### Registries

`container registry login`, `logout`, `list` (credentials stored locally).

### System

`container system start` / `stop` / `status` / `version` / `logs` (`--last`) /
`df` / `dns` (`create` / `delete` / `list`) / `kernel set` (`--recommended`) /
`property list`.

## Notes & gotchas

- **VM-per-container isolation**: each container is its own lightweight VM, giving
  stronger isolation than shared-kernel runtimes.
- **Host DNS access** needs `sudo`:

  ```sh
  sudo container system dns create host.container.internal --localhost 203.0.113.113
  ```

- **Networking** (`container network ...`) requires macOS 26+.
- **First build** may fail until `container builder start` has been run.

## Source

Content is sourced from Apple's official repository (not from any third-party
article):

- Overview — https://github.com/apple/container
- Command reference — https://github.com/apple/container/blob/main/docs/command-reference.md
- How-to — https://github.com/apple/container/blob/main/docs/how-to.md
