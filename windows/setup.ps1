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
$GitConfigSkipped    = $false

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
# PROGRESS TRACKING
# ─────────────────────────────────────────────
# Step counts per section. Each count = the number of discrete install
# actions in that section (one per package / named install call).
#
#   Essentials   : Git, VS Code, Windows Terminal                        = 3
#   Web          : nvm-windows, Node.js, pnpm, Docker Desktop, Postman  = 5
#   Python       : pyenv-win, Python, pipx                              = 3
#   Productivity : Starship, Nerd Font, bat, eza, fzf, GitHub CLI       = 6
#   AI           : Gemini CLI, Claude Code                              = 2
#   Linux        : Chocolatey, WSL2+Ubuntu                              = 2
$StepCounts = @{
    Essentials   = 3
    Web          = 5
    Python       = 3
    Productivity = 6
    AI           = 2
    Linux        = 2
}

$script:ProgressTotal   = 0
$script:ProgressCurrent = 0

function Compute-ProgressTotal {
    $t = 0
    if ($InstallEssentials)   { $t += $StepCounts.Essentials }
    if ($InstallWeb)          { $t += $StepCounts.Web }
    if ($InstallPython)       { $t += $StepCounts.Python }
    if ($InstallProductivity) { $t += $StepCounts.Productivity }
    if ($InstallAI)           { $t += $StepCounts.AI }
    if ($InstallLinux)        { $t += $StepCounts.Linux }
    $script:ProgressTotal = [Math]::Max($t, 1)
}

# Advance the counter and return a right-aligned "[XX%]" tag.
function Step-Progress {
    $script:ProgressCurrent++
    $pct    = [Math]::Min([Math]::Round(($script:ProgressCurrent / $script:ProgressTotal) * 100), 100)
    $padded = "$pct%".PadLeft(4)
    return "$DIM[$padded]$RESET"
}

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

# ── Winget-Install ───────────────────────────────────────────────────────────
# Advances progress, then either dry-runs (no real system calls) or installs.
function Winget-Install($id, $label) {
    $pct = Step-Progress

    if ($DryRun) {
        Write-Host "  $CYAN->$RESET $pct $DIM[dry-run]$RESET Would install: $BOLD$label$RESET"
        Write-Host "        $DIM winget install --id $id --silent --accept-package-agreements --accept-source-agreements$RESET"
        Write-Log "DRY-RUN WINGET: $id"
        return
    }

    $installed = winget list --id $id --exact 2>$null | Select-String $id
    if ($installed) {
        Success "$label already installed - skipping $DIM$pct$RESET"
    } else {
        Write-Host "  $CYAN->$RESET $pct Installing $label..."
        Write-Log "INFO: Installing $label"
        winget install --id $id --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
            Success "$label installed"
        } else {
            Warn "$label may have had issues (exit: $LASTEXITCODE) - check log"
        }
        Write-Log "WINGET: $id"
    }
}

# ── Choco-Install ────────────────────────────────────────────────────────────
# Fallback only — caller already advanced the progress counter.
# In dry-run: just prints the command that would run.
function Choco-Install($pkg, $label) {
    if ($DryRun) {
        Write-Host "        $DIM[dry-run fallback] choco install $pkg -y$RESET"
        Write-Log "DRY-RUN CHOCO: $pkg"
        return
    }

    if (-not (Has "choco")) {
        Warn "Chocolatey not available - skipping $label"
        return
    }
    $installed = choco list --local-only $pkg 2>$null | Select-String "^$pkg "
    if ($installed) {
        Success "$label already installed - skipping"
    } else {
        Info "Installing $label via Chocolatey..."
        choco install $pkg -y
        Success "$label installed"
        Write-Log "CHOCO: $pkg"
    }
}

