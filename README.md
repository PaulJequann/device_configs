# My Device Configuration

Personal system configuration using [Task](https://taskfile.dev) for my macOS, Windows (WSL2), and Arch Linux machines.

> If this helps you configure your own systems, feel free to fork and adapt it.

## Supported Platforms

- **macOS** - Homebrew-based setup
- **Windows 11 + WSL2** - apt for Linux side, winget for Windows GUI apps
- **Arch Linux** - pacman-based setup

## Installation

### Bootstrap

```bash
# Clone this repo
git clone git@github.com:PaulJequann/device_configs.git ~/.config/device_configs
cd ~/.config/device_configs

# Install Task
curl -fsSL https://taskfile.dev/install.sh | sh -s -- -d -b ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Or use native package managers:
# macOS: brew install go-task
# Arch: sudo pacman -S go-task
# Debian/Ubuntu: sudo sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# Run full setup
task setup
```

### What This Does

1. Detects platform (macOS/WSL/Arch)
2. Installs essential CLI tools
3. Sets up terminal (zsh, oh-my-zsh, zgenom)
4. Clones and stows dotfiles
5. Optionally installs GUI apps

## Commands

```bash
task --list          # Show all available tasks
task detect          # Show current platform
task setup           # Full setup for current platform
task packages        # Install CLI tools only
task terminal        # Setup zsh and plugins
task dotfiles        # Clone and stow dotfiles
task ssh             # Generate SSH key for this device
task gui             # Install GUI applications
task update          # Update all packages
task clean           # Clean package caches
task check           # Check system status
```

## What Gets Installed

### CLI Tools (all platforms)
- git, stow
- neovim, tmux, fzf
- ripgrep, fd, bat, eza, zoxide
- docker

### GUI Apps

**macOS**:
- Alacritty, Discord, Chrome, Edge

**Windows** (import via winget):
```powershell
# From PowerShell on Windows host
winget import -i \\wsl.localhost\Ubuntu\home\YOUR_USERNAME\.config\device_configs\configs\winget-packages.json --accept-package-agreements --accept-source-agreements
```
Includes: Windows Terminal, Chrome, Edge, Discord, Docker Desktop, VS Code, Alacritty, Steam, GeForce Now, Moonlight

**Arch**:
- Alacritty, Discord, Chromium
- Chrome/Edge via AUR (yay -S google-chrome microsoft-edge-stable-bin)

### What I Keep in Devcontainers

Everything project-specific stays in devcontainers:
- Language runtimes (Node, Python, etc.)
- Language servers
- Database tools
- Cloud CLIs (awscli, terraform)

## SSH Keys

Generate a unique SSH key per device:

```bash
task ssh
# Adds key to ~/.ssh/id_ed25519
# Copy the public key to GitHub/GitLab
```

## Dotfiles

Update the repo URL in [Taskfile.yml](Taskfile.yml):
```yaml
vars:
  DOTFILES_REPO: "git@github.com:PaulJequann/dotfiles.git"
```

Run `task dotfiles` to clone and stow.

## Platform Notes

### macOS
- Homebrew installs automatically
- Docker Desktop provides Docker runtime

### Windows 11 + WSL2
- Install Docker Desktop on Windows, enable WSL2 integration
- Use `task wsl:gui` to get the winget import command with full path
- Winget package list: [configs/winget-packages.json](configs/winget-packages.json)

### Arch Linux
- Docker service starts automatically
- Log out/in after setup for Docker group
- yay (AUR helper) installed automatically

## Structure

```
.
├── Taskfile.yml                  # Main orchestrator
├── .taskfiles/                   # Platform-specific tasks
│   ├── common.yml               # Shared tasks
│   ├── macos.yml                # macOS setup
│   ├── wsl.yml                  # WSL2 setup
│   ├── arch.yml                 # Arch setup
│   └── linux.yml                # Generic Linux fallback
├── configs/
│   └── winget-packages.json     # Windows apps for winget import
└── README.md                     # This file
```
