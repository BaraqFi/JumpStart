# =============================================================================
#     ██╗██╗   ██╗███╗   ███╗██████╗ ███████╗████████╗ █████╗ ██████╗ ████████╗
#     ██║██║   ██║████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝
#     ██║██║   ██║██╔████╔██║██████╔╝███████╗   ██║   ███████║██████╔╝   ██║
#██   ██║██║   ██║██║╚██╔╝██║██╔═══╝ ╚════██║   ██║   ██╔══██║██╔══██╗   ██║
#╚█████╔╝╚██████╔╝██║ ╚═╝ ██║██║     ███████║   ██║   ██║  ██║██║  ██║   ██║
# ╚════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
# =============================================================================
#  JumpStart - Windows Developer Setup
#  https://github.com/baraqfi/jumpstart
#  Open source. Beginner friendly. One command.
# =============================================================================
#
#  HOW TO RUN (in PowerShell as Administrator):
#  irm https://raw.githubusercontent.com/baraqfi/jumpstart/main/windows/setup.ps1 | iex
#
#  WITH FLAGS:
#  $env:JS_FLAGS="--web --python"; irm https://...setup.ps1 | iex
#
# =============================================================================

#Requires -Version 5.1

# Bypass execution policy for this process only (safe, temporary)
if ($MyInvocation.InvocationName -ne '') {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
}

# ─────────────────────────────────────────────
# FLAGS
# ─────────────────────────────────────────────
$flagString = $env:JS_FLAGS + " " + ($args -join " ")
$flags = $flagString.ToLower().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)

$Interactive         = $true
$InstallEssentials   = $false
$InstallWeb          = $false
$InstallPython       = $false
$InstallProductivity = $false
$InstallAI           = $false
$InstallLinux        = $false
$DryRun              = $false
$ShowHelp            = $false
$RestartRequired     = $false

foreach ($flag in $flags) {
    switch ($flag) {
        "--essentials"   { $InstallEssentials   = $true; $Interactive = $false }
        "--web"          { $InstallWeb           = $true; $Interactive = $false }
        "--python"       { $InstallPython        = $true; $Interactive = $false }
        "--productivity" { $InstallProductivity  = $true; $Interactive = $false }
        "--ai"           { $InstallAI            = $true; $Interactive = $false }
        "--linux"        { $InstallLinux         = $true; $Interactive = $false }
        "--all"          {
            $InstallEssentials = $InstallWeb = $InstallPython = $true
            $InstallProductivity = $InstallAI = $InstallLinux = $true
            $Interactive = $false
        }
        "--dry-run"      { $DryRun   = $true }
        "--help"         { $ShowHelp = $true }
    }
}

# ─────────────────────────────────────────────
# LOG FILE
# ─────────────────────────────────────────────
$LogFile = "$env:USERPROFILE\jumpstart-install.log"

# ─────────────────────────────────────────────
# COLORS
# ─────────────────────────────────────────────
$ESC    = [char]27
$RESET  = "$ESC[0m"
$BOLD   = "$ESC[1m"
$DIM    = "$ESC[2m"
$CYAN   = "$ESC[36m"
$GREEN  = "$ESC[32m"
$YELLOW = "$ESC[33m"
$RED    = "$ESC[31m"
$WHITE  = "$ESC[37m"

# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────
function Write-Log($msg) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Add-Content -Path $LogFile
}

function Info($msg)    { Write-Host "  $CYAN->$RESET $msg"; Write-Log "INFO: $msg" }
function Success($msg) { Write-Host "  $GREEN+$RESET $msg"; Write-Log "OK:   $msg" }
function Warn($msg)    { Write-Host "  $YELLOW!$RESET $msg"; Write-Log "WARN: $msg" }
function Err($msg)     { Write-Host "  $RED x$RESET $msg"; Write-Log "ERR:  $msg" }
function Dim($msg)     { Write-Host "  $DIM$msg$RESET" }
function Blank()       { Write-Host "" }
function Divider()     { Write-Host "  $DIM------------------------------------------------------------$RESET" }

