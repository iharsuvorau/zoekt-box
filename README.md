# ZoektBox

A containerized, self-syncing, and Apple Silicon-optimized deployment of [Zoekt](https://github.com/sourcegraph/zoekt), the fast trigram-based code search engine.

This box is specifically designed to run on macOS using Apple's lightweight [container](https://github.com/apple/container) CLI tool, but it also includes a `compose.yml` for standard Docker or Podman environments.

## Features

- **Recursive Sync**: Automatically crawls your specified directory (default: `~/dev`) and indexes every Git repository it finds.
- **Apple Silicon Native**: Multi-stage OCI build optimized for the `container` CLI and macOS virtualization.
- **High-Quality Ranking**: Includes `universal-ctags` for symbol-aware search results.
- **Periodic Re-indexing**: Background indexer pulls latest changes and updates search indices on a configurable interval.
- **Opt-in Plain Folders**: Capability to index non-git directories.
- **Easy Management**: A single control script (`zoekt-ctl.sh`) to build, start, stop, and clean the stack.

## Requirements

- **Apple's `container` tool**: [github.com/apple/container](https://github.com/apple/container)
- **macOS 15+**: Required for the `container` virtualization features.
- **Apple Silicon Mac**: Optimized for M1/M2/M3 chips.

## Quick Start

1. **Clone and Setup**:
   ```bash
   git clone https://github.com/iharsuvorau/zoekt-box zoekt-box
   cd zoekt-box
   ```

2. **Build the Image**:
   ```bash
   ./zoekt-ctl.sh build
   ```

3. **Start the Stack**:
   By default, it will recursively index your `~/dev` folder.
   ```bash
   ./zoekt-ctl.sh up
   ```

4. **Search Your Code**:
   Access the web interface at: [http://localhost:6070](http://localhost:6070)

## Usage Reference

The `./zoekt-ctl.sh` script is the primary way to manage the box:

| Command | Description |
| :--- | :--- |
| `build` | Compiles Zoekt and builds the OCI image. |
| `up` | Starts the webserver and the background indexer. |
| `down` | Stops and removes the containers. |
| `logs` | View logs (use `logs idx` for the indexer logs). |
| `status` | Show running containers and their status. |
| `clean` | Reclaim disk space by pruning unused images/containers. |
| `restart` | Restarts both services. |

## Configuration

You can customize the behavior by setting environment variables before running `./zoekt-ctl.sh up`:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `REPOS_DIR` | Host path to search for repositories. | `~/dev` |
| `ZOEKT_INTERVAL` | Sync/re-index interval in seconds. | `3600` (1 hour) |
| `ZOEKT_INDEX_PLAIN_FOLDERS` | Set to `true` to index non-git folders. | `false` |

**Example (Custom Path & Interval):**
```bash
REPOS_DIR=/Volumes/Projects ZOEKT_INTERVAL=1800 ./zoekt-ctl.sh up
```

## Storage

- **Indices**: Stored locally in the `./index/` folder of this project.
- **Repositories**: Mounted read-only (for indexing) from your host machine.
