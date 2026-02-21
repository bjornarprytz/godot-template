#!/usr/bin/env bash
# setup_jam.sh
# Prompt for ITCHIO_USERNAME, GAME_NAME, GODOT_VERSION and optionally create ~/.jam.config

set -euo pipefail
CONFIG="$HOME/.jam.config"

echo "Checking for existing config at $CONFIG..."
if [[ -f "$CONFIG" ]]; then
  echo "Found existing config:"
  grep -E '^(ITCHIO_USERNAME)=' "$CONFIG" || true
  read -rp "Overwrite existing config? [y/N]: " overwrite
  # load existing values as defaults
  # shellcheck disable=SC1090
  source "$CONFIG"
  if [[ "$overwrite" =~ ^[Yy]$ ]]; then
    echo "Existing config will be overwritten later if you confirm."
  else
    echo "Keeping existing config; ITCHIO_USERNAME will be used as default. The config file will not be modified unless you confirm later."
  fi
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
WRITE_CONFIG=true
if [[ "$confirm" =~ ^([Nn])$ ]]; then
  echo "Skipping writing $CONFIG; proceeding with README and project replacements."
  WRITE_CONFIG=false
fi

# write config only if requested
if [[ "$WRITE_CONFIG" == true ]]; then
  mkdir -p "$(dirname "$CONFIG")"
  {
    printf 'ITCHIO_USERNAME="%s"\n' "$ITCHIO_USERNAME_VAL"
  } > "$CONFIG"
  chmod 600 "$CONFIG"
  echo "Wrote $CONFIG (ITCHIO_USERNAME only)"
else
  echo "Did not write $CONFIG"
fi

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
        HOST="${BASH_REMATCH[1]}"
        GITHUB_USER="${BASH_REMATCH[2]}"
        GITHUB_REPO="${BASH_REMATCH[3]}"
      fi
      # strip trailing .git if present
      GITHUB_REPO="${GITHUB_REPO%.git}"
    fi
  fi

  # Use awk for safe literal in-place replacement (no backslash-escaping of hyphens)
  if command -v awk >/dev/null 2>&1; then
    # replace {jamName} and {itchioUsername}
    awk -v jam="$GAME_NAME_VAL" -v itchio="$ITCHIO_USERNAME_VAL" '{ gsub(/\{jamName\}/, jam); gsub(/\{itchioUsername\}/, itchio); print }' "$README_FILE" > "$README_FILE.tmp" && mv "$README_FILE.tmp" "$README_FILE"

    if [[ -n "$GITHUB_USER" ]]; then
      awk -v user="$GITHUB_USER" -v repo="$GITHUB_REPO" '{ gsub(/\{githubUsername\}/, user); gsub(/https:\/\/github.com\/\{githubUsername\}\/\{jamName\}/, "https://github.com/" user "/" repo); print }' "$README_FILE" > "$README_FILE.tmp" && mv "$README_FILE.tmp" "$README_FILE"
    fi
  else
    echo "awk not found; skipping placeholder replacement in $README_FILE"
  fi

  echo "Updated $README_FILE"
else
  echo "No readme.md found at $README_FILE; skipping update."
fi

# Replace placeholder tokens across project files (e.g. in workflows)
echo "Replacing ITCHIO_USERNAME, GAME_NAME and GODOT_VERSION across project files..."
if command -v grep >/dev/null 2>&1 && command -v awk >/dev/null 2>&1; then
  # find text files (ignore .git and scripts/) that contain any of the placeholder tokens
  mapfile -t FILES < <(grep -RIl --exclude-dir=.git --exclude-dir=scripts -e 'ITCHIO_USERNAME' -e 'GAME_NAME' -e 'GODOT_VERSION' . || true)
  for f in "${FILES[@]:-}"; do
    # skip README which we already handled
    if [[ "$(realpath "$f")" == "$(realpath "$README_FILE")" ]]; then
      continue
    fi
    # also skip any files under scripts/
    case "$f" in
      ./scripts/*|scripts/*)
        continue
        ;;
    esac
    # perform literal replacements; replace bracketed [TOKEN], "TOKEN" and 'TOKEN' forms only
    awk -v itchio="$ITCHIO_USERNAME_VAL" -v jam="$GAME_NAME_VAL" -v godot="$GODOT_VERSION_VAL" \
      '{ gsub(/\[ITCHIO_USERNAME\]/, itchio); gsub(/\[GAME_NAME\]/, jam); gsub(/\[GODOT_VERSION\]/, godot);
        gsub(/"ITCHIO_USERNAME"/, "\"" itchio "\""); gsub(/"GAME_NAME"/, "\"" jam "\""); gsub(/"GODOT_VERSION"/, "\"" godot "\"");
        sq = sprintf("%c",39);
        gsub(sq "ITCHIO_USERNAME" sq, sq itchio sq); gsub(sq "GAME_NAME" sq, sq jam sq); gsub(sq "GODOT_VERSION" sq, sq godot sq);
        print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    echo "Patched: $f"
  done
else
  echo "grep or awk not found; skipping project-wide token replacement."
fi
