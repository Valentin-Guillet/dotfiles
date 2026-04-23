#!/bin/bash

# Run using
# bash <(curl -LsSf https://raw.githubusercontent.com/Valentin-Guillet/dotfiles/main/.config/misc/installer.sh) -i

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Disable colors when not writing to a terminal
[[ ! -t 1 ]] && RED='' && GREEN='' && YELLOW='' && BLUE='' && CYAN='' && BOLD='' && RESET=''

_info() { echo -e "${CYAN}  →${RESET} $*"; }
_success() { echo -e "${GREEN}  ✓${RESET} $*"; }
_warn() { echo -e "${YELLOW}  ⚠${RESET} $*"; }
_error() { echo -e "${RED}  ✗ $*${RESET}" >&2; }
_header() { echo -e "\n${BOLD}${BLUE}▶ $*${RESET}"; }

_confirm() {
  [[ "$ASK_CONFIRM" == 1 ]] || return 0
  read -rp "$(echo -e "${BOLD}$1${RESET} (yN) ")"
  [[ $REPLY =~ ^[Yy]$ ]]
}

_try_run() {
  (
    set -e
    "$1"
  ) || _error "Failed to run '${1#_*_}'."
}

_install_dotfiles() {
  if [[ -f "$HOME"/.config/misc/installer.sh ]]; then
    _warn "Dotfiles already set up, skipping."
    return 0
  fi

  _confirm "Setup dotfiles?" || return 0
  _header "Setting up dotfiles"
  cd "$HOME" || return
  _info "Cloning dotfiles..."
  [[ ! -d dotfiles ]] && git clone -q https://github.com/Valentin-Guillet/dotfiles
  rsync -a dotfiles/.config/ .config/
  rm -rf dotfiles/.config/
  mv dotfiles/.[!.]* ./
  rmdir dotfiles
  _success "Dotfiles set up."
}

_install_git() {
  if grep -rq "^URI.*\bppa.launchpadcontent.net/git-core/ppa\b" /etc/apt/sources.list /etc/apt/sources.list.d/; then
    _warn "Git APT repository already added, skipping."
    return 0
  fi

  _confirm "Add git repository to APT?" || return 0
  _header "Updating git"
  _info "Adding git APT repository..."
  sudo add-apt-repository -y ppa:git-core/ppa >/dev/null
  _info "Running full upgrade..."
  sudo apt full-upgrade -y &>/dev/null
  _success "Git updated."
}

_install_uv() {
  if command -v uv &>/dev/null; then
    _warn "uv already installed, skipping."
    return 0
  fi

  _confirm "Install uv?" || return 0
  _header "Installing uv"
  _info "Running uv installer..."
  curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh >/dev/null
  _info "Generating shell completions..."
  uv generate-shell-completion bash >"$HOME"/.local/share/bash-completion/completions/uv
  uvx --generate-shell-completion bash >"$HOME"/.local/share/bash-completion/completions/uvx
  _info "Setting up base environment..."
  uv venv "$HOME"/.local/venvs/base
  _info "Installing ruff..."
  uv tool install ruff >/dev/null
  _success "uv installed."
}

_install_nerdfont() {
  if [[ -d /usr/local/share/fonts/UbuntuSansNerdFont ]]; then
    _warn "Nerd Font already installed, skipping."
    return 0
  fi

  _confirm "Install Nerdfont?" || return 0
  _header "Installing Nerd Font (UbuntuSans)"
  local font_url
  font_url="$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep browser_download_url | grep "UbuntuSans\.tar\.xz" | cut -d '"' -f 4)"
  _info "Downloading UbuntuSans Nerd Font..."
  wget -q "$font_url" -O UbuntuSans.tar.xz
  _info "Installing font..."
  sudo mkdir -p /usr/local/share/fonts/UbuntuSansNerdFont/
  sudo tar -xaf UbuntuSans.tar.xz -C /usr/local/share/fonts/UbuntuSansNerdFont/
  rm UbuntuSans.tar.xz
  _success "UbuntuSans Nerd Font installed."
}

