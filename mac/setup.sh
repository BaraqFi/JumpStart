#!/usr/bin/env bash

# =============================================================================
#     ██╗██╗   ██╗███╗   ███╗██████╗ ███████╗████████╗ █████╗ ██████╗ ████████╗
#     ██║██║   ██║████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝
#     ██║██║   ██║██╔████╔██║██████╔╝███████╗   ██║   ███████║██████╔╝   ██║
#██   ██║██║   ██║██║╚██╔╝██║██╔═══╝ ╚════██║   ██║   ██╔══██║██╔══██╗   ██║
#╚█████╔╝╚██████╔╝██║ ╚═╝ ██║██║     ███████║   ██║   ██║  ██║██║  ██║   ██║
# ╚════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
# =============================================================================
#  JumpStart — macOS Developer Setup
#  https://github.com/baraqfi/jumpstart
#  Open source. Beginner friendly. One command.
# =============================================================================

set -euo pipefail

# ─────────────────────────────────────────────
# COLORS & STYLES
# ─────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

BG_BLACK="\033[40m"
BG_BLUE="\033[44m"
BG_CYAN="\033[46m"

# ─────────────────────────────────────────────
# FLAGS (set by CLI args or defaults)
# ─────────────────────────────────────────────
INTERACTIVE=true
INSTALL_ESSENTIALS=false
INSTALL_WEB=false
INSTALL_PYTHON=false
INSTALL_PRODUCTIVITY=false
INSTALL_AI=false
INSTALL_ALL=false
DRY_RUN=false
LOG_FILE="$HOME/jumpstart-install.log"

# ─────────────────────────────────────────────
# PARSE ARGUMENTS
# ─────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --essentials)    INSTALL_ESSENTIALS=true; INTERACTIVE=false ;;
    --web)           INSTALL_WEB=true;        INTERACTIVE=false ;;
    --python)        INSTALL_PYTHON=true;     INTERACTIVE=false ;;
    --productivity)  INSTALL_PRODUCTIVITY=true; INTERACTIVE=false ;;
    --ai)            INSTALL_AI=true;         INTERACTIVE=false ;;
    --all)           INSTALL_ALL=true;        INTERACTIVE=false ;;
    --dry-run)       DRY_RUN=true ;;
    --help|-h)       SHOW_HELP=true ;;
  esac
done

# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────
log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"; }
info()    { echo -e "  ${CYAN}→${RESET} $*"; log "INFO: $*"; }
success() { echo -e "  ${GREEN}✓${RESET} $*"; log "OK:   $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET} $*"; log "WARN: $*"; }
error()   { echo -e "  ${RED}✗${RESET} $*"; log "ERR:  $*"; }
dim()     { echo -e "  ${DIM}$*${RESET}"; }
blank()   { echo ""; }

# Check if a command exists
has() { command -v "$1" &>/dev/null; }

# Run or simulate a command
run() {
  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${DIM}[dry-run] $*${RESET}"
    log "DRY-RUN: $*"
  else
    log "RUN: $*"
    "$@"
  fi
}

# Install a brew package only if not already present
brew_install() {
  local pkg="$1"
  local label="${2:-$1}"
  if brew list "$pkg" &>/dev/null 2>&1; then
    success "$label already installed — skipping"
  else
    info "Installing $label..."
    run brew install "$pkg"
    success "$label installed"
  fi
}

# Install a brew cask only if not already present
brew_cask_install() {
  local pkg="$1"
  local label="${2:-$1}"
  if brew list --cask "$pkg" &>/dev/null 2>&1; then
    success "$label already installed — skipping"
  else
    info "Installing $label..."
    run brew install --cask "$pkg"
    success "$label installed"
  fi
}

# ─────────────────────────────────────────────
# DIVIDER
# ─────────────────────────────────────────────
divider() {
  echo -e "${DIM}  ────────────────────────────────────────────────────────${RESET}"
}