function Has($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Winget-Install($id, $label) {
    $installed = winget list --id $id --exact 2>$null | Select-String $id
    if ($installed) {
        Success "$label already installed - skipping"
    } else {
        Info "Installing $label..."
        if ($DryRun) {
            Write-Host "  $DIM[dry-run] winget install --id $id --silent$RESET"
        } else {
            winget install --id $id --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
                Success "$label installed"
            } else {
                Warn "$label may have had issues (exit: $LASTEXITCODE) - check log"
            }
        }
        Write-Log "WINGET: $id"
    }
}

function Choco-Install($pkg, $label) {
    if (-not (Has "choco")) {
        Warn "Chocolatey not available - skipping $label"
        return
    }
    $installed = choco list --local-only $pkg 2>$null | Select-String "^$pkg "
    if ($installed) {
        Success "$label already installed - skipping"
    } else {
        Info "Installing $label via Chocolatey..."
        if ($DryRun) {
            Write-Host "  $DIM[dry-run] choco install $pkg -y$RESET"
        } else {
            choco install $pkg -y
            Success "$label installed"
        }
        Write-Log "CHOCO: $pkg"
    }
}

# ─────────────────────────────────────────────
# WELCOME SCREEN
# ─────────────────────────────────────────────
function Print-Welcome {
    Clear-Host
    Write-Host ""
    Write-Host "  $BOLD$CYAN+=========================================================+"
    Write-Host "  |                                                         |"
    Write-Host "  |   JUMPSTART - Windows Developer Setup  v1.0.0          |"
    Write-Host "  |                                                         |"
    Write-Host "  |   Your Windows PC. Set up in minutes.                  |"
    Write-Host "  |   Made for beginners. Open source.                     |"
    Write-Host "  |                                                         |"
    Write-Host "  |   github.com/baraqfi/jumpstart                         |"
    Write-Host "  |                                                         |"
    Write-Host "  +=========================================================+$RESET"
    Write-Host ""

    if ($DryRun) {
        Write-Host "  $YELLOW[DRY RUN MODE]$RESET $YELLOW Nothing will actually be installed.$RESET"
        Blank
    }
}

# ─────────────────────────────────────────────
# HELP SCREEN
# ─────────────────────────────────────────────
function Print-Help {
    Print-Welcome
    Write-Host "  ${BOLD}Usage:$RESET"
    Blank
    Dim "  Run interactively (recommended):"
    Write-Host "  $CYAN irm https://raw.githubusercontent.com/baraqfi/jumpstart/main/windows/setup.ps1 | iex$RESET"
    Blank
    Dim "  Run with flags:"
    Write-Host "  $CYAN `$env:JS_FLAGS='--web --python'; irm https://...setup.ps1 | iex$RESET"
    Blank
    Write-Host "  ${BOLD}Available flags:$RESET"
    Blank
    Write-Host "    $GREEN--essentials$RESET     Git, VS Code, Windows Terminal, Git Bash"
    Write-Host "    $GREEN--web$RESET            Node.js (nvm-windows), pnpm, Docker Desktop, Postman"
    Write-Host "    $GREEN--python$RESET         Python 3 (pyenv-win), pipx"
    Write-Host "    $GREEN--productivity$RESET   Starship, bat, eza, fzf, GitHub CLI, Nerd Fonts"
    Write-Host "    $GREEN--ai$RESET             Gemini CLI, Claude Code"
    Write-Host "    $GREEN--linux$RESET          WSL2 + Ubuntu, Chocolatey  $YELLOW[Windows only]$RESET"
    Write-Host "    $GREEN--all$RESET            Everything above"
    Write-Host "    $GREEN--dry-run$RESET        Preview what would be installed"
    Write-Host "    $GREEN--help$RESET           Show this screen"
    Blank
    Dim "  Docs: https://github.com/baraqfi/jumpstart"
    Blank
    exit 0
}

