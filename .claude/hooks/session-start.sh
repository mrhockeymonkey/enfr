#!/bin/bash
set -euo pipefail

# Only run in remote Claude Code environment
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_INSTALL_DIR="/opt/flutter"

# Install Flutter SDK if not already present
if [ ! -f "$FLUTTER_INSTALL_DIR/bin/flutter" ]; then
  echo "Installing Flutter SDK (stable)..."
  GIT_TERMINAL_PROMPT=0 git clone https://github.com/flutter/flutter.git \
    -b stable \
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
