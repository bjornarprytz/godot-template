#!/usr/bin/env bash
# scripts/new_game.sh
# Create a new GitHub repository from this template using the GitHub CLI (gh)

set -euo pipefail

# helper prompt
prompt() {
  local msg="$1" defaultVal="${2:-}" reply
  if [[ -n "$defaultVal" ]]; then
    read -rp "$msg [$defaultVal]: " reply
    reply="${reply:-$defaultVal}"
  else
    read -rp "$msg: " reply
  fi
  echo "$reply"
}

if ! command -v gh >/dev/null 2>&1; then
  echo "gh (GitHub CLI) is required. Install from https://cli.github.com/"
  exit 1
fi

# ensure git is available for detecting template remote
if ! command -v git >/dev/null 2>&1; then
  echo "git is required."
  exit 1
fi

# Try to get authenticated GitHub username
GH_USER=""
GH_USER=$(gh api user --jq .login 2>/dev/null || true)
if [[ -z "$GH_USER" ]]; then
  echo "Not authenticated with GitHub CLI. Running 'gh auth login'..."
  gh auth login || true
  GH_USER=$(gh api user --jq .login 2>/dev/null || true)
fi
if [[ -z "$GH_USER" ]]; then
  echo "Could not determine GitHub user after authentication. Aborting."
  exit 1
fi

# Try to determine this template repo (owner/repo) from git remote origin
TEMPLATE_REPO=""
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
if [[ -n "$REMOTE_URL" ]]; then
  if [[ "$REMOTE_URL" =~ ^git@github.com:([^/]+)/([^/]+)(\.git)?$ ]]; then
    TEMPLATE_REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  elif [[ "$REMOTE_URL" =~ ^https?://[^/]+/([^/]+)/([^/]+)(\.git)?$ ]]; then
    TEMPLATE_REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  fi
fi

# helper to sanitize template repo input (strip .git or convert URLs to owner/repo)
sanitize_repo() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo ""
    return
  fi
  if [[ "$input" =~ ^git@github.com:([^/]+)/([^/]+)(\.git)?$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return
  fi
  if [[ "$input" =~ ^https?://[^/]+/([^/]+)/([^/]+)(\.git)?$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return
  fi
  # strip trailing .git if present
  echo "${input%.git}"
}

# sanitize any detected TEMPLATE_REPO
TEMPLATE_REPO=$(sanitize_repo "$TEMPLATE_REPO")

# Fallback template (this repo) if detection failed
if [[ -z "$TEMPLATE_REPO" ]]; then
  TEMPLATE_REPO="${GH_USER}/godot-template"
fi

# Default new repo name: sanitized current directory name
DEFAULT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')
DEFAULT_NAME="${DEFAULT_NAME:-my-game}"

GAME_NAME=$(prompt "New repository name (slug)" "$DEFAULT_NAME")
# sanitize input
GAME_NAME=$(echo "$GAME_NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')

VISIBILITY=$(prompt "Visibility (public/private)" "public")
if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
  echo "Invalid visibility: $VISIBILITY"
  exit 1
fi

# Confirm template repo
TEMPLATE_REPO_INPUT=$(prompt "Template repository (owner/repo)" "$TEMPLATE_REPO")
if [[ -n "$TEMPLATE_REPO_INPUT" ]]; then
  # sanitize user input (accept URLs or owner/repo, strip .git)
  SANITIZED=$(sanitize_repo "$TEMPLATE_REPO_INPUT")
  if [[ -n "$SANITIZED" ]]; then
    TEMPLATE_REPO="$SANITIZED"
  fi
fi

echo "About to create: $GH_USER/$GAME_NAME from template $TEMPLATE_REPO ($VISIBILITY)"
read -rp "Continue? [Y/n]: " cont
if [[ -n "$cont" && ! "$cont" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Create repo from template and clone into current directory's parent
# Use --private if requested
CREATE_FLAGS=(--template "$TEMPLATE_REPO" --clone)
if [[ "$VISIBILITY" == "private" ]]; then
  CREATE_FLAGS+=(--private)
else
  CREATE_FLAGS+=(--public)
fi

# Run gh repo create
# Clone into the parent directory so the new repo appears as a sibling to this template
PARENT_DIR=$(dirname "$(pwd)")
echo "Creating and cloning into sibling directory: $PARENT_DIR/$GAME_NAME"
pushd "$PARENT_DIR" >/dev/null
set -x
gh repo create "$GH_USER/$GAME_NAME" "${CREATE_FLAGS[@]}"
set +x
popd >/dev/null

CLONE_DIR="$PARENT_DIR/$GAME_NAME"
if [[ -d "$CLONE_DIR" ]]; then
  echo "Repository created and cloned to $CLONE_DIR"
  if [[ -f "$CLONE_DIR/scripts/setup_jam.sh" ]]; then
    echo "Running setup_jam.sh in cloned repo..."
    chmod +x "$CLONE_DIR/scripts/setup_jam.sh" || true
    (cd "$CLONE_DIR" && ./scripts/setup_jam.sh)
  else
    echo "No setup_jam.sh in cloned repo; skipping."
  fi

  # Open in VS Code if available
  if command -v code >/dev/null 2>&1; then
    echo "Opening project in VS Code..."
    (cd "$CLONE_DIR" && code .) || true
  else
    echo "VS Code 'code' CLI not found; skipping opening in editor."
  fi

  # Start Godot editor pointed at the cloned repo's src directory (backgrounded)
  if command -v godot >/dev/null 2>&1; then
    if [[ -d "$CLONE_DIR/src" ]]; then
      echo "Starting Godot editor for project (src)..."
      nohup bash -c "cd \"$CLONE_DIR/src\" && godot -e ." >/dev/null 2>&1 &
    else
      echo "No src/ directory in cloned repo; starting Godot in repo root instead..."
      nohup bash -c "cd \"$CLONE_DIR\" && godot -e ." >/dev/null 2>&1 &
    fi
  else
    echo "Godot CLI not found; skipping starting Godot."
  fi

else
  echo "Clone directory not found: $CLONE_DIR"
fi

echo "Next steps: cd $CLONE_DIR && git remote -v"