# ─────────────────────────────────────────────
# SYSTEM CHECK
# ─────────────────────────────────────────────
function Check-System {
    Write-Host "  ${BOLD}Checking your system...$RESET"
    Blank

    $winVer = (Get-CimInstance Win32_OperatingSystem).Caption
    Success "$winVer detected"

    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        Err "PowerShell 5.1 or higher is required. Please update Windows."
        exit 1
    }
    Success "PowerShell $($psVersion.Major).$($psVersion.Minor) ready"

    # Admin check
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Blank
        Write-Host "  $YELLOW  Not running as Administrator.$RESET"
        Write-Host "  $YELLOW  Some installs (Docker, WSL2) require admin rights.$RESET"
        Write-Host "  $YELLOW  For best results: close this, right-click PowerShell ->$RESET"
        Write-Host "  $YELLOW  'Run as Administrator', then re-run JumpStart.$RESET"
        Blank
        Write-Host -NoNewline "  Continue anyway? [y/N]: "
        $cont = Read-Host
        if ($cont -notmatch '^[Yy]$') {
            Info "Re-run as Administrator when ready."
            exit 0
        }
    } else {
        Success "Running as Administrator"
    }

    # Internet check
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5
        Success "Internet connection confirmed"
    } catch {
        Err "No internet connection. Please connect and try again."
        exit 1
    }

    # winget check
    if (Has "winget") {
        Success "winget (Windows Package Manager) ready"
    } else {
        Warn "winget not found - attempting to install..."
        Dim "  winget ships with Windows 11 and updated Windows 10."
        Dim "  If this fails, visit: https://aka.ms/getwinget"
        Blank
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
            Refresh-Path
            Success "winget installed"
        } catch {
            Err "Could not auto-install winget."
            Err "Please install it from https://aka.ms/getwinget then re-run JumpStart."
            exit 1
        }
    }

    Blank
}

# ─────────────────────────────────────────────
# INTERACTIVE MENU
# ─────────────────────────────────────────────
function Print-Menu {
    Write-Host "  ${BOLD}What would you like to install?$RESET"
    Dim "  Enter numbers separated by spaces, or A for all."
    Blank

    Write-Host "  $BOLD${GREEN}[1]$RESET ${BOLD}Essentials$RESET $DIM(recommended)$RESET"
    Dim "      Git, VS Code"
    Write-Host "  $DIM      + Windows Terminal, Git Bash  $YELLOW[Windows only]$RESET"
    Blank

    Write-Host "  $BOLD${GREEN}[2]$RESET ${BOLD}Web Development$RESET"
    Dim "      Node.js, pnpm, Docker Desktop, Postman"
    Dim "      installed via nvm-windows + winget"
    Blank

    Write-Host "  $BOLD${GREEN}[3]$RESET ${BOLD}Python$RESET"
    Dim "      Python 3, pipx"
    Dim "      installed via pyenv-win"
    Blank

    Write-Host "  $BOLD${GREEN}[4]$RESET ${BOLD}Productivity Tools$RESET"
    Dim "      Starship prompt, bat, eza, fzf, GitHub CLI, Nerd Fonts"
    Dim "      installed via winget + Chocolatey"
    Blank

    Write-Host "  $BOLD${GREEN}[5]$RESET ${BOLD}AI CLI Tools$RESET $DIM(you'll add your own API keys after)$RESET"
    Dim "      Gemini CLI (Google), Claude Code (Anthropic)"
    Blank

    Write-Host "  $BOLD${GREEN}[6]$RESET ${BOLD}Linux on Windows$RESET $YELLOW[Windows only]$RESET"
    Dim "      WSL2 + Ubuntu - run bash & unix commands natively"
    Dim "      Chocolatey - wider package manager (complements winget)"
    Write-Host "  $DIM      $YELLOW  Requires a restart to complete WSL2 setup$RESET"
    Blank

    Write-Host "  $BOLD${CYAN}[A]$RESET ${BOLD}Install Everything$RESET"
    Blank
    Divider
    Blank
}

