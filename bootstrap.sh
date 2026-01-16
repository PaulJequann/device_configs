#!/usr/bin/env bash
# Bootstrap script for fresh systems
# Installs Homebrew, go-task, and runs the setup

set -e

echo "=================================================="
echo "  Device Configs Bootstrap"
echo "=================================================="
echo ""

# 1. Install Homebrew if not present
if ! command -v brew &> /dev/null; then
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

# 2. Install go-task via Homebrew
if ! command -v task &> /dev/null; then
  echo "Installing go-task..."
  brew install go-task
  echo "✓ go-task installed"
else
  echo "✓ go-task already installed"
fi

# 3. Run task setup
echo ""
echo "Running setup..."
echo ""
task setup
