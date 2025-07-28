# ProxMux macOS Development Setup

A standalone macOS Oh My Zsh setup script based on ProxMux's security-first architecture patterns, adapted for macOS development environments.

## Overview

This macOS setup provides a comprehensive development environment with:
- 🍺 **Homebrew** package management
- 🐚 **Oh My Zsh** with security-hardened configuration
- 🎨 **Powerlevel10k** theme
- 🛠️ **Development tools** and modern CLI utilities
- 🔒 **Security-first approach** with input validation
- 📁 **Project management** helpers

## Quick Start

```bash
# Clone or download the repository
git clone https://github.com/talltechy/ProxMux.git
cd ProxMux

# Run the macOS setup (as regular user, NOT root)
./setup-macos.sh
```

## What Gets Installed (Enhanced)

### Package Manager
- **Homebrew** - The missing package manager for macOS

### Development Tools
- **Git** with GitHub CLI
- **Node.js** with npm, yarn, pnpm
- **Python 3** with pip and virtual environment support
- **VSCode Insiders** with command-line integration
- **Modern CLI tools**: fzf, ripgrep, bat, exa, tree, jq, fd
- **Editors**: Neovim
- **Terminal**: tmux with iTerm2 integration

### Oh My Zsh Setup
- **Powerlevel10k** theme with instant prompt
- **Enhanced plugins**: autosuggestions, syntax highlighting, completions, z, copypath, colored-man-pages, iterm2
- **iTerm2 integration**: shell integration, image display, command status
- **Security settings**: limited history, duplicate removal
- **Development aliases** and functions with input validation

### Development Environment
- **Project directories**: `~/Projects`, `~/Scripts`, `~/.local/bin`
- **Helper scripts**: mkproject, brewup, serve
- **Git configuration** helpers
- **Development functions** library

## Enhanced Key Commands

After installation, you'll have access to these enhanced commands:

### Project Management
```bash
mkproject myapp          # Create new project with git init
mkpyproject myapp        # Create Python project with venv and structure
cdp myapp               # Navigate to project
projects                # Go to Projects directory
```

### Python Development
```bash
py                      # Python 3 shortcut
pip                     # pip3 shortcut
venv                    # Activate virtual environment (venv/ or .venv/)
```

### VSCode Insiders Integration
```bash
codei .                 # Open current directory in VSCode Insiders
code myfile.py          # Open file in VSCode Insiders (defaults to insiders)
```

### Enhanced Navigation
```bash
z myproject             # Jump to frequently used directory
copypath                # Copy current path to clipboard
ll                      # Enhanced ls with git status and colors
```

### Package Management
```bash
brewup                  # Update Homebrew and all packages
npmup                   # Update global npm packages
```

### Development Servers
```bash
serve                   # Start HTTP server (port 8000)
serve 3000             # Start HTTP server on port 3000
liveserve              # Start live-reload server
```

### Git Helpers
```bash
gitconfig              # Configure git user settings
gst                    # Git status (short)
gaa                    # Git add all
gcm "commit message"   # Git commit with validation
gp                     # Git push
```

### System Utilities
```bash
dev-help               # Show all available functions
myip                   # Show external IP address
ports                  # Show listening ports
cleanup                # Clean system caches
sysinfo                # System information
showfiles              # Show hidden files in Finder
hidefiles              # Hide hidden files in Finder
flushdns               # Flush DNS cache
```

### iTerm2 Features (when using iTerm2)
```bash
imgcat image.png       # Display image in terminal
imgls                  # List images with thumbnails
# Automatic command status indicators
# Semantic history (clickable paths/URLs)
# Shell marks for navigation
```

## Security Features

Following ProxMux's security-first approach:

- ✅ **Input validation** on all custom functions
- ✅ **Automatic backups** before configuration changes
- ✅ **Safe execution** with timeouts and error handling
- ✅ **Limited history** with duplicate removal
- ✅ **User-level installation** (no root required)
- ✅ **Download verification** for external resources
- ✅ **Enhanced Python workflow** with project templates and venv management
- ✅ **iTerm2 deep integration** with shell utilities and visual feedback
- ✅ **Smart navigation** with z plugin for frequency-based directory jumping

## File Structure

```
ProxMux/
├── setup-macos.sh                    # Main setup script
├── scripts/
│   ├── common-functions-macos.sh     # Shared functions library
│   ├── install-packages-macos.sh     # Package installation
│   └── apply-configs-macos.sh        # Configuration application
├── configs/
│   └── .zshrc-macos                  # macOS zsh configuration
└── README-macOS.md                   # This file
```

## Post-Installation

After running the setup:

1. **Start a new terminal** or run: `source ~/.zshrc`
2. **Configure Powerlevel10k**: Run `p10k configure`
3. **Test the setup**: Run `dev-help` to see available commands
4. **Create your first project**: `mkproject test-project` or `mkpyproject python-app`
5. **Test enhanced navigation**: Use `z` to jump to directories, `ll` for enhanced listing
6. **Try iTerm2 features**: Use `imgcat` to display images (in iTerm2)

## Customization

### Adding Custom Functions
Add your functions to `~/.local/lib/dev-functions.sh`:
```bash
# Example custom function
myfunction() {
    echo "My custom function"
}
export -f myfunction
```

### Modifying Aliases
Edit `~/.zshrc` to add or modify aliases:
```bash
# Add custom aliases
alias myalias='my command'
```

### Installing Additional Tools
Use Homebrew to install additional tools:
```bash
brew install your-tool
```

## Troubleshooting

### Homebrew Not Found
If Homebrew is not in your PATH after installation:
```bash
# For Apple Silicon Macs
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs
eval "$(/usr/local/bin/brew shellenv)"
```

### Zsh Not Default Shell
If zsh is not set as your default shell:
```bash
chsh -s $(which zsh)
```

### Functions Not Available
If development functions are not available:
```bash
source ~/.local/lib/dev-functions.sh
```

## Architecture

This setup follows ProxMux's modular architecture:

- **Security-first design** with input validation
- **Modular function library** for code reuse
- **Graceful error handling** with informative messages
- **Configuration management** with automatic backups
- **Template method pattern** for consistent initialization

## Comparison with ProxMux

| Feature | ProxMux (Proxmox) | macOS Setup |
|---------|-------------------|-------------|
| Package Manager | apt | Homebrew |
| Target User | root | regular user |
| Hardware Monitoring | IPMI/sensors | System Profiler |
| Virtualization | Proxmox VE | Development tools |
| Security Model | sudoers/restricted | user-level validation |

## Contributing

This macOS setup maintains the same architectural patterns as ProxMux. When contributing:

1. Follow the security-first approach
2. Add input validation to all functions
3. Include error handling and informative messages
4. Test on both Intel and Apple Silicon Macs
5. Update documentation

## License

Same license as ProxMux project.

## Related

- [ProxMux](https://github.com/talltechy/ProxMux) - Original Proxmox VE configuration
- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [Homebrew](https://brew.sh/) - Package manager for macOS