function Interactive-Menu {
    Print-Menu

    Write-Host -NoNewline "  Enter your choices $DIM(e.g. 1 2 6)$RESET, or ${CYAN}A$RESET for all: "
    $userInput = Read-Host

    Blank

    if ($userInput -match '[Aa]') {
        $script:InstallEssentials   = $true
        $script:InstallWeb          = $true
        $script:InstallPython       = $true
        $script:InstallProductivity = $true
        $script:InstallAI           = $true
        $script:InstallLinux        = $true
        return
    }

    $tokens = $userInput -split '\s+'
    foreach ($token in $tokens) {
        switch ($token.Trim()) {
            "1" { $script:InstallEssentials   = $true }
            "2" { $script:InstallWeb          = $true }
            "3" { $script:InstallPython       = $true }
            "4" { $script:InstallProductivity = $true }
            "5" { $script:InstallAI           = $true }
            "6" { $script:InstallLinux        = $true }
        }
    }

    if (-not ($InstallEssentials -or $InstallWeb -or $InstallPython -or
              $InstallProductivity -or $InstallAI -or $InstallLinux)) {
        Warn "Nothing selected. Defaulting to Essentials."
        $script:InstallEssentials = $true
    }
}

# ─────────────────────────────────────────────
# CONFIRM SCREEN
# ─────────────────────────────────────────────
function Print-Confirm {
    Write-Host "  ${BOLD}Here's what will be installed:$RESET"
    Blank

    if ($InstallEssentials)   { Write-Host "  $GREEN+$RESET Essentials - Git, VS Code, Windows Terminal, Git Bash" }
    if ($InstallWeb)          { Write-Host "  $GREEN+$RESET Web Dev - Node.js (nvm-windows), pnpm, Docker Desktop, Postman" }
    if ($InstallPython)       { Write-Host "  $GREEN+$RESET Python - pyenv-win, Python 3, pipx" }
    if ($InstallProductivity) { Write-Host "  $GREEN+$RESET Productivity - Starship, bat, eza, fzf, GitHub CLI, Nerd Fonts" }
    if ($InstallAI)           { Write-Host "  $GREEN+$RESET AI CLI Tools - Gemini CLI, Claude Code" }
    if ($InstallLinux)        { Write-Host "  $GREEN+$RESET Linux on Windows - WSL2 + Ubuntu, Chocolatey $YELLOW(restart required after)$RESET" }

    Blank
    Divider
    Blank
    Dim "  This may take 10-20 minutes depending on your connection."
    Dim "  Some tools may open installer windows - follow any prompts."
    if ($InstallLinux) {
        Write-Host "  $YELLOW  WSL2 is installed last. A restart will be needed to finish it.$RESET"
    }
    Blank
    Write-Host -NoNewline "  ${BOLD}Ready to go? [Y/n]:$RESET "
    $confirm = Read-Host

    if ($confirm -match '^[Nn]$') {
        Blank
        Info "No worries! Re-run anytime."
        Blank
        exit 0
    }

    Blank
}

# ─────────────────────────────────────────────
# ESSENTIALS
# ─────────────────────────────────────────────
function Install-Essentials {
    Write-Host "  ${BOLD}Installing Essentials...$RESET"
    Blank

    # Git installs Git Bash as part of the package
    Info "Installing Git (includes Git Bash for unix/bash commands)..."
    Winget-Install "Git.Git" "Git + Git Bash"
    Refresh-Path

    # Git config
    if (Has "git") {
        $existingName = git config --global user.name 2>$null
        if (-not $existingName) {
            Blank
            Write-Host "  ${BOLD}Let's set up your Git identity:$RESET"
            Write-Host -NoNewline "  Your name (for Git commits): "
            $gitName = Read-Host
            Write-Host -NoNewline "  Your email (for Git commits): "
            $gitEmail = Read-Host
            if (-not $DryRun) {
                git config --global user.name "$gitName"
                git config --global user.email "$gitEmail"
                git config --global init.defaultBranch main
            }
            Success "Git configured"
            Blank
        } else {
            Success "Git already configured as: $existingName"
        }
    }

    Winget-Install "Microsoft.VisualStudioCode" "VS Code"
    Winget-Install "Microsoft.WindowsTerminal" "Windows Terminal"

    Blank
    Write-Host "  $DIM  Git Bash tip: find it in your Start menu as 'Git Bash'.$RESET"
    Write-Host "  $DIM  It gives you ls, cat, grep and other unix commands on Windows.$RESET"
    Blank
}

