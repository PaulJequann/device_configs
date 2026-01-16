#!/bin/bash

################################################################################
# migrate-to-brew.sh
# 
# A safe migration script that:
# - Detects curl-based installations of specific tools
# - Uninstalls them (with user confirmation)
# - Reinstalls via Homebrew
# - Verifies new installations
# - Cleans up old directories
#
# Supports: macOS and Linux (WSL/Arch)
# Safe: Asks for confirmation before any deletion
# Idempotent: Can run multiple times safely
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories to check for old installations
SEARCH_DIRS=(
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
    "$HOME/.uv/bin"
    "$HOME/.cargo/bin"
    "/usr/local/bin"
)

# Tool definitions: name, brew_formula, version_check_cmd
declare -A TOOLS=(
    [bd]="steveyegge/beads/bd|--version"
    [beads_viewer]="beads_viewer|--version"
    [bun]="oven-sh/bun/bun|--version"
    [uv]="uv|--version"
    [opencode]="opencode|--version"
)

# Tracking arrays
declare -a FOUND_TOOLS=()
declare -a MIGRATED_TOOLS=()
declare -a FAILED_TOOLS=()

################################################################################
# Helper Functions
################################################################################

# Print colored output
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Ask for user confirmation
confirm() {
    local prompt="$1"
    local response
    while true; do
        read -p "$prompt (y/n): " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            [nN][oO]|[nN]) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Find all instances of a tool
find_tool_instances() {
    local tool=$1
    local found_paths=()
    
    # Check each search directory
    for dir in "${SEARCH_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            if [[ -f "$dir/$tool" ]] || [[ -L "$dir/$tool" ]]; then
                found_paths+=("$dir/$tool")
            fi
        fi
    done
    
    # Check PATH for the tool
    if local tool_path=$(command -v "$tool" 2>/dev/null); then
        # Check if it's NOT a brew installation
        if [[ ! "$tool_path" =~ /opt/homebrew|/usr/local/Cellar ]]; then
            found_paths+=("$tool_path")
        fi
    fi
    
    printf '%s\n' "${found_paths[@]}" | sort -u
}

# Get the parent installation directory
get_install_dir() {
    local tool_path=$1
    
    # If it's a symlink, try to find the original directory
    if [[ -L "$tool_path" ]]; then
        local target=$(readlink -f "$tool_path")
        echo "$(dirname "$target")"
    else
        echo "$(dirname "$tool_path")"
    fi
}

################################################################################
# Detection Phase
################################################################################

