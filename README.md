# ⚡ JumpStart

**Go from fresh Mac or Windows install → productive dev environment in ~15 minutes.**

Built for beginners. Safe to re-run. Open source.

```
  ╔══════════════════════════════════════════╗
  ║    ██╗██╗   ██╗███╗   ███╗██████╗       ║
  ║    ██║██║   ██║████╗ ████║██╔══██╗      ║
  ║    ██║██║   ██║██╔████╔██║██████╔╝      ║
  ║    ██║██║   ██║██║╚██╔╝██║██╔═══╝       ║
  ║    ██║╚██████╔╝██║ ╚═╝ ██║██║           ║
  ║    ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝           ║
  ╚══════════════════════════════════════════╝
```

---

## 🚀 Quick Start

### macOS

Open **Terminal** (press `Cmd + Space`, type `Terminal`, hit Enter) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/baraqfi/jumpstart/main/mac/setup.sh | bash
```

### Windows

Open **PowerShell** (press `Win`, type `PowerShell`, hit Enter) and run:

```powershell
irm https://raw.githubusercontent.com/baraqfi/jumpstart/main/windows/setup.ps1 | iex
```

> ℹ️ **First time ever opening a terminal?** That's okay — this is what JumpStart is for. Just paste the command above and press Enter. The script will walk you through everything.

---

## 📦 What Gets Installed

Run the interactive menu to choose, or pass flags to go straight to install.

> **Key:** no tag = works the same on both platforms · `[macOS]` = macOS only · `[Windows]` = Windows only

| Category | What's included | Flag |
|---|---|---|
| **Essentials** | Git, VS Code | `--essentials` |
| | + Homebrew `[macOS]` | |
| | + Windows Terminal, Git Bash `[Windows]` | |
| **Web Dev** | Node.js, pnpm, Docker Desktop, Postman | `--web` |
| | installed via nvm + Homebrew `[macOS]` | |
| | installed via nvm-windows + winget `[Windows]` | |
| **Python** | Python 3, pipx | `--python` |
| | installed via pyenv `[macOS]` | |
| | installed via pyenv-win `[Windows]` | |
| **Productivity** | Starship prompt, bat, eza, fzf, GitHub CLI, Nerd Fonts | `--productivity` |
| | installed via Homebrew `[macOS]` | |
| | installed via winget + Chocolatey `[Windows]` | |
| **AI CLI Tools** | Gemini CLI (Google), Claude Code (Anthropic) | `--ai` |
| **Linux on Windows** `[Windows]` | WSL2 + Ubuntu, Chocolatey | `--linux` |
| | *Gives you bash, grep, ls and all unix commands on Windows* | |
| | *⚠ Requires a restart to complete WSL2 setup* | |

### Install everything at once

macOS:
```bash
curl -fsSL https://raw.githubusercontent.com/baraqfi/jumpstart/main/mac/setup.sh | bash -s -- --all
```

Windows:
```powershell
$env:JS_FLAGS="--all"; irm https://raw.githubusercontent.com/baraqfi/jumpstart/main/windows/setup.ps1 | iex
```

### Mix and match

macOS:
```bash
# Web dev + AI tools only
curl -fsSL https://raw.githubusercontent.com/baraqfi/jumpstart/main/mac/setup.sh | bash -s -- --web --ai

# Just the essentials
curl -fsSL https://raw.githubusercontent.com/baraqfi/jumpstart/main/mac/setup.sh | bash -s -- --essentials
```

Windows:
```powershell
# Web dev + Linux on Windows
$env:JS_FLAGS="--web --linux"; irm https://raw.githubusercontent.com/baraqfi/jumpstart/main/windows/setup.ps1 | iex
```

### Preview without installing

macOS:
```bash
curl -fsSL https://raw.githubusercontent.com/baraqfi/jumpstart/main/mac/setup.sh | bash -s -- --dry-run
```

Windows:
```powershell
$env:JS_FLAGS="--dry-run"; irm https://raw.githubusercontent.com/baraqfi/jumpstart/main/windows/setup.ps1 | iex
```

---

## 🤖 AI CLI Tools — API Keys

JumpStart installs the tools, but **never handles your API keys**. They stay on your machine only.

**Gemini CLI** (free tier available)
1. Go to [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Sign in with your Google account → Create API Key
3. Run `gemini` in your terminal — it will prompt you to paste it

**Claude Code** (Anthropic)
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Create account → API Keys → Create Key
3. Run `claude` in your terminal — it will prompt you to paste it

---

## 🔒 Is This Safe?

**Yes.** A few things worth knowing:

- JumpStart is fully open source — you can read every line before running it
- It only installs well-known, widely used tools from official sources
- It checks if things are already installed before touching anything (safe to re-run)
- It never collects data, sends telemetry, or touches your API keys

**Want to inspect before running?**
```bash
# Download first, read it, then run
curl -o jumpstart.sh https://raw.githubusercontent.com/baraqfi/jumpstart/main/mac/setup.sh
cat jumpstart.sh   # read it
bash jumpstart.sh  # run it when you're happy
```

---

## 🛠️ Customize It

### Fork & edit package lists
Package lists are simple arrays at the top of each script. Fork the repo, add your company's tools, share your custom version.

### Add your own tools
In `mac/setup.sh`, find the relevant section and add:
```bash
brew_install your-tool "Your Tool Name"
# or
brew_cask_install your-app "Your App Name"
```

### Pass flags from a config file (coming in v2)
```bash
bash setup.sh --web --python --essentials
```

---

## 📋 After Install

1. **Restart your terminal** (or run `exec $SHELL`) so all tools are recognized
2. **VS Code:** type `code .` anywhere to open it in the current folder
3. **Starship:** set your terminal font to **JetBrains Mono Nerd Font** for icons to display correctly
4. **Node.js:** run `node -v` to confirm it's working
5. **Python:** run `python --version` to confirm

Full install log is saved to `~/jumpstart-install.log`.

---

## 🗺️ Roadmap

- [x] macOS script (v1) — Homebrew, nvm, pyenv, Starship, AI CLI tools
- [x] Windows script (v1) — winget, nvm-windows, pyenv-win, WSL2, Chocolatey
- [ ] Web configurator with GUI (GUI → generates your custom command)
- [ ] More tool categories (mobile, game dev, DevOps)
- [ ] Config file support (`jumpstart.yaml`)
- [ ] Version pinning for reproducible setups

---

## 🤝 Contributing

PRs welcome! Adding a tool is as simple as one line in an array.

- Found a bug → [open an issue](https://github.com/baraqfi/jumpstart/issues)
- Want to add a tool → open a PR with the brew package name and a one-line description
- Want to port to Linux → let's talk!

---

## 📄 License

MIT — free to use, fork, and share.

---

Made with ☕ by [@baraqfi](https://github.com/baraqfi)
