#!/usr/bin/env bash
# setup_jam.sh
# Prompt for ITCHIO_USERNAME, GAME_NAME, GODOT_VERSION and optionally create ~/.jam.config

set -euo pipefail
CONFIG="$HOME/.jam.config"

echo "Checking for existing config at $CONFIG..."
if [[ -f "$CONFIG" ]]; then
  echo "Found existing config:"
  grep -E '^(ITCHIO_USERNAME|GAME_NAME|GODOT_VERSION)=' "$CONFIG" || true
  read -rp "Overwrite existing config? [y/N]: " overwrite
  if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
    echo "Keeping existing config. To view it: cat $CONFIG"
    exit 0
  fi
  # load existing values as defaults
  # shellcheck disable=SC1090
  source "$CONFIG"
else
  echo "No existing config found."
fi

# helper to prompt with optional default
prompt() {
  local key="$1" defaultVal="$2" reply
  if [[ -n "$defaultVal" ]]; then
    read -rp "$key [$defaultVal]: " reply
    reply="${reply:-$defaultVal}"
  else
    read -rp "$key: " reply
  fi
  echo "$reply"
}

ITCHIO_USERNAME_DEFAULT="${ITCHIO_USERNAME:-}"
GAME_NAME_DEFAULT="${GAME_NAME:-}"
GODOT_VERSION_DEFAULT="${GODOT_VERSION:-}"

# If `godot` is available locally, try to detect its version and offer it as the default
if command -v godot >/dev/null 2>&1; then
  GODOT_RAW=$(godot -v 2>&1 | head -n1 || true)
  # extract version like 3.5.1 or 4.0.3 (handles v prefix)
  DETECTED_VERSION=$(echo "${GODOT_RAW}" | grep -oP 'v\K[0-9]+(\.[0-9]+){1,2}(-[a-z0-9]+)?' || true)
  if [[ -n "${DETECTED_VERSION}" ]]; then
    echo "Detected Godot: ${GODOT_RAW}"
    read -rp "Use detected Godot version '${DETECTED_VERSION}'? [Y/n]: " use_detected
    if [[ -z "${use_detected}" || "${use_detected}" =~ ^[Yy]$ ]]; then
      GODOT_VERSION_DEFAULT="${DETECTED_VERSION}"
    fi
  fi
fi

ITCHIO_USERNAME_VAL=$(prompt "Enter your itch.io username" "$ITCHIO_USERNAME_DEFAULT")
GAME_NAME_VAL=$(prompt "Enter your game name (project slug)" "$GAME_NAME_DEFAULT")
GODOT_VERSION_VAL=$(prompt "Enter Godot version (e.g. 3.5.1-stable, 4.0.3, etc.)" "$GODOT_VERSION_DEFAULT")

cat <<EOF

Summary:
  ITCHIO_USERNAME: $ITCHIO_USERNAME_VAL
  GAME_NAME:       $GAME_NAME_VAL
  GODOT_VERSION:   $GODOT_VERSION_VAL
EOF

read -rp "Create/overwrite $CONFIG with these values? [Y/n]: " confirm
if [[ "$confirm" =~ ^([Nn])$ ]]; then
  echo "Aborted. No changes made."
  exit 0
fi

# write config
mkdir -p "$(dirname "$CONFIG")"
{
  printf 'ITCHIO_USERNAME="%s"\n' "$ITCHIO_USERNAME_VAL"
  printf 'GAME_NAME="%s"\n' "$GAME_NAME_VAL"
  printf 'GODOT_VERSION="%s"\n' "$GODOT_VERSION_VAL"
} > "$CONFIG"
chmod 600 "$CONFIG"

echo "Wrote $CONFIG"

echo "To use these values in your shell run: source $CONFIG"

echo "CI note: This file is intended for local developer convenience. Your GitHub Actions workflows still need secrets configured in the repository settings (e.g. BUTLER_API_KEY)."

# Update readme.md placeholders if present
README_FILE="$(pwd)/readme.md"
if [[ -f "$README_FILE" ]]; then
  echo "Updating $README_FILE with provided values..."

  # try to derive GitHub user/repo from git remote
  GITHUB_USER=""
  GITHUB_REPO=""
  if command -v git >/dev/null 2>&1; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$REMOTE_URL" ]]; then
      if [[ "$REMOTE_URL" =~ ^git@github.com:([^/]+)/([^/]+)(\.git)?$ ]]; then
        GITHUB_USER="${BASH_REMATCH[1]}"
        GITHUB_REPO="${BASH_REMATCH[2]}"
      elif [[ "$REMOTE_URL" =~ ^https?://([^/]+)/([^/]+)/([^/]+)(\.git)?$ ]]; then
        # e.g. https://github.com/user/repo.git or https://git.example.com/user/repo
        HOST="${BASH_REMATCH[1]}"
        GITHUB_USER="${BASH_REMATCH[2]}"
        GITHUB_REPO="${BASH_REMATCH[3]}"
      fi
      # strip trailing .git if present
      GITHUB_REPO="${GITHUB_REPO%.git}"
    fi
  fi

  # Use perl for safe in-place replacement handling special characters
  if command -v perl >/dev/null 2>&1; then
    perl -0777 -pe "s/\{jamName\}/\Q$GAME_NAME_VAL\E/g; s/\{itchioUsername\}/\Q$ITCHIO_USERNAME_VAL\E/g;" -i "$README_FILE"
    if [[ -n "$GITHUB_USER" ]]; then
      perl -0777 -pe "s/\{githubUsername\}/\Q$GITHUB_USER\E/g;" -i "$README_FILE"
      # also replace full repo link if present
      perl -0777 -pe "s#https://github.com/\{githubUsername\}/\{jamName\}#https://github.com/$GITHUB_USER/$GITHUB_REPO#g;" -i "$README_FILE"
    fi
  else
    echo "perl not found; skipping placeholder replacement in $README_FILE"
  fi

  echo "Updated $README_FILE"
else
  echo "No readme.md found at $README_FILE; skipping update."
fi
