#!/usr/bin/env bash
set -euo pipefail

# Install foundry if not already installed
echo "Installing Foundry..."
if ! command -v foundryup >/dev/null 2>&1; then
  curl -L https://foundry.paradigm.xyz | bash
fi

# Ensure foundry binaries are in PATH
export PATH="$HOME/.foundry/bin:$PATH"

# Install or update the Foundry toolchain
foundryup