# ─────────────────────────────────────────────
# WELCOME SCREEN
# ─────────────────────────────────────────────
print_welcome() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}"
  echo "  ╔══════════════════════════════════════════════════════════╗"
  echo "  ║                                                          ║"
  echo "  ║    ██╗██╗   ██╗███╗   ███╗██████╗ ███████╗████████╗    ║"
  echo "  ║    ██║██║   ██║████╗ ████║██╔══██╗██╔════╝╚══██╔══╝    ║"
  echo "  ║    ██║██║   ██║██╔████╔██║██████╔╝███████╗   ██║       ║"
  echo "  ║    ██║██║   ██║██║╚██╔╝██║██╔═══╝ ╚════██║   ██║       ║"
  echo "  ║    ██║╚██████╔╝██║ ╚═╝ ██║██║     ███████║   ██║       ║"
  echo "  ║    ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝   ╚═╝       ║"
  echo "  ║                                                          ║"
  echo -e "  ║  ${WHITE}Your Mac. Set up in minutes. Made for beginners.${CYAN}        ║"
  echo "  ║                                                          ║"
  echo -e "  ║  ${DIM}${WHITE}v1.0.0  •  github.com/baraqfi/jumpstart${CYAN}                  ║"
  echo "  ║                                                          ║"
  echo "  ╚══════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${YELLOW}${BOLD}[DRY RUN MODE]${RESET} ${YELLOW}Nothing will actually be installed.${RESET}"
    blank
  fi
}

# ─────────────────────────────────────────────
# HELP SCREEN
# ─────────────────────────────────────────────
print_help() {
  print_welcome
  echo -e "  ${BOLD}Usage:${RESET}"
  blank
  dim "  Run interactively (recommended for first time):"
  echo -e "  ${CYAN}curl -fsSL https://raw.githubusercontent.com/baraqfi/jumpstart/main/mac/setup.sh | bash${RESET}"
  blank
  dim "  Run with specific categories:"
  echo -e "  ${CYAN}... | bash -s -- --web --python${RESET}"
  blank
  echo -e "  ${BOLD}Available flags:${RESET}"
  blank
  echo -e "    ${GREEN}--essentials${RESET}    Git, VS Code, terminal basics"
  echo -e "    ${GREEN}--web${RESET}           Node.js (nvm), pnpm, Docker, Postman"
  echo -e "    ${GREEN}--python${RESET}        Python (pyenv), pipx"
  echo -e "    ${GREEN}--productivity${RESET}  Starship prompt, bat, eza, fzf, GitHub CLI"
  echo -e "    ${GREEN}--ai${RESET}            Gemini CLI, Claude Code"
  echo -e "    ${GREEN}--all${RESET}           Everything above"
  echo -e "    ${GREEN}--dry-run${RESET}       Preview what would be installed"
  echo -e "    ${GREEN}--help${RESET}          Show this screen"
  blank
  echo -e "  ${DIM}Docs: https://github.com/baraqfi/jumpstart${RESET}"
  blank
  exit 0
}

# ─────────────────────────────────────────────
# SYSTEM CHECK
# ─────────────────────────────────────────────
check_system() {
  echo -e "  ${BOLD}Checking your system...${RESET}"
  blank

  # macOS only
  if [[ "$OSTYPE" != "darwin"* ]]; then
    error "JumpStart macOS script only works on macOS."
    info  "For Windows, see: https://github.com/baraqfi/jumpstart/windows"
    exit 1
  fi

  local macos_version
  macos_version=$(sw_vers -productVersion)
  success "macOS $macos_version detected"

  # Check internet
  if curl -s --max-time 5 https://github.com &>/dev/null; then
    success "Internet connection confirmed"
  else
    error "No internet connection detected. Please connect and try again."
    exit 1
  fi

  # Xcode Command Line Tools (required for git, brew, etc.)
  if ! xcode-select -p &>/dev/null; then
    warn "Xcode Command Line Tools not found — installing now..."
    echo ""
    echo -e "  ${YELLOW}A popup may appear asking to install developer tools.${RESET}"
    echo -e "  ${YELLOW}Click 'Install' and wait for it to finish, then re-run JumpStart.${RESET}"
    blank
    run xcode-select --install
    echo ""
    warn "Please re-run JumpStart after the Xcode tools finish installing."
    exit 0
  else
    success "Xcode Command Line Tools ready"
  fi

  blank
}

