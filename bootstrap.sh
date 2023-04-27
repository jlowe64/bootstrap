#!/usr/bin/env zsh

set -e

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

success_final () {
    success "Nothing else to do!"
    exit 0
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure?} [Y/n]" response
    case $response in
        [yY][eE][sS]|[yY]|"") 
            true
            ;;
        *)
            false
            ;;
    esac
}

# Only run if the tools are not installed yet
# To check that try to print the SDK path
xcode-select -p &> /dev/null
if [ $? -ne 0 ]; then
  info "Command Line Tools for Xcode not found. Installing from softwareupdate…"
# This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
  PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
  softwareupdate -i "$PROD" --verbose;
else
  info "Command Line Tools for Xcode have been installed."
fi

if [ -d ~/Development/dotfiles ] && confirm "Install .dotfiles from github?"; then
    info "dotfiles found, updating them from github.com/jlowe64/dotfiles"
    (cd ~/Development/dotfiles && git pull)
    cp ~/Development/dotfiles/.zshrc ~/
    cp ~/Development/dotfiles/.zprofile ~/
    source ~/.zshrc
else
    info "dotfiles not found, getting them from github.com/jlowe64/dotfiles"
    git clone https://github.com/jlowe64/dotfiles ~/Development/dotfiles
    cp ~/Development/dotfiles/.zshrc ~/
    cp ~/Development/dotfiles/.zprofile ~/
    source ~/.zshrc
fi

# Check if Homebrew is already there
if ! command -v brew &>/dev/null; then
    # Install Homebrew
    info "Homebrew is not installed, installing."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    info "Homebrew is already installed, let's make sure it's up to date (brew update)."
    brew update
fi

if [ -f /usr/local/bin/ktoolbox ] && confirm "Install ktoolbox?"; then
    info "ktoolbox found, doing nothing"
else
    info "ktoolbox not found, installing"
    sudo curl -L https://git.io/JeCE4 -o /usr/local/bin/ktoolbox && sudo chmod +x /usr/local/bin/ktoolbox
fi

if [[ ! -e ~/Development ]]; then
    mkdir ~/Development
elif [[ ! -d ~/Development ]]; then
    echo "~/Development already exists but is not a directory" 1>&2
fi

if [ -f ~/.zshrc ] && confirm "Install zsh completions?"; then
    brew install zsh-completions
fi

if [ -z "$HOMEBREW_CASK_OPTS" ]; then
    if confirm "Install brew cask apps under /Applications (it's more predictable than default behavior)?"; then
        # Make Brew Cask install programs in a more predictable location
        cask_opts="HOMEBREW_CASK_OPTS=--appdir=/Applications"
        export $cask_opts
        shell_dot_file="$HOME/.zshrc"
        if [ ! -f "$shell_dot_file" ]; then
            shell_dot_file="$HOME/.bash_profile"
        fi
        echo $cask_opts >> $shell_dot_file
        info "$cask_opts has been added to $shell_dot_file"
    fi
fi

# TODO: Confirm setting the zsh plugins to certain list 

if confirm "Next step installs everything defined in Brewfile - review them BEFORE you hit ENTER!"; then
    # Following will install everything from Brewfile
    info "Depending on the packages you install, you might get promped for your password several times."
    brew bundle
fi

if command -v pyenv &>/dev/null; then
    pyenv install 3.11.2
    pyenv global 3.11.2
fi

if command -v tfenv &>/dev/null; then
    tfenv install 1.4.4
    tfenv use 1.4.4
fi

brew cleanup
success_final