_install_dconf() {
  _confirm "Setup dconf keybindings?" || return 0
  _header "Setting up dconf keybindings"
  dconf load / <"$HOME"/.config/dconf/conf
  _success "dconf keybindings configured."
}

_install_misc() {
  _confirm "Install htop ctags and xclip?" || return 0
  _header "Installing htop, ctags, xclip"
  _info "Installing packages..."
  sudo apt install -y -qq htop universal-ctags xclip &>/dev/null
  _success "htop, ctags, xclip installed."
}

_update_vim() {
  _confirm "Install vim?" || return 0
  _header "Installing vim"
  _info "Installing dependencies..."
  sudo apt install -y -qq gcc make clang libtool-bin libncurses-dev &>/dev/null
  cd "$HOME"/.local/src/ || return
  if [[ ! -d vim ]]; then
    _info "Cloning vim source..."
    git clone -q --depth 1 https://github.com/vim/vim
    cd vim/ || return
  else
    cd vim/ || return
    _info "Updating vim source..."
    git pull -q --depth 1
  fi
  _info "Configuring..."
  if ! ./configure >/dev/null; then
    make distclean >/dev/null
    ./configure >/dev/null || return 0
  fi
  _info "Building..."
  make -j >/dev/null
  _info "Installing..."
  sudo make install >/dev/null
  _info "Installing vim plugins..."
  command -v vim &>/dev/null && vim -c "PlugInstall | q | q"
  _success "vim installed."
}

_update_tmux() {
  _confirm "Install tmux?" || return 0

  local api_response latest_version tmux_url
  api_response="$(curl -s https://api.github.com/repos/tmux/tmux/releases/latest)"
  latest_version="$(echo "$api_response" | grep '"tag_name"' | cut -d '"' -f 4)"
  tmux_url="$(echo "$api_response" | grep browser_download_url | cut -d '"' -f 4 | grep ".tar.gz")"

  local local_version=""
  if command -v tmux &>/dev/null; then
    local_version="$(tmux -V | cut -d ' ' -f 2)"
  fi

  if [[ "$local_version" == "$latest_version" ]]; then
    _success "tmux $latest_version is already up to date."
    return 0
  fi

  _header "Installing tmux ${latest_version} (current: ${local_version:-not installed})"
  _info "Installing dependencies..."
  sudo apt install -y -qq gcc make libevent-dev ncurses-dev build-essential bison pkg-config &>/dev/null
  cd "$HOME"/.local/src/ || return
  rm -rf tmux-*
  _info "Downloading tmux ${latest_version}..."
  wget -q "$tmux_url" -O tmux.tar.gz
  tar -xaf tmux.tar.gz
  rm tmux.tar.gz
  cd "tmux-$latest_version" || return
  _info "Configuring..."
  if ! ./configure >/dev/null; then
    make distclean >/dev/null
    ./configure >/dev/null
  fi
  _info "Building..."
  make -j >/dev/null
  _info "Installing..."
  sudo make install >/dev/null
  _success "tmux ${latest_version} installed."
}

_update_neovim() {
  _confirm "Install nvim?" || return 0
  _header "Installing nvim"
  cd "$HOME"/.local/src/ || return
  if [[ ! -d neovim ]]; then
    _info "Cloning neovim source..."
    git clone -q --depth 1 https://github.com/neovim/neovim
    cd neovim/ || return
  else
    cd neovim/ || return
    _info "Updating neovim source..."
    git pull -q --depth 1
  fi
  _info "Installing dependencies..."
  sudo apt install -y -qq gcc make cmake &>/dev/null
  _info "Building..."
  make -j >/dev/null
  _info "Installing..."
  sudo make install >/dev/null
  _success "nvim $(nvim --version | head -n 1 | cut -d' ' -f2) installed."
}

