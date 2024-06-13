# Unix System Initializer (Debian)

This repository contains scripts that can initialize a developer environment. The installed tools are console (terminal)
heavy, because I am primarily working on a WSL Distro, but I included a handful apps for those who are either dual
booting their system or using a Debian flavor directly.

The script will be extensively tested with both Ubuntu and Debian distros once a week with GitHub Actions. This shall
help flag build breaking changes in time. Granted if a diviation occures between the Debian/Ubuntu docker image and the
installable OS / WSL those will need to be fixed manually. While I'll try and test the installer every once in a while
I am making no promisses.

## Installation

```bash
dotfiles_repo="https://github.com/Hegi/dotfiles-public.git"
sudo apt update && sudo apt install -y git
git clone https://github.com/Hegi/unix-setup.git
cd unix-setup
sudo ./install.sh "${dotfiles_repo}"
cd ..
```

## List of installed software, tools and utilities

Below is a list of the apps that are directly installed with the script.

### Utility tools for the installation

These tools are extensively used by the script itself.

- **`curl`**: The de-facto command-line tool network requests. (HTTP(S), FTP, etc.)
- **`wget`**: Similar to curl. Only installed so VS Code Server can be installed in wsl.
- **`gnupg`**: App for encrypting and signing data and communications.
- **`zip` / `unzip`**: A utility pair for creating / extracting ZIP archives.
- **`tar`**: A utility for archiving files and extracting archives.
- **`xz-utils`**: A set of tools for compressing and decompressing `.xz` files.
- **`procps`**: A package containing utilities for monitoring system processes.

### Console productivity tools

These apps are used to enhance the user-experience of the shell user:

- **`zsh`**: An extended Bourne shell with many improvements, including a customizable user interface.
  - **`zinit`**: A plugin manager for `zsh` to manage shell extensions easily.
- **`zellij`**: A terminal workspace with batteries included, designed for developers and system administrators.
- **`starship`**: A customizable prompt for any shell to display various information dynamically.
- **`zoxide`**: A smarter `cd` command for navigating directories.
- **`fzf`**: A command-line fuzzy finder for interactive search.
- **`eza`**: A modern replacement for `ls` with more features and better defaults.
- **`bat`**: A `cat` clone with syntax highlighting and Git integration.
- **`ripgrep`**: A fast search tool that recursively searches directories for a regex pattern. It's `grep` compatible and respects `.gitignore` values.
- **`stow`**: A symlink manager to manage configuration files in a clean and efficient way.
- **`gum`**: A tool to make shell scripts user-friendly with beautiful interactive prompts.
- **`neovim`**: A hyperextensible text editor based on Vim, designed to be more extensible and maintainable.
  - **`nvchad`**: A Neovim configuration that focuses on modern features and a streamlined setup.

### Developer tools

These apps are primarily used by developers.

- **`git`**: A distributed version control system for tracking changes in source code.
- **`gh`**: GitHub’s official command-line tool for interacting with GitHub repositories.
- **`httpie`**: A user-friendly command-line HTTP client for making requests and viewing responses.
- **`jq`**: A lightweight and flexible command-line JSON processor.
- **`yq`**: A command-line YAML processor that works with jq-like syntax.
- **`aws_cli`**: The official command-line interface for interacting with AWS services.
- **`shellcheck`**: A static analysis tool for shell scripts to identify and fix common mistakes.
- **`nvm`**: Node Version Manager, a tool to manage multiple active Node.js versions.
- **`terraform`**: An infrastructure as code tool to define and provision data center infrastructure using a declarative configuration language.
- [DISABLED] **`powershell`**: A cross-platform task automation and configuration management framework, consisting of a command-line shell and scripting language.
  - currently disabled due to a known bug with the latest Ubuntu distro

### UI apps

These apps are only installed if a GUI is present in the distro. (WSL is considered a GUI-less environment in this script)

- **`docker`**: A platform for developing, shipping, and running applications in containers.
- **`brave-browser`**: A privacy-focused web browser with built-in ad and tracker blocking.
- **`signal-desktop`**: A desktop client for the Signal messaging service, which focuses on privacy and security.
- **`ulauncher`**: A fast application launcher for Linux with extension support.
- **`vlc`**: A free and open-source cross-platform multimedia player and framework that plays most multimedia files and streaming protocols.
