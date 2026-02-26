---
summary: Zsh configuration — oh-my-zsh, Powerlevel10k, aliases, tool managers, and custom functions.
read_when: Modifying shell config, adding aliases, or debugging environment setup.
---

# Zsh Configuration

## Framework

- **Shell**: Zsh
- **Framework**: oh-my-zsh
- **Theme**: Powerlevel10k (`ZSH_THEME="powerlevel10k/powerlevel10k"`)
- **Plugins**: `git`, `zsh-autosuggestions`
- **Config**: `~/.zshrc` + `~/.p10k.zsh`

## Key Aliases

### Navigation

```bash
alias cl='clear ; ls -lah'
alias c_ait='cd ~/source/mateonunez/ait'
alias c_mn='cd ~/source/mateonunez/'
alias c_ai='cd ~/source/mateonunez/ai'
```

### Git

```bash
alias gaa='git add .'
alias gcsnm='git commit -s -n -m'
alias gpn='git push --no-verify'
alias gpfn='git push --force --no-verify'
alias gpfwn='git push --force-with-lease --no-verify'
alias gs='git status'
```

### Docker & Kubernetes

```bash
alias d='docker'
alias dc='docker compose'
alias k='kubectl'
```

### Languages

```bash
alias n='node'
alias p='python3'
```

### AWS LocalStack

```bash
alias awslocal="AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test ... aws --endpoint-url=http://localhost:4566"
```

## Custom Functions

### wtf — Port Inspector

```bash
wtf() {
  local port="${1:-3000}"
  lsof -i :"$port"
}
# Usage: wtf        → checks port 3000
# Usage: wtf 8080   → checks port 8080
```

## Autosuggestions

```bash
# Accept suggestion with Ctrl+Space
bindkey '^ ' autosuggest-accept
```

## Tool Managers

| Tool | Manager | Setup |
|------|---------|-------|
| Node.js | nvm | `source ~/.nvm/nvm.sh` |
| Python | pyenv | `eval "$(pyenv init --path)"` |
| Bun | Direct install | `~/.bun/bin` in PATH |
| Ruby | Homebrew | `/opt/homebrew/opt/ruby@3.2/bin` |

## Additional PATH Entries

```bash
~/.bun/bin
~/.local/bin
~/.pulumi/bin
~/.antigravity/bin
~/.opencode/bin
~/.android-sdk-macosx/platform-tools
/opt/homebrew/opt/ruby@3.2/bin
~/.pub-cache/bin
```

## Shell Integrations

- Dart/Flutter CLI completions
- Docker Desktop completions
- Kiro shell integration

## Powerlevel10k

Configuration in `~/.p10k.zsh` — run `p10k configure` to reconfigure interactively.

Features:
- Git status in prompt (branch, dirty, ahead/behind)
- Current directory with path truncation
- Command execution time
- Node.js version indicator
- Python virtualenv indicator
