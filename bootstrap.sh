#!/usr/bin/env bash
# Bootstrap script for fresh systems
# Installs Homebrew, go-task, and runs the setup

set -euo pipefail

echo "=================================================="
echo "  Device Configs Bootstrap"
echo "=================================================="
echo ""

# 0. Detect Arch Linux for informational purposes
IS_ARCH=false
if [ -f /etc/arch-release ]; then
  IS_ARCH=true
fi

append_line_if_missing() {
  local file="$1"
  local line="$2"
  if [ -z "$file" ] || [ -z "$line" ]; then
    return
  fi
  if [ ! -f "$file" ]; then
    printf '%s\n' "$line" >> "$file"
    return
  fi
  if ! grep -F -- "$line" "$file" >/dev/null 2>&1; then
    printf '%s\n' "$line" >> "$file"
  fi
}

configure_homebrew_env() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    append_line_if_missing "$HOME/.bashrc" 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    append_line_if_missing "$HOME/.zshrc" 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $(uname -m) == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

# 1. Install Homebrew if not present
if ! command -v brew &> /dev/null; then
  BREW_ATTEMPTS=0
  while true; do
    BREW_ATTEMPTS=$((BREW_ATTEMPTS + 1))
    echo "Installing Homebrew (attempt $BREW_ATTEMPTS)..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      configure_homebrew_env
      echo "✓ Homebrew installed"
      break
    fi
    if [ "$BREW_ATTEMPTS" -ge 2 ]; then
      echo "Homebrew installation failed after $BREW_ATTEMPTS attempts. Aborting."
      exit 1
    fi
    echo "⚠️ Homebrew install failed; retrying..."
  done
else
  configure_homebrew_env
  echo "✓ Homebrew already installed"
fi

# 2. Install go-task
if ! command -v go-task &> /dev/null; then
  echo "Installing go-task..."
  brew install go-task
  echo "✓ go-task installed"
else
  echo "✓ go-task already installed"
fi

ensure_local_bin_env() {
  mkdir -p "$HOME/bin"
  export PATH="$HOME/bin:$PATH"
  append_line_if_missing "$HOME/.bashrc" 'export PATH="$HOME/bin:$PATH"'
  append_line_if_missing "$HOME/.zshrc" 'export PATH="$HOME/bin:$PATH"'
}

ensure_local_bin_env
if command -v go-task &> /dev/null; then
  ln -sf "$(command -v go-task)" "$HOME/bin/task"
  echo "✓ task shim ready ($(command -v task))"
else
  echo "⚠️ go-task binary not found after installation"
fi

# 3. Run task setup
echo ""
echo "Running setup..."
echo ""
task setup