# ── Install-Step ─────────────────────────────────────────────────────────────
# For steps that aren't simple winget installs (scripted installs, npm, etc.).
# Advances progress and prints the "-> [XX%] label..." line.
# The caller is responsible for the actual work and any Success/Warn output.
function Install-Step($label) {
    $pct = Step-Progress
    Write-Host "  $CYAN->$RESET $pct $label..."
    Write-Log "INFO: $label"
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
        Write-Host "  $YELLOW${BOLD}[DRY RUN MODE]$RESET $YELLOW Nothing will actually be installed.$RESET"
        Write-Host "  $YELLOW  All steps will be previewed. No changes made to your system.$RESET"
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
    Write-Host "    $GREEN--dry-run$RESET        Preview what would be installed (no changes made)"
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

    # Internet check — skipped in dry-run (no real network call needed)
    if ($DryRun) {
        Success "Internet check skipped $DIM(dry-run)$RESET"
    } else {
        try {
            $null = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5
            Success "Internet connection confirmed"
        } catch {
            Err "No internet connection. Please connect and try again."
            exit 1
        }
    }

    # winget check — in dry-run we assume it exists (we can't install it in preview mode)
    if ($DryRun) {
        Success "winget check skipped $DIM(dry-run)$RESET"
    } elseif (Has "winget") {
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

    if ($InstallEssentials)   { Write-Host "  $GREEN+$RESET Essentials    - Git, VS Code, Windows Terminal, Git Bash" }
    if ($InstallWeb)          { Write-Host "  $GREEN+$RESET Web Dev       - Node.js (nvm-windows), pnpm, Docker Desktop, Postman" }
    if ($InstallPython)       { Write-Host "  $GREEN+$RESET Python        - pyenv-win, Python 3, pipx" }
    if ($InstallProductivity) { Write-Host "  $GREEN+$RESET Productivity  - Starship, bat, eza, fzf, GitHub CLI, Nerd Fonts" }
    if ($InstallAI)           { Write-Host "  $GREEN+$RESET AI CLI Tools  - Gemini CLI, Claude Code" }
    if ($InstallLinux)        { Write-Host "  $GREEN+$RESET Linux on Win  - WSL2 + Ubuntu, Chocolatey $YELLOW(restart required after)$RESET" }

    Blank

    # Compute total so we can show it on the confirm screen
    Compute-ProgressTotal
    $modeLabel = if ($DryRun) { "steps to preview" } else { "packages to install" }
    Dim "  $($script:ProgressTotal) $modeLabel"

    Divider
    Blank
    if (-not $DryRun) {
        Dim "  This may take 10-20 minutes depending on your connection."
        Dim "  Some tools may open installer windows - follow any prompts."
        if ($InstallLinux) {
            Write-Host "  $YELLOW  WSL2 is installed last. A restart will be needed to finish it.$RESET"
        }
    }
    Blank

    $prompt = if ($DryRun) { "  ${BOLD}Preview the install plan? [Y/n]:$RESET " } `
              else          { "  ${BOLD}Ready to go? [Y/n]:$RESET " }
    Write-Host -NoNewline $prompt
    $confirm = Read-Host

    if ($confirm -match '^[Nn]$') {
        Blank
        Info "No worries! Re-run anytime."
        Blank
        exit 0
    }

    # Reset current counter — Compute-ProgressTotal ran above to show the count,
    # now zero it so Step-Progress starts fresh during the actual install loop.
    $script:ProgressCurrent = 0

    Blank
}

# ─────────────────────────────────────────────
# ESSENTIALS
# ─────────────────────────────────────────────
function Install-Essentials {
    Write-Host "  ${BOLD}[ Essentials ]$RESET"
    Blank

    # Step 1 — Git + Git Bash
    Winget-Install "Git.Git" "Git + Git Bash (includes unix/bash commands)"
    if (-not $DryRun) { Refresh-Path }

    # Git config check — no interactive prompt; flag missing config for the
    # post-install checklist. In dry-run we can't call git, so assume it needs setting.
    if ($DryRun) {
        $script:GitConfigSkipped = $true
        Dim "    [dry-run] Git identity check skipped - will remind at end"
    } elseif (Has "git") {
        $existingName = git config --global user.name 2>$null
        if (-not $existingName) {
            $script:GitConfigSkipped = $true
            Warn "Git identity not configured - we'll remind you at the end"
        } else {
            Success "Git already configured as: $existingName"
        }
    }

    # Step 2 — VS Code
    Winget-Install "Microsoft.VisualStudioCode" "VS Code"

    # Step 3 — Windows Terminal
    Winget-Install "Microsoft.WindowsTerminal" "Windows Terminal"

    Blank
    Dim "  Git Bash tip: find it in your Start menu as 'Git Bash'."
    Dim "  It gives you ls, cat, grep and other unix commands on Windows."
    Blank
}

# ─────────────────────────────────────────────
# WEB DEVELOPMENT
# ─────────────────────────────────────────────
function Install-Web {
    Write-Host "  ${BOLD}[ Web Development ]$RESET"
    Blank

    # Step 1 — nvm-windows
    $nvmPresent = (-not $DryRun) -and (Has "nvm")
    if ($nvmPresent) {
        $pct = Step-Progress
        Success "nvm-windows already installed - skipping $DIM$pct$RESET"
    } else {
        Winget-Install "CoreyButler.NVMforWindows" "nvm-windows"
        if (-not $DryRun) { Refresh-Path }
    }

    # Step 2 — Node.js LTS via nvm
    $nodePresent = (-not $DryRun) -and (Has "node")
    if ($nodePresent) {
        $pct = Step-Progress
        Success "Node.js $(node -v 2>$null) already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        Install-Step "Installing Node.js LTS via nvm"
        Write-Host "        $DIM nvm install lts$RESET"
        Write-Host "        $DIM nvm use lts$RESET"
    } elseif (Has "nvm") {
        Install-Step "Installing Node.js LTS"
        nvm install lts
        nvm use lts
        Refresh-Path
        Success "Node.js installed"
    } else {
        $pct = Step-Progress
        Warn "nvm not yet in PATH $DIM$pct$RESET - restart PowerShell then run: nvm install lts"
    }

    # Step 3 — pnpm
    $pnpmPresent = (-not $DryRun) -and (Has "pnpm")
    if ($pnpmPresent) {
        $pct = Step-Progress
        Success "pnpm already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        Install-Step "Installing pnpm"
        Write-Host "        $DIM npm install -g pnpm$RESET"
    } elseif (Has "npm") {
        Install-Step "Installing pnpm"
        npm install -g pnpm
        Success "pnpm installed"
    } else {
        $pct = Step-Progress
        Warn "npm not yet available $DIM$pct$RESET - install pnpm later with: npm install -g pnpm"
    }

    # Step 4 — Docker Desktop
    Winget-Install "Docker.DockerDesktop" "Docker Desktop"

    # Step 5 — Postman
    Winget-Install "Postman.Postman" "Postman"

    Blank
}

# ─────────────────────────────────────────────
# PYTHON
# ─────────────────────────────────────────────
function Install-Python {
    Write-Host "  ${BOLD}[ Python ]$RESET"
    Blank

    # Step 1 — pyenv-win
    $pyenvPresent = (-not $DryRun) -and (Has "pyenv")
    if ($pyenvPresent) {
        $pct = Step-Progress
        Success "pyenv-win already installed - skipping $DIM$pct$RESET"
    } else {
        Winget-Install "PyPA.Pyenv-win" "pyenv-win"

        if (-not $DryRun) {
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
    }

    # Step 2 — Python via pyenv
    $pythonVersion = "3.12.4"
    $pythonPresent = (-not $DryRun) -and (Has "python")
    if ($pythonPresent) {
        $pct = Step-Progress
        Success "Python ($(python --version 2>$null)) already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        Install-Step "Installing Python $pythonVersion via pyenv"
        Write-Host "        $DIM pyenv install $pythonVersion$RESET"
        Write-Host "        $DIM pyenv global $pythonVersion$RESET"
    } elseif (Has "pyenv") {
        Install-Step "Installing Python $pythonVersion (this may take a few minutes)"
        pyenv install $pythonVersion
        pyenv global $pythonVersion
        Refresh-Path
        Success "Python $pythonVersion set as default"
    } else {
        $pct = Step-Progress
        Warn "pyenv not yet in PATH $DIM$pct$RESET - restart PowerShell then run: pyenv install $pythonVersion"
    }

    # Step 3 — pipx
    $pipxPresent = (-not $DryRun) -and (Has "pipx")
    if ($pipxPresent) {
        $pct = Step-Progress
        Success "pipx already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        Install-Step "Installing pipx"
        Write-Host "        $DIM pip install --user pipx$RESET"
        Write-Host "        $DIM python -m pipx ensurepath$RESET"
    } elseif (Has "pip") {
        Install-Step "Installing pipx"
        pip install --user pipx
        python -m pipx ensurepath
        Success "pipx installed"
    } else {
        $pct = Step-Progress
        Warn "pip not yet available $DIM$pct$RESET - install pipx later with: pip install --user pipx"
    }

    Blank
}

# ─────────────────────────────────────────────
# PRODUCTIVITY
# ─────────────────────────────────────────────
function Install-Productivity {
    Write-Host "  ${BOLD}[ Productivity Tools ]$RESET"
    Blank

    # Step 1 — Starship
    $starshipPresent = (-not $DryRun) -and (Has "starship")
    if ($starshipPresent) {
        $pct = Step-Progress
        Success "Starship prompt already installed - skipping $DIM$pct$RESET"
    } else {
        Winget-Install "Starship.Starship" "Starship prompt"

        if ($DryRun) {
            Dim "    [dry-run] Would add: Invoke-Expression (&starship init powershell) to PowerShell profile"
        } else {
            Refresh-Path
            $profileDir = Split-Path $PROFILE
            if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
            if (-not (Test-Path $PROFILE))    { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
            $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
            if ($profileContent -notmatch 'starship') {
                Add-Content -Path $PROFILE -Value "`n# Starship prompt`nInvoke-Expression (&starship init powershell)"
            }
            Success "Starship added to PowerShell profile"
        }
    }

    # Step 2 — Nerd Font
    Winget-Install "DEVCOM.JetBrainsMonoNerdFont" "JetBrains Mono Nerd Font"

    # Step 3 — bat (winget first, choco fallback)
    $batPresent = (-not $DryRun) -and (Has "bat")
    if ($batPresent) {
        $pct = Step-Progress
        Success "bat already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        $pct = Step-Progress
        Write-Host "  $CYAN->$RESET $pct $DIM[dry-run]$RESET Would install: $BOLDbat$RESET (better file viewer)"
        Write-Host "        $DIM winget install sharkdp.bat --silent  (choco install bat -y as fallback)$RESET"
    } else {
        $pct = Step-Progress
        Write-Host "  $CYAN->$RESET $pct Installing bat (better file viewer)..."
        winget install --id sharkdp.bat --silent --accept-package-agreements --accept-source-agreements 2>$null
        if ($LASTEXITCODE -ne 0) { Choco-Install "bat" "bat" }
        else { Refresh-Path; Success "bat installed" }
    }

    # Step 4 — eza (winget first, choco fallback)
    $ezaPresent = (-not $DryRun) -and (Has "eza")
    if ($ezaPresent) {
        $pct = Step-Progress
        Success "eza already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        $pct = Step-Progress
        Write-Host "  $CYAN->$RESET $pct $DIM[dry-run]$RESET Would install: $BOLDeza$RESET (better directory listing)"
        Write-Host "        $DIM winget install eza-community.eza --silent  (choco install eza -y as fallback)$RESET"
    } else {
        $pct = Step-Progress
        Write-Host "  $CYAN->$RESET $pct Installing eza (better directory listing)..."
        winget install --id eza-community.eza --silent --accept-package-agreements --accept-source-agreements 2>$null
        if ($LASTEXITCODE -ne 0) { Choco-Install "eza" "eza" }
        else { Refresh-Path; Success "eza installed" }
    }

    # Step 5 — fzf
    Winget-Install "junegunn.fzf" "fzf (fuzzy finder)"

    # Step 6 — GitHub CLI
    Winget-Install "GitHub.cli" "GitHub CLI"

    Blank
}

