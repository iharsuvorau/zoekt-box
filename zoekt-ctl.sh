#!/bin/bash
# zoekt-ctl.sh - Wrapper for Apple's 'container' CLI to manage ZoektBox.

# Configuration
IMAGE_NAME="zoekt-box"
WEB_CONTAINER="zoekt-webserver"
IDX_CONTAINER="zoekt-indexer"
WEB_PORT="6070"

# Host paths
BASE_DIR="$(pwd)"
INDEX_DIR="${BASE_DIR}/index"
# Default to ~/dev as requested
REPOS_DIR="${REPOS_DIR:-$HOME/dev}"
# Opt-in for plain folders (default false)
ZOEKT_INDEX_PLAIN_FOLDERS="${ZOEKT_INDEX_PLAIN_FOLDERS:-false}"

# Ensure directories exist
mkdir -p "$INDEX_DIR"
if [ ! -d "$REPOS_DIR" ]; then
    echo "Warning: REPOS_DIR ($REPOS_DIR) does not exist."
fi

usage() {
    echo "Usage: $0 {build|up|down|logs|status|restart|clean}"
    echo "  build   : Build the Zoekt image"
    echo "  up      : Create volumes and start the Zoekt stack"
    echo "  down    : Stop and remove the Zoekt stack"
    echo "  logs    : View logs (defaults to webserver, use 'logs idx' for indexer)"
    echo "  status  : List running containers"
    echo "  restart : Restart the stack"
    echo "  clean   : Reclaim disk space by pruning unused containers, images, and volumes"
    echo ""
    echo "Environment Variables:"
    echo "  REPOS_DIR                 : Path to repositories (default: $HOME/dev)"
    echo "  ZOEKT_INTERVAL            : Sync interval in seconds (default: 3600)"
    echo "  ZOEKT_INDEX_PLAIN_FOLDERS : Set to 'true' to index non-git folders (default: false)"
    exit 1
}

case "$1" in
    build)
        echo "Building image: $IMAGE_NAME"
        container build -t "$IMAGE_NAME" .
        ;;

    up)
        echo "Starting Zoekt Stack..."
        echo "  - Repositories: $REPOS_DIR"
        echo "  - Index: $INDEX_DIR"
        echo "  - Plain Folders: $ZOEKT_INDEX_PLAIN_FOLDERS"

        # 1. Start Webserver
        echo "  -> Starting Webserver on port $WEB_PORT"
        container run -d --name "$WEB_CONTAINER" \
            -p "$WEB_PORT:6070" \
            -v "$INDEX_DIR:/data/index" \
            "$IMAGE_NAME" \
            zoekt-webserver -index /data/index -listen :6070
        
        # 2. Start Indexer
        echo "  -> Starting Indexer (Sync Interval: ${ZOEKT_INTERVAL:-3600}s)"
        container run -d --name "$IDX_CONTAINER" \
            -v "$INDEX_DIR:/data/index" \
            -v "$REPOS_DIR:/data/repos" \
            -e "ZOEKT_INTERVAL=${ZOEKT_INTERVAL:-3600}" \
            -e "ZOEKT_INDEX_PLAIN_FOLDERS=$ZOEKT_INDEX_PLAIN_FOLDERS" \
            "$IMAGE_NAME" \
            /usr/local/bin/indexer.sh
        
        echo "Zoekt is up! Access the search UI at http://localhost:$WEB_PORT"
        ;;

    down)
        echo "Stopping and removing Zoekt Stack..."
        container stop "$WEB_CONTAINER" "$IDX_CONTAINER" 2>/dev/null
        container delete "$WEB_CONTAINER" "$IDX_CONTAINER" 2>/dev/null
        echo "Done."
        ;;

    logs)
        target="$2"
        if [ "$target" == "idx" ] || [ "$target" == "indexer" ]; then
            container logs -f "$IDX_CONTAINER"
        else
            container logs -f "$WEB_CONTAINER"
        fi
        ;;

    status)
        container list --all
        ;;

    restart)
        "$0" down
        "$0" up
        ;;

    clean)
        echo "Reclaiming disk space..."
        echo "  -> Pruning stopped containers"
        container prune
        echo "  -> Pruning unused images"
        container image prune -a
        echo "  -> Pruning unused volumes"
        container volume prune
        echo "Final disk usage:"
        container system df
        ;;

    *)
        usage
        ;;
esac