# ─────────────────────────────────────────────
# WEB DEVELOPMENT
# ─────────────────────────────────────────────
function Install-Web {
    Write-Host "  ${BOLD}Installing Web Development tools...$RESET"
    Blank

    if (Has "nvm") {
        Success "nvm-windows already installed - skipping"
    } else {
        Winget-Install "CoreyButler.NVMforWindows" "nvm-windows"
        Refresh-Path
    }

    if (Has "node") {
        Success "Node.js $(node -v 2>$null) already installed - skipping"
    } elseif (Has "nvm") {
        Info "Installing Node.js LTS..."
        if (-not $DryRun) {
            nvm install lts
            nvm use lts
            Refresh-Path
            Success "Node.js installed"
        } else {
            Write-Host "  $DIM[dry-run] nvm install lts && nvm use lts$RESET"
        }
    } else {
        Warn "nvm not yet in PATH - restart PowerShell then run: nvm install lts"
    }

    if (Has "pnpm") {
        Success "pnpm already installed - skipping"
    } elseif (Has "npm") {
        Info "Installing pnpm..."
        if (-not $DryRun) { npm install -g pnpm }
        else { Write-Host "  $DIM[dry-run] npm install -g pnpm$RESET" }
        Success "pnpm installed"
    } else {
        Warn "npm not yet available - install pnpm later with: npm install -g pnpm"
    }

    Winget-Install "Docker.DockerDesktop" "Docker Desktop"
    Winget-Install "Postman.Postman" "Postman"

    Blank
}

# ─────────────────────────────────────────────
# PYTHON
# ─────────────────────────────────────────────
function Install-Python {
    Write-Host "  ${BOLD}Installing Python tools...$RESET"
    Blank

    if (Has "pyenv") {
        Success "pyenv-win already installed - skipping"
    } else {
        Winget-Install "PyPA.Pyenv-win" "pyenv-win"

        $pyenvPath = "$env:USERPROFILE\.pyenv\pyenv-win"
        [System.Environment]::SetEnvironmentVariable("PYENV",      $pyenvPath, "User")
        [System.Environment]::SetEnvironmentVariable("PYENV_ROOT", $pyenvPath, "User")
        [System.Environment]::SetEnvironmentVariable("PYENV_HOME", $pyenvPath, "User")

        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notmatch "pyenv") {
            [System.Environment]::SetEnvironmentVariable(
                "Path",
                "$pyenvPath\bin;$pyenvPath\shims;$currentPath",
                "User"
            )
        }
        Refresh-Path
    }

    $pythonVersion = "3.12.4"
    if (Has "python") {
        Success "Python ($(python --version 2>$null)) already installed - skipping"
    } elseif (Has "pyenv") {
        Info "Installing Python $pythonVersion (this may take a few minutes)..."
        if (-not $DryRun) {
            pyenv install $pythonVersion
            pyenv global $pythonVersion
            Refresh-Path
            Success "Python $pythonVersion set as default"
        } else {
            Write-Host "  $DIM[dry-run] pyenv install $pythonVersion && pyenv global $pythonVersion$RESET"
        }
    } else {
        Warn "pyenv not yet in PATH - restart PowerShell then run: pyenv install $pythonVersion"
    }

    if (Has "pipx") {
        Success "pipx already installed - skipping"
    } elseif (Has "pip") {
        Info "Installing pipx..."
        if (-not $DryRun) {
            pip install --user pipx
            python -m pipx ensurepath
        } else {
            Write-Host "  $DIM[dry-run] pip install --user pipx$RESET"
        }
        Success "pipx installed"
    } else {
        Warn "pip not yet available - install pipx later with: pip install --user pipx"
    }

    Blank
}

