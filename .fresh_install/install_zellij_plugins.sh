#!/bin/bash
# Install zellij plugins (zjstatus)

set -eo pipefail

PLUGIN_DIR="$HOME/.config/zellij/plugins"
mkdir -p "$PLUGIN_DIR"

echo "Installing zjstatus..."
curl -sL "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" \
  -o "$PLUGIN_DIR/zjstatus.wasm"

echo "zjstatus installed to $PLUGIN_DIR/zjstatus.wasm"