# ─────────────────────────────────────────────
# AI CLI TOOLS
# ─────────────────────────────────────────────
function Install-AI {
    Write-Host "  ${BOLD}[ AI CLI Tools ]$RESET"
    Blank

    Dim "  These tools require API keys - JumpStart will NOT handle your keys."
    Dim "  After install, we'll show you exactly where to get them."
    Blank

    if (-not $DryRun) { Refresh-Path }

    # In dry-run we assume npm will be available (can't check without running node)
    $npmAvailable = $DryRun -or (Has "npm")

    if (-not $npmAvailable) {
        # Consume both steps so the total stays accurate
        $null = Step-Progress; $null = Step-Progress
        Warn "Node.js/npm is required for AI CLI tools."
        Warn "Select Web Dev (option 2) first, then re-run with --ai"
        Blank
        return
    }

    # Step 1 — Gemini CLI
    $geminiPresent = (-not $DryRun) -and (npm list -g @google/gemini-cli 2>$null | Select-String "gemini-cli")
    if ($geminiPresent) {
        $pct = Step-Progress
        Success "Gemini CLI already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        Install-Step "Installing Gemini CLI (Google)"
        Write-Host "        $DIM npm install -g @google/gemini-cli$RESET"
    } else {
        Install-Step "Installing Gemini CLI (Google)"
        npm install -g @google/gemini-cli
        Success "Gemini CLI installed"
    }

    # Step 2 — Claude Code
    $claudePresent = (-not $DryRun) -and (npm list -g @anthropic-ai/claude-code 2>$null | Select-String "claude-code")
    if ($claudePresent) {
        $pct = Step-Progress
        Success "Claude Code already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        Install-Step "Installing Claude Code (Anthropic)"
        Write-Host "        $DIM npm install -g @anthropic-ai/claude-code$RESET"
    } else {
        Install-Step "Installing Claude Code (Anthropic)"
        npm install -g @anthropic-ai/claude-code
        Success "Claude Code installed"
    }

    Blank
}