# ─────────────────────────────────────────────
# PRODUCTIVITY
# ─────────────────────────────────────────────
function Install-Productivity {
    Write-Host "  ${BOLD}Installing Productivity tools...$RESET"
    Blank

    if (Has "starship") {
        Success "Starship prompt already installed - skipping"
    } else {
        Winget-Install "Starship.Starship" "Starship prompt"
        Refresh-Path

        $profileDir = Split-Path $PROFILE
        if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
        if (-not (Test-Path $PROFILE))    { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }

        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($profileContent -notmatch 'starship') {
            if (-not $DryRun) {
                Add-Content -Path $PROFILE -Value "`n# Starship prompt`nInvoke-Expression (&starship init powershell)"
            }
        }
        Success "Starship installed and added to PowerShell profile"
    }

    Winget-Install "DEVCOM.JetBrainsMonoNerdFont" "JetBrains Mono Nerd Font"

    # bat - winget first, choco fallback
    if (Has "bat") {
        Success "bat already installed - skipping"
    } else {
        Info "Installing bat (better file viewer)..."
        if ($DryRun) {
            Write-Host "  $DIM[dry-run] winget install sharkdp.bat$RESET"
        } else {
            winget install --id sharkdp.bat --silent --accept-package-agreements --accept-source-agreements 2>$null
            if ($LASTEXITCODE -ne 0) { Choco-Install "bat" "bat" }
            else { Refresh-Path; Success "bat installed" }
        }
    }

    # eza - winget first, choco fallback
    if (Has "eza") {
        Success "eza already installed - skipping"
    } else {
        Info "Installing eza (better directory listing)..."
        if ($DryRun) {
            Write-Host "  $DIM[dry-run] winget install eza-community.eza$RESET"
        } else {
            winget install --id eza-community.eza --silent --accept-package-agreements --accept-source-agreements 2>$null
            if ($LASTEXITCODE -ne 0) { Choco-Install "eza" "eza" }
            else { Refresh-Path; Success "eza installed" }
        }
    }

    Winget-Install "junegunn.fzf" "fzf (fuzzy finder)"
    Winget-Install "GitHub.cli" "GitHub CLI"

    Blank
}

# ─────────────────────────────────────────────
# AI CLI TOOLS
# ─────────────────────────────────────────────
function Install-AI {
    Write-Host "  ${BOLD}Installing AI CLI Tools...$RESET"
    Blank

    Write-Host "  $DIM  These tools require API keys - JumpStart will NOT handle your keys.$RESET"
    Write-Host "  $DIM  After install, we'll show you exactly where to get them.$RESET"
    Blank

    Refresh-Path

    if (-not (Has "npm")) {
        Warn "Node.js/npm is required for AI CLI tools."
        Warn "Select Web Dev (option 2) first, then re-run with --ai"
        Blank
        return
    }

    $geminiCheck = npm list -g @google/gemini-cli 2>$null | Select-String "gemini-cli"
    if ($geminiCheck) {
        Success "Gemini CLI already installed - skipping"
    } else {
        Info "Installing Gemini CLI (Google)..."
        if (-not $DryRun) { npm install -g @google/gemini-cli }
        else { Write-Host "  $DIM[dry-run] npm install -g @google/gemini-cli$RESET" }
        Success "Gemini CLI installed"
    }

    $claudeCheck = npm list -g @anthropic-ai/claude-code 2>$null | Select-String "claude-code"
    if ($claudeCheck) {
        Success "Claude Code already installed - skipping"
    } else {
        Info "Installing Claude Code (Anthropic)..."
        if (-not $DryRun) { npm install -g @anthropic-ai/claude-code }
        else { Write-Host "  $DIM[dry-run] npm install -g @anthropic-ai/claude-code$RESET" }
        Success "Claude Code installed"
    }

    Blank
}

