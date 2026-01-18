# My Device Configuration

Personal system configuration using [Homebrew](https://brew.sh) and [Task](https://taskfile.dev) for my macOS, Windows (WSL2), and Arch Linux machines.

> If this helps you configure your own systems, feel free to fork and adapt it.

## Supported Platforms

- **macOS** - Homebrew for everything
- **Windows 11 + WSL2** - Homebrew for CLI, winget for Windows GUI apps
- **Arch Linux** - Native `pacman` and `yay` for CLI and GUI tools plus an automatic Homebrew install for the cross-platform bits

## Quick Start

```bash
# Clone this repo
git clone git@github.com:PaulJequann/device_configs.git ~/.config/device_configs
cd ~/.config/device_configs

# Run bootstrap (installs Homebrew + Task + runs setup)
./bootstrap.sh
```

That's it! The bootstrap script handles everything for a fresh system.

Bootstrap now retries the Homebrew installer once on failure and creates `~/bin/task`, so `task` always points to the `go-task` binary.

## Commands

```bash
task --list          # Show all available tasks
task detect          # Show current platform
task setup           # Full setup for current platform
task packages        # Install CLI tools via Homebrew
task terminal        # Setup zsh and plugins
task dotfiles        # Clone and stow dotfiles
task ssh             # Generate SSH key for this device
task gui             # Install GUI applications
task sync            # Pull latest configs and install new packages
task update          # Update all Homebrew packages
task clean           # Clean package caches
task check           # Check system status
```

## What Gets Installed

### CLI Tools

**All platforms (Homebrew by default, pacman/AUR on Arch):**

```
git stow zsh neovim tmux fzf ripgrep fd bat eza zoxide bun go-task gemini-cli
```

### AI Coding Tools

| Tool        | macOS     | WSL/Windows | Arch       |
| ----------- | --------- | ----------- | ---------- |
| Claude Code | brew cask | winget      | pacman     |
| OpenCode    | curl      | curl        | curl       |
| Gemini CLI  | brew      | brew        | pacman     |
| Antigravity | brew cask | winget      | AUR        |
| Cursor      | brew cask | winget      | AUR        |
| Zed         | brew cask | winget      | AUR        |
| Beads (bd)  | brew tap  | brew tap    | brew tap\* |
| Codexbar    | brew tap  | brew tap    | brew tap\* |

_Homebrew installs automatically on Arch to manage the `arch_brew_cli_tools` (e.g., `beads_viewer`), while `pacman`/`yay` still drive the rest of the stack._

### GUI Apps

**macOS** (brew cask):

- Claude Code, Antigravity, Cursor, VS Code, Zed
- Alacritty, Discord, Chrome, Edge
- Ollama, Bruno, Docker

**Windows** (winget import):

```powershell
# From PowerShell on Windows host
winget import -i "\\wsl.localhost\Ubuntu\home\YOUR_USERNAME\.config\device_configs\configs\winget-packages.json" --accept-package-agreements --accept-source-agreements
```

Includes: Windows Terminal, VS Code, Chrome, Edge, Discord, Docker Desktop, Claude Code, Antigravity, Cursor, Zed, Ollama, Bruno, Alacritty, Steam, GeForce Now, Moonlight

**Arch** (pacman + AUR via yay):

- Google Chrome, Microsoft Edge, Cursor, VS Code, Discord, Antigravity (AUR)
- Ghostty, Alacritty, Ollama (pacman)

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

- Homebrew installs automatically via bootstrap.sh
- All apps install via Homebrew or Homebrew Cask
- Docker Desktop via cask

### Windows 11 + WSL2

- Homebrew on Linux (WSL2) for CLI tools
- Windows GUI apps via winget import
- Docker Desktop on Windows with WSL2 integration
- Use `task gui` to get the winget import command with full path

### Arch Linux

- Native `pacman` and `yay` (AUR) are used for CLI and GUI tools by default, and bootstrap now also installs Homebrew so the `arch_brew_cli_tools` list (like `beads_viewer`) stays in sync with macOS/WSL.
- Homebrew install runs automatically (one retry) and `~/bin/task` is symlinked to the `go-task` binary so the `task` command works exactly like on other platforms.
- `yay` (AUR helper) is installed automatically if not present.
- Docker service configured via systemd.
- Log out/in after setup for Docker group membership.

## Structure

```
.
├── bootstrap.sh                  # Fresh system bootstrap
├── Taskfile.yml                  # Main orchestrator
├── .taskfiles/                   # Platform-specific tasks
│   ├── common.yml               # Shared tasks (packages, terminal, dotfiles)
│   ├── macos.yml                # macOS setup
│   ├── wsl.yml                  # WSL2 setup
│   ├── arch.yml                 # Arch setup (Docker systemd, yay)
│   └── linux.yml                # Generic Linux fallback
├── configs/
│   ├── packages.yml             # Package list documentation
│   └── winget-packages.json     # Windows apps for winget import
└── README.md                     # This file
```

## Migration from Curl-Based Setup

If you previously installed tools via curl, use the migration script to move them under Homebrew management:

```bash
./migrate-to-brew.sh
```

This script:

- Detects curl-based installations of: `bd`, `beads_viewer`, `bun`, `uv`, `opencode`
- Uninstalls them (with confirmation)
- Reinstalls via Homebrew
- Verifies each tool works
- Optionally cleans up old directories (`~/.bun`, `~/.uv`, etc.)

## Syncing Changes

When you add new tools to this repo and want to update other machines:

```bash
task sync
```

This will:

1. Pull latest device_configs
2. Pull latest dotfiles
3. Re-run dotfiles bootstrap
4. Install any new packages