_update_git-extras() {
  _confirm "Install git-extras?" || return 0

  local extra_list=(abort alias count obliterate root summary)
  local extra_name
  _info "Updating binaries..."
  for extra_name in "${extra_list[@]}"; do
    wget -q "https://raw.githubusercontent.com/tj/git-extras/refs/heads/main/bin/git-$extra_name" -O "$HOME/.config/git/custom_commands/git-$extra_name"
    chmod +x "$HOME/.config/git/custom_commands/git-$extra_name"
  done
  # Remote `git-continue` definition is wrong (doesn't work with script "$0"), we create it manually
  ln -sf "$HOME"/.config/git/custom_commands/git-abort "$HOME"/.config/git/custom_commands/git-continue
  _info "Updating man pages..."
  for extra_name in "${extra_list[@]}"; do
    sudo wget -q "https://raw.githubusercontent.com/tj/git-extras/refs/heads/main/man/git-$extra_name.1" -O /usr/local/share/man/man1/"git-$extra_name.1"
  done
}

_github_deb() {
  local gh_repo="$1"
  local name="${gh_repo##*/}"
  local binary="${2:-$name}"

  _confirm "Install ${name}?" || return 0

  local api_response latest_version deb_url
  api_response="$(curl -s "https://api.github.com/repos/${gh_repo}/releases/latest")"
  latest_version="$(echo "$api_response" | grep '"tag_name"' | cut -d '"' -f 4)"
  deb_url="$(echo "$api_response" | grep browser_download_url | grep 'amd64\.deb"' | grep -v musl | cut -d '"' -f 4)"

  local compare_version="${latest_version#v}"

  local local_version=""
  if command -v "$binary" &>/dev/null; then
    local_version="$("$binary" --version | head -1 | cut -d ' ' -f 2)"
  fi

  if [[ "$local_version" == "$compare_version" ]]; then
    _success "${name} ${compare_version} is already up to date."
    return 0
  fi

  _header "Installing ${name} ${compare_version} (current: ${local_version:-not installed})"
  _info "Downloading ${name} ${compare_version}..."
  wget -q "$deb_url" -O "${name}.deb"
  _info "Installing package..."
  sudo dpkg -i "${name}.deb" >/dev/null
  rm "${name}.deb"
  _success "${name} ${compare_version} installed."
}

_update_bat() { _github_deb "sharkdp/bat"; }
_update_fd() { _github_deb "sharkdp/fd"; }
_update_ripgrep() { _github_deb "BurntSushi/ripgrep" "rg"; }

_update_delta() {
  _github_deb "dandavison/delta" || return 0

  if [[ ! -f "$HOME"/.local/share/bash-completion/completions/delta ]]; then
    _info "Generating shell completion..."
    delta --generate-completion bash >"$HOME"/.local/share/bash-completion/completions/delta
  fi
  if [[ ! -f /usr/local/share/man/man1/delta.1 ]]; then
    _info "Downloading man page..."
    sudo wget -q https://manpages.debian.org/testing/git-delta/delta.1.en.gz -O /usr/local/share/man/man1/delta.1
  fi
}

_update_fzf() {
  _confirm "Install fzf?" || return 0

  local api_response latest_version fzf_url
  api_response="$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest)"
  latest_version="$(echo "$api_response" | grep '"tag_name"' | cut -d '"' -f 4)"
  fzf_url="$(echo "$api_response" | grep browser_download_url | grep 'linux_amd64\.tar\.gz' | cut -d '"' -f 4)"

  local local_version=""
  if command -v fzf &>/dev/null; then
    local_version="$(fzf --version | cut -d ' ' -f 1)"
  fi

  if [[ "$local_version" == "${latest_version#v}" ]]; then
    _success "fzf ${latest_version#v} is already up to date."
    return 0
  fi

  _header "Installing fzf ${latest_version#v} (current: ${local_version:-not installed})"
  _info "Downloading fzf ${latest_version#v}..."
  wget -q "$fzf_url" -O fzf.tar.gz
  tar -xaf fzf.tar.gz
  rm fzf.tar.gz
  mv fzf "$HOME"/.local/bin/
  _info "Downloading man pages..."
  sudo wget -q https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/man/man1/fzf.1 -O /usr/local/share/man/man1/fzf.1
  _success "fzf ${latest_version#v} installed."
}