# ─────────────────────────────────────────────
# INTERACTIVE MENU
# ─────────────────────────────────────────────
print_menu() {
  echo -e "  ${BOLD}What would you like to install?${RESET}"
  dim "  Use the number keys to toggle, then press Enter when ready."
  blank

  echo -e "  ${BOLD}${GREEN}[1]${RESET} ${BOLD}Essentials${RESET} ${DIM}(recommended)${RESET}"
  dim "      Git, VS Code, Homebrew"
  blank

  echo -e "  ${BOLD}${GREEN}[2]${RESET} ${BOLD}Web Development${RESET}"
  dim "      Node.js via nvm, pnpm, Docker Desktop, Postman"
  blank

  echo -e "  ${BOLD}${GREEN}[3]${RESET} ${BOLD}Python${RESET}"
  dim "      Python 3 via pyenv, pipx"
  blank

  echo -e "  ${BOLD}${GREEN}[4]${RESET} ${BOLD}Productivity Tools${RESET}"
  dim "      Starship prompt, bat, eza, fzf, GitHub CLI, Nerd Fonts"
  blank

  echo -e "  ${BOLD}${GREEN}[5]${RESET} ${BOLD}AI CLI Tools${RESET} ${DIM}(optional — you'll add your own API keys)${RESET}"
  dim "      Gemini CLI (Google), Claude Code (Anthropic)"
  blank

  echo -e "  ${BOLD}${CYAN}[A]${RESET} ${BOLD}Install Everything${RESET}"
  blank
  divider
  blank
}

interactive_menu() {
  print_menu

  local sel_essentials=false
  local sel_web=false
  local sel_python=false
  local sel_productivity=false
  local sel_ai=false

  local choices=()

  echo -e "  Enter numbers separated by spaces ${DIM}(e.g. 1 2 5)${RESET}, or ${CYAN}A${RESET} for all:"
  echo -ne "  ${BOLD}→ ${RESET}"
  read -r input

  blank

  # Lowercase and check for 'a'
  input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

  if [[ "$input_lower" == *"a"* ]]; then
    INSTALL_ESSENTIALS=true
    INSTALL_WEB=true
    INSTALL_PYTHON=true
    INSTALL_PRODUCTIVITY=true
    INSTALL_AI=true
    return
  fi

  for token in $input; do
    case $token in
      1) INSTALL_ESSENTIALS=true ;;
      2) INSTALL_WEB=true ;;
      3) INSTALL_PYTHON=true ;;
      4) INSTALL_PRODUCTIVITY=true ;;
      5) INSTALL_AI=true ;;
    esac
  done

  # Must select at least one
  if [ "$INSTALL_ESSENTIALS" = false ] && [ "$INSTALL_WEB" = false ] && \
     [ "$INSTALL_PYTHON" = false ] && [ "$INSTALL_PRODUCTIVITY" = false ] && \
     [ "$INSTALL_AI" = false ]; then
    warn "Nothing selected. Defaulting to Essentials."
    INSTALL_ESSENTIALS=true
  fi
}

