#!/bin/bash
set -euo pipefail

# Only run in remote Claude Code environment
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Pinned SDK version — the single source of truth, also read by CI
FLUTTER_VERSION="$(tr -d '[:space:]' < "$CLAUDE_PROJECT_DIR/.flutter-version")"

# Version-named so bumping the pin installs fresh instead of reusing a stale SDK
FLUTTER_INSTALL_DIR="/opt/flutter-$FLUTTER_VERSION"

if [ ! -x "$FLUTTER_INSTALL_DIR/bin/flutter" ]; then
  echo "Installing Flutter SDK $FLUTTER_VERSION..."
  GIT_TERMINAL_PROMPT=0 git clone https://github.com/flutter/flutter.git \
    -b "$FLUTTER_VERSION" \
    --depth 1 \
    "$FLUTTER_INSTALL_DIR"
fi

# Add Flutter to PATH for this session
export PATH="$FLUTTER_INSTALL_DIR/bin:$PATH"
echo "export PATH=\"$FLUTTER_INSTALL_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"

# Bootstrap Flutter — downloads Dart SDK on first run
echo "Bootstrapping Flutter..."
flutter --version

# Install project dependencies
echo "Installing project dependencies..."
cd "$CLAUDE_PROJECT_DIR/enfr"
flutter pub get

echo "Flutter setup complete!"

# Fix Chrome symlink for Playwright MCP
# The MCP server expects Chrome at /opt/google/chrome/chrome but the binary lives elsewhere
mkdir -p /opt/google/chrome
ln -sf /opt/pw-browsers/chromium-1194/chrome-linux/chrome /opt/google/chrome/chrome
echo "Playwright Chrome symlink set."