_update_lazygit() {
  _confirm "Install lazygit?" || return 0

  local api_response latest_version lg_url
  api_response="$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest)"
  latest_version="$(echo "$api_response" | grep '"tag_name"' | cut -d '"' -f 4)"
  lg_url="$(echo "$api_response" | grep browser_download_url | grep 'linux_x86_64\.tar\.gz' | cut -d '"' -f 4)"

  local local_version=""
  if command -v lazygit &>/dev/null; then
    local_version="$(lazygit --version | grep -oP '(?<=, version=)[^,]+')"
  fi

  if [[ "$local_version" == "${latest_version#v}" ]]; then
    _success "lazygit ${latest_version#v} is already up to date."
    return 0
  fi

  _header "Installing lazygit ${latest_version#v} (current: ${local_version:-not installed})"
  _info "Downloading lazygit ${latest_version#v}..."
  wget -q "$lg_url" -O lg.tar.gz
  tar -xaf lg.tar.gz lazygit
  rm lg.tar.gz
  mv lazygit "$HOME"/.local/bin/
  _success "lazygit ${latest_version#v} installed."
}

main() {
  mkdir -p "$HOME"/.local/bin/
  mkdir -p "$HOME"/.local/src/
  mkdir -p "$HOME"/.local/share/bash-completion/completions/

  local all_install_tools=(dotfiles git uv nerdfont dconf misc)
  local all_update_tools=(vim tmux neovim bat delta fd fzf lazygit ripgrep git-extras)

  local tools=()
  local do_install=0
  ASK_CONFIRM=1

  local usage
  usage="$(
    echo -e "${BOLD}Usage:${RESET} $(basename "$0") [OPTIONS] [TOOL...]"
    echo ""
    echo "Set up workspace by installing and updating tools."
    echo ""
    echo -e "${BOLD}Options:${RESET}"
    echo "  -h, --help     Show this help message and exit"
    echo "  -l, --list     List all available tools and exit"
    echo "  -i, --install  Run first-time setup routines (implies -u)"
    echo "  -t, --tools    Update CLI tools only: bat, delta, fd, fzf, lazygit, ripgrep"
    echo "  -y, --yes      Skip confirmation prompts"
    echo ""
    echo -e "${BOLD}Arguments:${RESET}"
    echo "  TOOL...        Only update the specified tool(s) (implies -y)"
  )"

  local parsed
  if ! parsed=$(getopt --options hltiy --longoptions help,list,tools,install,yes \
    --name "$(basename "$0")" -- "$@"); then
    echo -e "$usage" >&2
    return 1
  fi
  eval set -- "$parsed"

  while true; do
    case "$1" in
    -h | --help)
      echo -e "$usage"
      return 0
      ;;
    -l | --list)
      echo -e "${BOLD}Update tools:${RESET}"
      printf '  %s\n' "${all_update_tools[@]}"
      echo -e "${BOLD}Install tools:${RESET}"
      printf '  %s\n' "${all_install_tools[@]}"
      return 0
      ;;
    -i | --install) do_install=1 && shift ;;
    -t | --tools) tools+=(bat delta fd fzf lazygit ripgrep) && shift ;;
    -y | --yes) ASK_CONFIRM=0 && shift ;;
    --) shift && break ;;
    esac
  done

  for arg in "$@"; do
    tools+=("$arg")
  done

  # -i implies updating all tools
  if [[ "$do_install" == 1 || ${#tools[@]} -eq 0 ]]; then
    tools=("${all_update_tools[@]}")
  elif [[ ${#tools[@]} -eq 1 ]]; then # Don't confirm when called with one tool only
    ASK_CONFIRM=0
  fi

  if [[ "$do_install" == 1 ]]; then
    for tool in "${all_install_tools[@]}"; do
      _try_run "_install_$tool"
      [[ "$tool" == "dotfiles" ]] && source "$HOME"/.profile
    done
  fi

  for tool in "${tools[@]}"; do
    if [[ " ${all_update_tools[*]} " != *" $tool "* ]]; then
      _error "No update procedure found for '$tool'"
      return 1
    fi
    _try_run "_update_$tool"
  done

  unset ASK_CONFIRM
}

main "$@"