# ─────────────────────────────────────────────
# CONFIRM SCREEN
# ─────────────────────────────────────────────
print_confirm() {
  echo -e "  ${BOLD}Here's what will be installed:${RESET}"
  blank

  [ "$INSTALL_ESSENTIALS" = true ]   && echo -e "  ${GREEN}✓${RESET} Essentials — Git, VS Code, Homebrew"
  [ "$INSTALL_WEB" = true ]          && echo -e "  ${GREEN}✓${RESET} Web Dev — Node.js (nvm), pnpm, Docker, Postman"
  [ "$INSTALL_PYTHON" = true ]       && echo -e "  ${GREEN}✓${RESET} Python — pyenv, Python 3, pipx"
  [ "$INSTALL_PRODUCTIVITY" = true ] && echo -e "  ${GREEN}✓${RESET} Productivity — Starship, bat, eza, fzf, GitHub CLI, Nerd Fonts"
  [ "$INSTALL_AI" = true ]           && echo -e "  ${GREEN}✓${RESET} AI CLI Tools — Gemini CLI, Claude Code"

  blank
  divider
  blank
  echo -e "  ${DIM}This may take 10–20 minutes depending on your connection.${RESET}"
  echo -e "  ${DIM}You may be asked for your Mac password — this is normal and safe.${RESET}"
  blank
  echo -ne "  ${BOLD}Ready to go? [Y/n]:${RESET} "
  read -r confirm

  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    blank
    info "No worries! Re-run anytime: curl -fsSL https://raw.githubusercontent.com/baraqfi/jumpstart/main/mac/setup.sh | bash"
    blank
    exit 0
  fi

  blank
}

# ─────────────────────────────────────────────
# HOMEBREW
# ─────────────────────────────────────────────
install_homebrew() {
  echo -e "  ${BOLD}Setting up Homebrew (package manager)...${RESET}"
  blank

  if has brew; then
    success "Homebrew already installed"
    info "Updating Homebrew..."
    run brew update --quiet
    success "Homebrew up to date"
  else
    info "Installing Homebrew..."
    echo -e "  ${DIM}You may be prompted for your Mac password.${RESET}"
    blank
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon Macs
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi

    success "Homebrew installed"
  fi

  blank
}

# ─────────────────────────────────────────────
# ESSENTIALS
# ─────────────────────────────────────────────
install_essentials() {
  echo -e "  ${BOLD}Installing Essentials...${RESET}"
  blank

  brew_install git "Git"

  # Git config
  if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
    blank
    echo -e "  ${BOLD}Let's set up your Git identity:${RESET}"
    echo -ne "  Your name (for Git commits): "
    read -r git_name
    echo -ne "  Your email (for Git commits): "
    read -r git_email
    run git config --global user.name "$git_name"
    run git config --global user.email "$git_email"
    run git config --global init.defaultBranch main
    success "Git configured"
    blank
  else
    success "Git already configured as: $(git config --global user.name)"
  fi

  brew_cask_install visual-studio-code "VS Code"

  # Add 'code' CLI command if not present
  if ! has code && [ "$DRY_RUN" = false ]; then
    info "Adding 'code' command to your terminal..."
    ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
  fi

  brew_install wget "wget"

  blank
}

# ─────────────────────────────────────────────
# WEB DEVELOPMENT
# ─────────────────────────────────────────────
install_web() {
  echo -e "  ${BOLD}Installing Web Development tools...${RESET}"
  blank

  # nvm (Node Version Manager)
  if [ -d "$HOME/.nvm" ]; then
    success "nvm already installed — skipping"
  else
    info "Installing nvm (Node Version Manager)..."
    run curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Load nvm immediately for this session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    success "nvm installed"
  fi

  # Ensure nvm is loaded
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Node.js LTS
  if has node; then
    success "Node.js $(node -v) already installed — skipping"
  else
    info "Installing Node.js LTS..."
    run nvm install --lts
    run nvm use --lts
    run nvm alias default node
    success "Node.js $(node -v 2>/dev/null || echo '') installed"
  fi

  # pnpm
  if has pnpm; then
    success "pnpm already installed — skipping"
  else
    info "Installing pnpm (fast package manager)..."
    run npm install -g pnpm
    success "pnpm installed"
  fi

  # Docker Desktop
  brew_cask_install docker "Docker Desktop"

  # Postman
  brew_cask_install postman "Postman"

  blank
}