# ─────────────────────────────────────────────
# LINUX ON WINDOWS
# ─────────────────────────────────────────────
function Install-Linux {
    Write-Host "  ${BOLD}Installing Linux on Windows...$RESET"
    Blank

    # ── CHOCOLATEY ──────────────────────────────
    Write-Host "  ${BOLD}Setting up Chocolatey (package manager)...$RESET"
    Blank

    if (Has "choco") {
        Success "Chocolatey already installed - skipping"
    } else {
        Info "Installing Chocolatey..."
        if ($DryRun) {
            Write-Host "  $DIM[dry-run] Install-Chocolatey$RESET"
        } else {
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                Refresh-Path
                Success "Chocolatey installed"
            } catch {
                Warn "Chocolatey install failed: $_"
                Warn "Install manually at: https://chocolatey.org/install"
            }
        }
    }

    Blank

    # ── WSL2 ────────────────────────────────────
    Write-Host "  ${BOLD}Setting up WSL2 + Ubuntu...$RESET"
    Blank

    Dim "  WSL2 (Windows Subsystem for Linux) gives you a full bash/Linux"
    Dim "  environment directly inside Windows - no dual boot needed."
    Dim "  After setup, open 'Ubuntu' from your Start menu to use it."
    Blank

    $wslAlreadyOn = $false
    try {
        $wslList = wsl --list 2>$null
        if ($wslList -match "Ubuntu") { $wslAlreadyOn = $true }
    } catch {}

    if ($wslAlreadyOn) {
        Success "WSL2 + Ubuntu already installed - skipping"
    } else {
        Info "Enabling WSL2..."
        Write-Host ""
        Write-Host "  $YELLOW  WSL2 will be enabled and Ubuntu will be installed.$RESET"
        Write-Host "  $YELLOW  A restart is required to finish - JumpStart will prompt you.$RESET"
        Blank

        if ($DryRun) {
            Write-Host "  $DIM[dry-run] dism /enable-feature Microsoft-Windows-Subsystem-Linux$RESET"
            Write-Host "  $DIM[dry-run] dism /enable-feature VirtualMachinePlatform$RESET"
            Write-Host "  $DIM[dry-run] wsl --set-default-version 2$RESET"
            Write-Host "  $DIM[dry-run] wsl --install -d Ubuntu$RESET"
        } else {
            try {
                dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
                dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
                wsl --set-default-version 2 2>$null
                wsl --install -d Ubuntu
                $script:RestartRequired = $true
                Success "WSL2 + Ubuntu install initiated - restart required to finish"
            } catch {
                Warn "WSL2 install encountered an issue: $_"
                Warn "Try manually: open PowerShell as Admin and run: wsl --install -d Ubuntu"
            }
        }
    }

    Blank
}

# ─────────────────────────────────────────────
# AI KEYS GUIDE
# ─────────────────────────────────────────────
function Print-AIKeysGuide {
    Blank
    Divider
    Blank
    Write-Host "  $BOLD${CYAN}Setting up your AI CLI tools:$RESET"
    Blank
    Write-Host "  ${BOLD}Gemini CLI (free tier available)$RESET"
    Dim "  1. Visit: https://aistudio.google.com/apikey"
    Dim "  2. Sign in with your Google account"
    Dim "  3. Click 'Create API Key'"
    Dim "  4. Run: gemini  (it will prompt you to paste your key)"
    Blank
    Write-Host "  ${BOLD}Claude Code (Anthropic)$RESET"
    Dim "  1. Visit: https://console.anthropic.com"
    Dim "  2. Create an account and go to 'API Keys'"
    Dim "  3. Click 'Create Key'"
    Dim "  4. Run: claude  (it will prompt you to paste your key)"
    Blank
    Dim "  Your API keys are stored locally on your machine only."
    Dim "  JumpStart never sees or touches them."
}

