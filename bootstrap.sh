#!/usr/bin/env bash
# Bootstrap script for fresh systems
# Installs Homebrew, go-task, and runs the setup

set -e

echo "=================================================="
echo "  Device Configs Bootstrap"
echo "=================================================="
echo ""

# 0. Detect Arch Linux and check if we should skip Homebrew
IS_ARCH=false
if [ -f /etc/arch-release ]; then
  IS_ARCH=true
fi

USE_BREW_ON_LINUX=${DEVICE_CONFIGS_USE_BREW_ON_LINUX:-0}

# 1. Install Homebrew if not present (skipped on Arch unless forced)
if [ "$IS_ARCH" = true ] && [ "$USE_BREW_ON_LINUX" -eq 0 ]; then
  echo "Arch Linux detected. Skipping Homebrew installation (use DEVICE_CONFIGS_USE_BREW_ON_LINUX=1 to force)."
elif ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Configure PATH for current session
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    # Add to shell profile for future sessions
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
    if [ -f ~/.zshrc ]; then
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $(uname -m) == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  echo "✓ Homebrew installed"
else
  echo "✓ Homebrew already installed"
fi

# 2. Install go-task
if ! command -v task &> /dev/null; then
  echo "Installing go-task..."
  if [ "$IS_ARCH" = true ] && [ "$USE_BREW_ON_LINUX" -eq 0 ]; then
    sudo pacman -S --needed --noconfirm go-task
  else
    brew install go-task
  fi
  echo "✓ go-task installed"
else
  echo "✓ go-task already installed"
fi

# 3. Run task setup
echo ""
echo "Running setup..."
echo ""
task setup