# ─────────────────────────────────────────────
# PYTHON
# ─────────────────────────────────────────────
install_python() {
  echo -e "  ${BOLD}Installing Python tools...${RESET}"
  blank

  # pyenv
  if has pyenv; then
    success "pyenv already installed — skipping"
  else
    info "Installing pyenv (Python version manager)..."
    run brew install pyenv

    # Add pyenv to shell
    {
      echo ''
      echo '# pyenv'
      echo 'export PYENV_ROOT="$HOME/.pyenv"'
      echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
      echo 'eval "$(pyenv init -)"'
    } >> "$HOME/.zshrc"

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true

    success "pyenv installed"
  fi

  # Python 3 (latest stable)
  local python_version="3.12.4"
  if pyenv versions 2>/dev/null | grep -q "$python_version"; then
    success "Python $python_version already installed — skipping"
  else
    info "Installing Python $python_version (this may take a few minutes)..."
    run pyenv install "$python_version"
    run pyenv global "$python_version"
    success "Python $python_version installed and set as default"
  fi

  # pipx
  if has pipx; then
    success "pipx already installed — skipping"
  else
    info "Installing pipx (run Python tools in isolation)..."
    run brew install pipx
    run pipx ensurepath
    success "pipx installed"
  fi

  blank
}

# ─────────────────────────────────────────────
# PRODUCTIVITY
# ─────────────────────────────────────────────
install_productivity() {
  echo -e "  ${BOLD}Installing Productivity tools...${RESET}"
  blank

  # Starship prompt
  if has starship; then
    success "Starship prompt already installed — skipping"
  else
    info "Installing Starship prompt (makes your terminal beautiful)..."
    run brew install starship

    # Add to .zshrc if not already there
    if ! grep -q 'starship init' "$HOME/.zshrc" 2>/dev/null; then
      echo '' >> "$HOME/.zshrc"
      echo '# Starship prompt' >> "$HOME/.zshrc"
      echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    fi

    success "Starship installed"
  fi

  # Nerd Fonts (required for Starship icons)
  brew_cask_install font-jetbrains-mono-nerd-font "JetBrains Mono Nerd Font"

  # bat (better cat)
  brew_install bat "bat (better file viewer)"

  # eza (better ls)
  brew_install eza "eza (better directory listing)"

  # fzf (fuzzy finder)
  if has fzf; then
    success "fzf already installed — skipping"
  else
    info "Installing fzf (fuzzy finder — you'll love this)..."
    run brew install fzf
    run "$(brew --prefix)/opt/fzf/install" --all --no-update-rc 2>/dev/null || true
    success "fzf installed"
  fi

  # GitHub CLI
  brew_install gh "GitHub CLI"

  blank
}

# ─────────────────────────────────────────────
# AI CLI TOOLS
# ─────────────────────────────────────────────
install_ai() {
  echo -e "  ${BOLD}Installing AI CLI Tools...${RESET}"
  blank

  echo -e "  ${DIM}These tools require API keys to use — JumpStart will NOT handle${RESET}"
  echo -e "  ${DIM}your keys. After install, we'll show you exactly where to get them.${RESET}"
  blank

  # Node must be available for npm global installs
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  if ! has node; then
    warn "Node.js is required for AI CLI tools. Installing it first..."
    run nvm install --lts
    run nvm use --lts
  fi

  # Gemini CLI
  if npm list -g @google/gemini-cli &>/dev/null 2>&1; then
    success "Gemini CLI already installed — skipping"
  else
    info "Installing Gemini CLI (Google)..."
    run npm install -g @google/gemini-cli
    success "Gemini CLI installed"
  fi

  # Claude Code
  if npm list -g @anthropic-ai/claude-code &>/dev/null 2>&1; then
    success "Claude Code already installed — skipping"
  else
    info "Installing Claude Code (Anthropic)..."
    run npm install -g @anthropic-ai/claude-code
    success "Claude Code installed"
  fi

  blank
}