# ─────────────────────────────────────────────
# NEXT STEPS
# ─────────────────────────────────────────────
function Print-NextSteps {
    Blank
    Write-Host "  $BOLD$GREEN+=========================================================+"
    Write-Host "  |                                                         |"
    Write-Host "  |   You're all set up! Welcome to the dev life.          |"
    Write-Host "  |                                                         |"
    Write-Host "  +=========================================================+$RESET"
    Blank

    Write-Host "  ${BOLD}First things to do:$RESET"
    Blank
    Write-Host "  $CYAN 1.$RESET Close and reopen PowerShell so all tools are recognized"
    Write-Host "  $CYAN 2.$RESET Open VS Code anywhere by typing: $CYAN code .$RESET"
    if ($InstallEssentials)   { Write-Host "  $CYAN 3.$RESET Find 'Git Bash' in Start menu for unix/bash commands" }
    if ($InstallWeb)          { Write-Host "  $CYAN 4.$RESET Check Node.js: $CYAN node -v$RESET" }
    if ($InstallPython)       { Write-Host "  $CYAN 5.$RESET Check Python: $CYAN python --version$RESET" }
    if ($InstallProductivity) { Write-Host "  $CYAN 6.$RESET Set terminal font to ${BOLD}JetBrains Mono Nerd Font$RESET for Starship icons" }

    if ($InstallLinux) {
        Blank
        Write-Host "  $YELLOW  WSL2 requires a restart to fully activate.$RESET"
        Write-Host "  $YELLOW  After restarting:$RESET"
        Write-Host "  $YELLOW  -> Open 'Ubuntu' from Start menu to finish Linux setup$RESET"
        Write-Host "  $YELLOW  -> Create a Linux username and password when prompted$RESET"
        Write-Host "  $YELLOW  -> Then run: sudo apt update && sudo apt upgrade$RESET"
        Write-Host "  $YELLOW  -> You can now use bash, grep, ls, curl and all unix commands$RESET"
    }

    if ($InstallAI) { Print-AIKeysGuide }

    Blank
    Divider
    Blank
    Dim "  Full install log saved to: $LogFile"
    Dim "  Found this useful? Star us: github.com/baraqfi/jumpstart"
    Dim "  Issues? github.com/baraqfi/jumpstart/issues"
    Blank
}

# ─────────────────────────────────────────────
# SECTION BREAK
# ─────────────────────────────────────────────
function Section {
    Blank
    Divider
    Blank
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
function Main {
    "JumpStart install started at $(Get-Date)" | Set-Content -Path $LogFile

    if ($ShowHelp) { Print-Help }

    Print-Welcome
    Check-System

    if ($Interactive) {
        Interactive-Menu
        Blank
        Print-Confirm
    } else {
        Print-Confirm
    }

    # WSL2 always goes last - it needs a restart and shouldn't block other installs
    if ($InstallEssentials)   { Section; Install-Essentials }
    if ($InstallWeb)          { Section; Install-Web }
    if ($InstallPython)       { Section; Install-Python }
    if ($InstallProductivity) { Section; Install-Productivity }
    if ($InstallAI)           { Section; Install-AI }
    if ($InstallLinux)        { Section; Install-Linux }

    Print-NextSteps

    "JumpStart install completed at $(Get-Date)" | Add-Content -Path $LogFile

    # Restart prompt if WSL2 was newly installed
    if ($script:RestartRequired) {
        Blank
        Write-Host "  $YELLOW${BOLD}  A restart is required to finish WSL2 setup.$RESET"
        Write-Host -NoNewline "  Restart now? [y/N]: "
        $restartNow = Read-Host
        if ($restartNow -match '^[Yy]$') {
            Restart-Computer -Force
        } else {
            Write-Host "  $DIM  Remember to restart before opening Ubuntu.$RESET"
        }
    }
}

Main