detect_old_installations() {
    print_header "Detecting Old Curl-Based Installations"
    
    for tool in "${!TOOLS[@]}"; do
        local instances=$(find_tool_instances "$tool")
        
        if [[ -n "$instances" ]]; then
            print_warning "Found old installation(s) of '$tool':"
            while IFS= read -r path; do
                echo "  → $path"
                if [[ -L "$path" ]]; then
                    echo "    (symlink → $(readlink -f "$path"))"
                fi
            done <<< "$instances"
            FOUND_TOOLS+=("$tool")
        fi
    done
    
    if [[ ${#FOUND_TOOLS[@]} -eq 0 ]]; then
        print_success "No old curl-based installations found!"
        return 0
    fi
    
    echo ""
    echo "Found ${#FOUND_TOOLS[@]} tool(s) to migrate"
}

################################################################################
# Uninstallation Phase
################################################################################

uninstall_old_tool() {
    local tool=$1
    local instances
    instances=$(find_tool_instances "$tool")
    
    if [[ -z "$instances" ]]; then
        print_success "$tool: Not found (already removed)"
        return 0
    fi
    
    print_header "Removing old '$tool'"
    
    # Collect all paths and parent directories
    local -a paths_to_remove=()
    local -a dirs_to_clean=()
    
    while IFS= read -r path; do
        paths_to_remove+=("$path")
        dirs_to_clean+=($(get_install_dir "$path"))
    done <<< "$instances"
    
    # Show what will be removed
    echo "Paths to remove:"
    for path in "${paths_to_remove[@]}"; do
        echo "  • $path"
    done
    
    echo ""
    echo "Parent directories to clean:"
    for dir in $(printf '%s\n' "${dirs_to_clean[@]}" | sort -u); do
        if [[ -d "$dir" ]]; then
            echo "  • $dir"
        fi
    done
    
    if ! confirm "Remove these files?"; then
        print_warning "$tool: Skipped by user"
        return 1
    fi
    
    # Remove files
    for path in "${paths_to_remove[@]}"; do
        if rm -f "$path"; then
            print_success "Removed: $path"
        else
            print_error "Failed to remove: $path"
            return 1
        fi
    done
    
    return 0
}

################################################################################
# Installation Phase
################################################################################

install_via_brew() {
    local tool=$1
    local formula=$2
    local version_cmd=$3
    
    print_header "Installing '$tool' via Homebrew"
    
    # Check if brew is installed
    if ! command_exists brew; then
        print_error "Homebrew not found. Please install Homebrew first."
        print_error "Visit: https://brew.sh"
        return 1
    fi
    
    # Install the tool
    echo "Running: brew install $formula"
    if brew install "$formula"; then
        print_success "Successfully installed $tool"
    else
        print_error "Failed to install $tool"
        return 1
    fi
    
    # Verify installation
    sleep 1
    if command_exists "$tool"; then
        if [[ -n "$version_cmd" ]]; then
            echo "Verifying installation:"
            if $tool $version_cmd; then
                print_success "$tool is working correctly"
                return 0
            else
                print_error "$tool installed but version check failed"
                return 1
            fi
        else
            print_success "$tool is installed"
            return 0
        fi
    else
        print_error "Tool not found after installation"
        return 1
    fi
}

################################################################################
# Cleanup Phase
################################################################################

cleanup_directories() {
    local tool=$1
    
    local instances
    instances=$(find_tool_instances "$tool")
    
    # If no old instances remain, suggest directory cleanup
    if [[ -z "$instances" ]]; then
        local -a dirs_to_check=(
            "$HOME/.bun"
            "$HOME/.uv"
        )
        
        for dir in "${dirs_to_check[@]}"; do
            if [[ -d "$dir" ]] && [[ -z "$(find "$dir" -type f 2>/dev/null)" ]]; then
                if confirm "Remove empty directory $dir?"; then
                    if rm -rf "$dir"; then
                        print_success "Removed directory: $dir"
                    else
                        print_warning "Could not remove: $dir (requires sudo?)"
                    fi
                fi
            fi
        done
    fi
}

################################################################################
# Migration for Single Tool
################################################################################

migrate_tool() {
    local tool=$1
    local formula version_cmd
    
    # Parse tool definition
    IFS='|' read -r formula version_cmd <<< "${TOOLS[$tool]}"
    
    echo ""
    print_header "Migrating: $tool"
    
    # Uninstall old version
    if uninstall_old_tool "$tool"; then
        # Install via brew
        if install_via_brew "$tool" "$formula" "$version_cmd"; then
            MIGRATED_TOOLS+=("$tool")
            cleanup_directories "$tool"
            return 0
        else
            FAILED_TOOLS+=("$tool")
            return 1
        fi
    else
        print_warning "$tool: Skipped migration"
        return 1
    fi
}

################################################################################
# Summary Report
################################################################################

print_summary() {
    echo ""
    print_header "Migration Summary"
    
    if [[ ${#MIGRATED_TOOLS[@]} -gt 0 ]]; then
        print_success "Successfully migrated (${#MIGRATED_TOOLS[@]}):"
        for tool in "${MIGRATED_TOOLS[@]}"; do
            echo "  ✓ $tool"
        done
    fi
    
    if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
        print_error "Failed to migrate (${#FAILED_TOOLS[@]}):"
        for tool in "${FAILED_TOOLS[@]}"; do
            echo "  ✗ $tool"
        done
    fi
    
    # Show skipped tools
    local skipped=()
    for tool in "${FOUND_TOOLS[@]}"; do
        if [[ ! " ${MIGRATED_TOOLS[@]} " =~ " ${tool} " ]] && \
           [[ ! " ${FAILED_TOOLS[@]} " =~ " ${tool} " ]]; then
            skipped+=("$tool")
        fi
    done
    
    if [[ ${#skipped[@]} -gt 0 ]]; then
        print_warning "Skipped (${#skipped[@]}):"
        for tool in "${skipped[@]}"; do
            echo "  ⊘ $tool"
        done
    fi
    
    echo ""
    print_header "Final Status"
    
    # Verify all brew installations
    local all_good=true
    for tool in "${!TOOLS[@]}"; do
        if command_exists "$tool"; then
            print_success "$tool: $(command -v "$tool")"
        else
            print_warning "$tool: Not found"
            all_good=false
        fi
    done
    
    echo ""
    if [[ "$all_good" == true ]] && [[ ${#FAILED_TOOLS[@]} -eq 0 ]]; then
        print_success "Migration complete! All tools are ready via Homebrew."
    else
        print_warning "Migration incomplete. Some tools may need manual attention."
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║         Homebrew Migration Script for Development Tools            ║
║                                                                    ║
║ This script safely migrates curl-based installations to Homebrew  ║
╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Detect old installations
    detect_old_installations
    
    if [[ ${#FOUND_TOOLS[@]} -eq 0 ]]; then
        echo ""
        print_success "No migration needed. Your tools are already managed by Homebrew!"
        exit 0
    fi
    
    # Ask for overall confirmation
    echo ""
    if ! confirm "Proceed with migration?"; then
        print_warning "Migration cancelled by user"
        exit 0
    fi
    
    # Migrate each tool
    for tool in "${FOUND_TOOLS[@]}"; do
        migrate_tool "$tool" || true
    done
    
    # Print summary
    print_summary
    
    exit 0
}

# Run main function if script is executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
