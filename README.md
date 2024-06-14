# Unix System Initializer (Debian)

This repository contains scripts that can initialize a developer environment. The installed tools are console (terminal)
heavy, because I am primarily working on a WSL Distro, but I included a handful apps for those who are either dual
booting their system or using a Debian flavor directly.

The script will be extensively tested with both Ubuntu and Debian distros once a week with GitHub Actions. This shall
help flag build breaking changes in time. Granted if a diviation occures between the Debian/Ubuntu docker image and the
installable OS / WSL those will need to be fixed manually. While I'll try and test the installer every once in a while
I am making no promisses.

## What's not covered?

While this setup _should_ be working in native linux, it's not tested. The script is also not modular, it has everything
I use in a way that testing and script execution is optimized. So no modularity. If you want to remove things, you'll
have to go through the whole install_lib file. Same goes if you want to add something.

This library also not covers how to install nerdfonts in your favourite terminal, because YMMW. However w/o installing
at least one - and using it - some of the characters in the console won't show up; making the experience subpar. If you
don't want to use a nerdfont, that's understandable, however you'll have to tweak quite a lot of configuration for the
apps used here.

## Fresh installation in WSL

If you want to do a fresh installation on WSL, but you already have Debian distro, here is how you can throw it away:

```powershell
wsl --unregister Debian
wsl --install -d Debian --web-download
```

After unregister, docker will complain that it's Debian integration is failing. After re-installing the distro, you can
simply click on the docker restart button and all should be well.

![wsl integration failiure ui](docs/docker-wsl-integration-error.png "WSL Integration failiure")

If your you just installed the Debian distro in WSL for the first time, make sure that you enable the docker WSL
integration for the distro, before you move on

![wsl integration failiure ui](docs/docker-wsl-integration.png "WSL Integration failiure")

## Installation

```bash
dotfiles_repo="https://github.com/Hegi/dotfiles-public.git"
[[ ! $(type git) ]] && sudo apt update && sudo apt install -y git
git clone https://github.com/Hegi/unix-setup.git
cd unix-setup
sudo ./install.sh "${dotfiles_repo}"
cd ..
```

While the above installation, and dotfile management works, it has one significant drawback: if any of your dotfiles
contain a secret, it gets into version control. And while it's obvious how unsecure is to make such a repo public,
keeping it private is only marginally better, if you are hosting the repo with a cloud provider such as GitHub or GitLab.
Imagine that the provider gets a data-breach and your private dotfiles repo is a victim of said breach. Your secrets are
just as compromised.

To avoid this scenario, I'd recommend the following measures being taken:

1. **DO NOT** host such a repo with a cloud provider.
2. Encrypt the repository if you store it remotely.

### Self-hosting

To address the first callout, you can do one of two things: If you have more than one device that needs the dotfiles,
then you can clone and pull between said devices with git. Just use `git remote add name url` to specify the machines,
then you can do `git pull basement-server`, `git pull laptop`, `git pull nas` etc. Granted, you won't be able to push
but you'll have redundancy in place, so if one of the devices needs a re-install, you can get the dotfiles config from
another.

Or if you have a server running, and have ssh access to said server, then you can setup a bare repo on the server
somewhere and pull/push that way. `git init --bare repo.git` is the command you are looking for in this case.

### Encryption

The problem with the self-hosted server is the same as with the cloud provider hosted one. Yes, if your own hardware
gets compromised you have bigger problems. Never the less if you want to add in an extra layer of security, you can
use `git-remote-gcrypt` to wrap the remote operations and encrypt the data that's being written into the repository.
The biggest downside of this approach - beyond the ones documented at [git-remote-gcrypt-](https://github.com/spwhitton/git-remote-gcrypt) -
is that you'll need a unix machine to decrypt the content. Given that we are planning to use this to manage linux configuration
this shouldn't be a show-stopper; especially with the WSL integrations, I wanted to be explicit with it, before you start
wanting to use this approch with other repos as well.

Now can you just encrypt the repo, and store it as a private one in a cloud provider? Sure! Do I recommend doing it? Nope!
And before you mention that I am about to do the exact same thing bellow, let me remind you that this entire repo is
mostly for demo purposes, and that there is absolutely nothing sensitive in the repo in question. Further more I am also
sharing the encryption key for said repo, so at this point it's only technically encrypted.

### Installation using an encrypted dotfiles repo

Make sure you have a gpg key for encryption and that you backed it up into a file. If you don't you can use the
`gpg --full-generate-key` command to create one, then the
`gpg -o dotfiles.asc --armor --export-options backup --export-secret-keys 0000000000000000000000000000000000000000`
command to export it into a file called `dotfiles.asc`. The `0000000000000000000000000000000000000000` stands for the
id of the key, which you can fetch with the `gpg -k` command.

In case you want to test it with a pre-cooked encryption setup, here is the gpg-key for the encrypted version of the
same dotfiles-public repo:

```bash
cat << 'EOF' > dotfiles.asc
-----BEGIN PGP PRIVATE KEY BLOCK-----

lFgEZmu52xYJKwYBBAHaRw8BAQdAL/9SgHGFQVFiFKWfLJoRmKvYcIika8PbUKQF
E2Vae/YAAP9FvgfQxydr59atsdKHLLsbuqJtwq05bvN/Bu6E+PZrwBOKsAwAAGdw
ZwEAAAAAAAC0MElzdHZhbiBIZWdlZHVzIChkb3RmaWxlcykgPGlzdHZhbkBoZWdp
c3R2YW4uY29tPrAMAABncGcCAAAAAAAAiJkEExYKAEEWIQQCAsiF1zegdJ4KO4As
vMeoVVPYKQUCZmu52wIbAwUJA8JnAAULCQgHAgIiAgYVCgkICwIEFgIDAQIeBwIX
gAAKCRAsvMeoVVPYKVltAP4+j3htIDwiNqOnNRkWA3CUjHCbOeSf0Jm8h/JPJXC8
BgD+Jb99rsH/4/YhThq+GMm6H3rW8170WJiQl5bIOa3DqAWwBgAAZ3BnAJxdBGZr
udsSCisGAQQBl1UBBQEBB0DmFsCbroR5De5I3KmtKqo9/s5AfaLu+W5TvZbDWebf
dQMBCAcAAP9vomRbWL6IH+pIdRjzHx1ZcnnnpwuoDrYRL8/m5u++6BEziH4EGBYK
ACYWIQQCAsiF1zegdJ4KO4AsvMeoVVPYKQUCZmu52wIbDAUJA8JnAAAKCRAsvMeo
VVPYKa7/AQDVwgZIgmIioVgPX/kzES2hI2/4kZmWoPzz2Q8YA7V3bgEAiVvKoj81
Hr7M2gqdx0I1e4DBJ97Mw6yiyxyOZYgrKwSwBgAAZ3BnAA==
=8khS
-----END PGP PRIVATE KEY BLOCK-----
EOF
```

Here's the modified installer script:

```bash
dotfiles_repo="gcrypt:git@github.com:Hegi/dotfiles-encrypted-public.git"
dotfiles_key_path="./dotfiles.asc"
[[ ! $(type git) ]] && sudo apt update && sudo apt install -y git
[[ ! $(type git-remote-gcrypt) ]] && sudo apt update && sudo apt install -y git-remote-gcrypt
git clone https://github.com/Hegi/unix-setup.git
cd unix-setup
sudo ./install.sh "${dotfiles_repo}" "${dotfiles_key_path}"
cd ..
```

Please note that if you used a passkey for the gpg key, you'll be prompted for it each time you pull or push the
dotfiles repo. This includes the installation process.

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
