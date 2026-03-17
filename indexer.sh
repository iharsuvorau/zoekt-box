#!/bin/sh
# indexer.sh - Periodic Zoekt indexer script for containerized deployments.

ZOEKT_INTERVAL="${ZOEKT_INTERVAL:-3600}"
INDEX_DIR="${INDEX_DIR:-/data/index}"
REPOS_DIR="${REPOS_DIR:-/data/repos}"
ZOEKT_INDEX_PLAIN_FOLDERS="${ZOEKT_INDEX_PLAIN_FOLDERS:-false}"

mkdir -p "$INDEX_DIR"

while true; do
  echo "[$(date)] Starting indexing cycle..."
  
  if [ ! -d "$REPOS_DIR" ]; then
    echo "Error: $REPOS_DIR directory not found."
  else
    # 1. Recursively find and index all Git repositories
    echo "Scanning for Git repositories in $REPOS_DIR..."
    find "$REPOS_DIR" -name .git -type d -prune | while read -r gitdir; do
      repo=$(dirname "$gitdir")
      repo_name=$(basename "$repo")
      echo "Processing Git repository: $repo_name ($repo)"
      
      echo "  - Pulling updates..."
      git -C "$repo" pull --rebase || echo "  - Warning: Git pull failed for $repo_name."
      
      echo "  - Running zoekt-git-index..."
      zoekt-git-index -index "$INDEX_DIR" "$repo"
    done

    # 2. Opt-in: Index plain folders (non-git) at the top level of REPOS_DIR
    if [ "$ZOEKT_INDEX_PLAIN_FOLDERS" = "true" ]; then
      echo "Scanning for plain folders in $REPOS_DIR..."
      find "$REPOS_DIR" -maxdepth 1 -mindepth 1 -type d | while read -r dir; do
        if [ ! -d "$dir/.git" ]; then
          repo_name=$(basename "$dir")
          echo "Processing plain directory: $repo_name ($dir)"
          echo "  - Running zoekt-index..."
          zoekt-index -index "$INDEX_DIR" "$dir"
        fi
      done
    fi
  fi
  
  echo "[$(date)] Indexing cycle complete. Sleeping for $ZOEKT_INTERVAL seconds..."
  sleep "$ZOEKT_INTERVAL"
done