# ─────────────────────────────────────────────
# POST-INSTALL — AI KEYS GUIDE
# ─────────────────────────────────────────────
print_ai_keys_guide() {
  blank
  divider
  blank
  echo -e "  ${BOLD}${CYAN}🤖 Setting up your AI CLI tools:${RESET}"
  blank
  echo -e "  ${BOLD}Gemini CLI (free tier available)${RESET}"
  dim "  1. Visit: https://aistudio.google.com/apikey"
  dim "  2. Sign in with your Google account"
  dim "  3. Click 'Create API Key'"
  dim "  4. Run: gemini  (it will prompt you to paste your key)"
  blank
  echo -e "  ${BOLD}Claude Code (Anthropic)${RESET}"
  dim "  1. Visit: https://console.anthropic.com"
  dim "  2. Create an account and go to 'API Keys'"
  dim "  3. Click 'Create Key'"
  dim "  4. Run: claude  (it will prompt you to paste your key)"
  blank
  echo -e "  ${DIM}Your API keys are stored locally on your machine only.${RESET}"
  echo -e "  ${DIM}JumpStart never sees or touches them.${RESET}"
}

# ─────────────────────────────────────────────
# NEXT STEPS SCREEN
# ─────────────────────────────────────────────
print_next_steps() {
  blank
  echo -e "${BOLD}${GREEN}"
  echo "  ╔══════════════════════════════════════════════════════════╗"
  echo "  ║                                                          ║"
  echo "  ║   ✅  You're all set up! Welcome to the dev life.       ║"
  echo "  ║                                                          ║"
  echo "  ╚══════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  blank

  echo -e "  ${BOLD}First things to do:${RESET}"
  blank
  echo -e "  ${CYAN}1.${RESET} Restart your terminal (or run: ${CYAN}exec \$SHELL${RESET})"
  echo -e "  ${CYAN}2.${RESET} Open VS Code anywhere by typing: ${CYAN}code .${RESET}"
  [ "$INSTALL_WEB" = true ]  && echo -e "  ${CYAN}3.${RESET} Check Node.js: ${CYAN}node -v${RESET}"
  [ "$INSTALL_PYTHON" = true ] && echo -e "  ${CYAN}4.${RESET} Check Python: ${CYAN}python --version${RESET}"
  [ "$INSTALL_PRODUCTIVITY" = true ] && echo -e "  ${CYAN}5.${RESET} Set your terminal font to ${BOLD}JetBrains Mono Nerd Font${RESET} to see Starship icons"

  [ "$INSTALL_AI" = true ] && print_ai_keys_guide

  blank
  divider
  blank
  echo -e "  ${DIM}📋 Full install log saved to: ~/jumpstart-install.log${RESET}"
  echo -e "  ${DIM}⭐ Found this useful? Star us: github.com/baraqfi/jumpstart${RESET}"
  echo -e "  ${DIM}🐛 Issues? github.com/baraqfi/jumpstart/issues${RESET}"
  blank
}

# ─────────────────────────────────────────────
# SECTION HEADER
# ─────────────────────────────────────────────
section() {
  blank
  divider
  blank
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
main() {
  # Init log
  echo "JumpStart install started at $(date)" > "$LOG_FILE"

  # Show help if requested
  [ "${SHOW_HELP:-false}" = true ] && print_help

  print_welcome
  check_system

  # Interactive or flag-based selection
  if [ "$INTERACTIVE" = true ]; then
    interactive_menu
    blank
    print_confirm
  else
    # If --all flag was passed, set everything
    if [ "$INSTALL_ALL" = true ]; then
      INSTALL_ESSENTIALS=true
      INSTALL_WEB=true
      INSTALL_PYTHON=true
      INSTALL_PRODUCTIVITY=true
      INSTALL_AI=true
    fi
    print_confirm
  fi

  # Always install Homebrew first
  section
  install_homebrew

  # Install selected categories
  [ "$INSTALL_ESSENTIALS" = true ]   && { section; install_essentials; }
  [ "$INSTALL_WEB" = true ]          && { section; install_web; }
  [ "$INSTALL_PYTHON" = true ]       && { section; install_python; }
  [ "$INSTALL_PRODUCTIVITY" = true ] && { section; install_productivity; }
  [ "$INSTALL_AI" = true ]           && { section; install_ai; }

  # Done!
  print_next_steps

  echo "JumpStart install completed at $(date)" >> "$LOG_FILE"
}

main "$@"