# ─────────────────────────────────────────────
# LINUX ON WINDOWS
# ─────────────────────────────────────────────
function Install-Linux {
    Write-Host "  ${BOLD}[ Linux on Windows ]$RESET"
    Blank

    # ── Step 1: Chocolatey ───────────────────────
    Write-Host "  ${BOLD}Setting up Chocolatey (package manager)...$RESET"
    Blank

    $chocoPresent = (-not $DryRun) -and (Has "choco")
    if ($chocoPresent) {
        $pct = Step-Progress
        Success "Chocolatey already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        Install-Step "Installing Chocolatey"
        Write-Host "        $DIM Set-ExecutionPolicy Bypass -Scope Process -Force$RESET"
        Write-Host "        $DIM [Net.ServicePointManager]::SecurityProtocol |= 3072$RESET"
        Write-Host "        $DIM Invoke-Expression (DownloadString 'https://community.chocolatey.org/install.ps1')$RESET"
    } else {
        Install-Step "Installing Chocolatey"
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

    Blank

    # ── Step 2: WSL2 + Ubuntu ───────────────────
    Write-Host "  ${BOLD}Setting up WSL2 + Ubuntu...$RESET"
    Blank

    Dim "  WSL2 (Windows Subsystem for Linux) gives you a full bash/Linux"
    Dim "  environment directly inside Windows - no dual boot needed."
    Dim "  After setup, open 'Ubuntu' from your Start menu to use it."
    Blank

    # wsl --list is a real system call — skip entirely in dry-run
    $wslAlreadyOn = $false
    if (-not $DryRun) {
        try {
            $wslList = wsl --list 2>$null
            if ($wslList -match "Ubuntu") { $wslAlreadyOn = $true }
        } catch {}
    }

    if ($wslAlreadyOn) {
        $pct = Step-Progress
        Success "WSL2 + Ubuntu already installed - skipping $DIM$pct$RESET"
    } elseif ($DryRun) {
        Install-Step "Enabling WSL2 + installing Ubuntu"
        Write-Host "        $DIM dism /enable-feature Microsoft-Windows-Subsystem-Linux /all /norestart$RESET"
        Write-Host "        $DIM dism /enable-feature VirtualMachinePlatform /all /norestart$RESET"
        Write-Host "        $DIM wsl --set-default-version 2$RESET"
        Write-Host "        $DIM wsl --install -d Ubuntu$RESET"
        Write-Host "  $YELLOW  Note: a system restart would be required after this step.$RESET"
    } else {
        $pct = Step-Progress
        Write-Host "  $CYAN->$RESET $pct Enabling WSL2..."
        Blank
        Write-Host "  $YELLOW  WSL2 will be enabled and Ubuntu will be installed.$RESET"
        Write-Host "  $YELLOW  A restart is required to finish - JumpStart will prompt you.$RESET"
        Blank

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

    Blank
}

# ─────────────────────────────────────────────
# AI KEYS GUIDE
# ─────────────────────────────────────────────
function Print-AIKeysGuide {
    Blank
    Write-Host "  $BOLD${CYAN}  Setting up your AI CLI tools:$RESET"
    Blank
    Write-Host "  ${BOLD}  Gemini CLI $DIM(free tier available)$RESET"
    Dim "    1. Visit: https://aistudio.google.com/apikey"
    Dim "    2. Sign in with your Google account and click 'Create API Key'"
    Dim "    3. Run: gemini  (it will prompt you to paste your key)"
    Blank
    Write-Host "  ${BOLD}  Claude Code $DIM(Anthropic)$RESET"
    Dim "    1. Visit: https://console.anthropic.com"
    Dim "    2. Go to 'API Keys' and click 'Create Key'"
    Dim "    3. Run: claude  (it will prompt you to paste your key)"
    Blank
    Dim "  Your API keys are stored locally on your machine only."
    Dim "  JumpStart never sees or touches them."
}

# ─────────────────────────────────────────────
# NEXT STEPS  (post-install checklist)
# ─────────────────────────────────────────────
function Print-NextSteps {
    Blank

    if ($DryRun) {
        Write-Host "  $BOLD$YELLOW+=========================================================+"
        Write-Host "  |                                                         |"
        Write-Host "  |   Dry run complete. No changes were made.              |"
        Write-Host "  |   Re-run without --dry-run to actually install.        |"
        Write-Host "  |                                                         |"
        Write-Host "  +=========================================================+$RESET"
    } else {
        Write-Host "  $BOLD$GREEN+=========================================================+"
        Write-Host "  |                                                         |"
        Write-Host "  |   You're all set up! Here's what to do next.           |"
        Write-Host "  |                                                         |"
        Write-Host "  +=========================================================+$RESET"
    }
    Blank

    Write-Host "  ${BOLD}Finish your setup — do these after closing this window:$RESET"
    Blank

    $step = 1

    # Reopen terminal (not needed after a dry-run, but still good advice)
    if (-not $DryRun) {
        Write-Host "  $CYAN[$step]$RESET Close and reopen PowerShell so all new tools are recognized"
        $step++
    }

    # Git identity — shown if git config was not already set
    if ($script:GitConfigSkipped) {
        Write-Host "  $CYAN[$step]$RESET $YELLOW${BOLD}Set your Git identity$RESET $DIM(required for commits)$RESET"
        Dim "      git config --global user.name `"Your Name`""
        Dim "      git config --global user.email `"you@example.com`""
        Dim "      git config --global init.defaultBranch main"
        $step++
    }

    # GitHub authentication
    if ($InstallEssentials) {
        Write-Host "  $CYAN[$step]$RESET $YELLOW${BOLD}Authenticate with GitHub$RESET $DIM(so you can push/pull repos)$RESET"
        Dim "      Option A - GitHub CLI (recommended):"
        Dim "        gh auth login"
        Dim "      Option B - SSH key:"
        Dim "        ssh-keygen -t ed25519 -C `"you@example.com`""
        Dim "        Then add the key at: https://github.com/settings/keys"
        $step++
    }

    # VS Code quick tip
    if ($InstallEssentials) {
        Write-Host "  $CYAN[$step]$RESET Open VS Code anywhere by typing: $CYAN code .$RESET"
        $step++
    }

    # Git Bash
    if ($InstallEssentials) {
        Write-Host "  $CYAN[$step]$RESET Find $BOLD'Git Bash'$RESET in Start menu for unix/bash commands $DIM(ls, cat, grep...)$RESET"
        $step++
    }

    # Node / npm
    if ($InstallWeb) {
        Write-Host "  $CYAN[$step]$RESET Verify Node.js: $CYAN node -v$RESET  and npm: $CYAN npm -v$RESET"
        $step++
    }

    # Python
    if ($InstallPython) {
        Write-Host "  $CYAN[$step]$RESET Verify Python: $CYAN python --version$RESET"
        $step++
    }

    # Nerd Font for Starship
    if ($InstallProductivity) {
        Write-Host "  $CYAN[$step]$RESET Set your terminal font to $BOLD'JetBrains Mono Nerd Font'$RESET for Starship icons"
        Dim "      Windows Terminal: Settings -> Profiles -> Defaults -> Font face"
        $step++
    }

    # WSL2 restart + first-run instructions
    if ($InstallLinux) {
        Blank
        Write-Host "  $YELLOW${BOLD}  WSL2 requires a restart to fully activate$RESET"
        Write-Host "  $CYAN[$step]$RESET $YELLOW${BOLD}Restart your PC$RESET $DIM(WSL2 won't work until you do)$RESET"
        $step++
        Write-Host "  $CYAN[$step]$RESET After restarting, open $BOLD'Ubuntu'$RESET from the Start menu"
        Dim "      -> Create a Linux username and password when prompted"
        Dim "      -> Then run: sudo apt update && sudo apt upgrade"
        Dim "      -> You can now use bash, grep, ls, curl and all unix commands"
        $step++
    }

    # AI API key setup
    if ($InstallAI) {
        Print-AIKeysGuide
    }

    Blank
    Divider
    Blank
    if ($DryRun) {
        Dim "  Re-run without --dry-run to apply these changes."
    } else {
        Dim "  Full install log saved to: $LogFile"
    }
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

    # WSL2 always goes last — it requires a restart and shouldn't block other installs
    if ($InstallEssentials)   { Section; Install-Essentials }
    if ($InstallWeb)          { Section; Install-Web }
    if ($InstallPython)       { Section; Install-Python }
    if ($InstallProductivity) { Section; Install-Productivity }
    if ($InstallAI)           { Section; Install-AI }
    if ($InstallLinux)        { Section; Install-Linux }

    Print-NextSteps

    "JumpStart install completed at $(Get-Date)" | Add-Content -Path $LogFile

    # Restart prompt — only after a real install that needed WSL2
    if ($script:RestartRequired -and -not $DryRun) {
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
