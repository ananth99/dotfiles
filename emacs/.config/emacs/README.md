# Terminal Emacs Configuration for BitGo Development

A literate programming-based Emacs configuration optimized for full-time terminal use with BitGo's multi-repository development environment.

## Philosophy

This configuration follows **literate programming** principles:
- `config.org` is the **single source of truth**
- `init.el` and `early-init.el` are **auto-generated** via org-babel tangling
- All customizations are documented with context and rationale

## Features

- **Terminal-First**: Full functionality in Ghostty terminal
- **VSCode-Level LSP**: eglot + typescript-language-server with rich completion
- **Multi-Repo Navigation**: Custom helpers for BitGo's 20 repositories
- **Modern Completion**: Vertico + Consult + Orderless + Corfu
- **Tree-sitter Support**: 13 languages with modern syntax parsing
- **Comprehensive Git**: Magit + Forge + git-timemachine + blamer
- **Smart Keyboard**: Ctrl = C-, Option = M- (Meta)

## Prerequisites

### System Tools
```bash
# TypeScript Language Server (CRITICAL for LSP)
brew install typescript-language-server

# Fast search tools
brew install ripgrep fd

# Code formatting
npm install -g prettier eslint

# Terminal (if not already installed)
# brew install ghostty
```

### Emacs Installation
```bash
brew tap d12frosted/emacs-plus
brew install emacs-plus@30 --with-native-comp
```

### Fonts
```bash
brew install font-jetbrains-mono
brew install font-jetbrains-mono-nerd-font
```

## Installation

### 1. Backup Current Config (if needed)
```bash
mv ~/.config/emacs ~/.emacs-backup-$(date +%Y%m%d-%H%M%S)
```

### 2. Symlink New Config
```bash
cd ~/Personal/emacs-terminal-config
stow -t ~ .
```

This creates: `~/.config/emacs/` → `~/Personal/emacs-terminal-config/.config/emacs/`

### 3. Generate Init Files
```bash
# Open Emacs (will show errors - expected!)
emacs

# Open config.org
C-x C-f ~/.config/emacs/config.org RET

# Tangle to generate init.el and early-init.el
C-c C-v C-t

# Restart Emacs
C-x C-c
emacs
```

### 4. Initial Package Installation
On first launch, Elpaca will automatically:
- Clone package repositories
- Install ~50 packages
- Byte-compile everything
- This takes 2-3 minutes

## Literate Programming Workflow

### Making Changes

**NEVER edit `init.el` or `early-init.el` directly!**

1. Open `config.org`: `M-x find-file RET ~/.config/emacs/config.org`
2. Edit the org file
3. Tangle to regenerate: `C-c C-v C-t`
4. Reload Emacs: `C-x C-c` then restart

### Understanding config.org Structure

```org
* Section Name
Prose explanation of what this section does and why.

** Subsection
More detailed explanation.

#+begin_src emacs-lisp :tangle "init.el"
  ;; This code goes into init.el
  (use-package some-package
    :config ...)
#+end_src

#+begin_src emacs-lisp :tangle "early-init.el"
  ;; This code goes into early-init.el
  (setq some-early-setting value)
#+end_src

#+begin_src emacs-lisp :tangle no
  ;; This is example code, not tangled
  (example-function)
#+end_src
```

## Quick Start Guide

### Navigation Keybindings

| Key | Command | Description |
|-----|---------|-------------|
| `C-c p` | bitgo/switch-project | Switch to BitGo project |
| `C-x p f` | project-find-file | Find file in current project |
| `C-x b` | consult-buffer | Switch buffer with preview |
| `C-c j` | bitgo/jump-to-repo | Jump to specific BitGo repo |
| `M-g i` | consult-imenu | Jump to function/class |
| `C-s` | consult-line | Search in current buffer |

### Search Across BitGo Repos

| Key | Command | Description |
|-----|---------|-------------|
| `C-c s` | bitgo/search-all-repos | Search across ALL BitGo repos |
| `C-c a` | bitgo/find-api-handler | Find API route handlers |
| `C-c u` | bitgo/find-component | Find React components/hooks |
| `C-c r` | bitgo/find-related-files | Find files related to current |

### LSP / Code Intelligence

| Key | Command | Description |
|-----|---------|-------------|
| `M-.` | xref-find-definitions | Go to definition |
| `M-?` | xref-find-references | Find all references |
| `M-,` | xref-go-back | Go back after jumping |
| `C-c l s` | consult-eglot-symbols | Search symbols in workspace |
| `C-c l r` | eglot-rename | Rename symbol everywhere |
| `C-c l a` | eglot-code-actions | Show code actions |
| `C-c l f` | eglot-format | Format current buffer |
| `C-c l h` | eldoc-box-help-at-point | Show documentation popup |

### Git

| Key | Command | Description |
|-----|---------|-------------|
| `C-c m s` | magit-status | Git status (main interface) |
| `C-c m b` | magit-blame | Git blame current file |
| `C-c g t` | git-timemachine | Browse file history |
| `C-c g b` | blamer-mode | Toggle inline git blame |

## Example Workflow: Finding API Handlers

Let's trace `useTransfersByEnterpriseQuery` from bitgo-ui to wallet-platform:

1. **Start in bitgo-ui**:
   ```
   C-c p → select "bitgo-ui" → RET
   C-x p f → type "useTransfersByEnterpriseQuery" → RET
   ```

2. **Find the React Query hook**:
   - You'll see it uses `getTransfersByEnterprise` API call
   - Note the endpoint structure

3. **Search for the API handler**:
   ```
   C-c a → type "getTransfersByEnterprise" → RET
   ```
   - This searches across all BitGo repos for API handlers
   - Results show matches in `wallet-platform/src/routes/`

4. **Jump to definition** (if already in the handler file):
   ```
   M-. → jumps to function definition
   M-? → shows all references
   M-, → go back
   ```

5. **View git history**:
   ```
   C-c g t → opens git-timemachine
   p/n → navigate through commits
   q → quit timemachine
   ```

## Keyboard Layout Reference

### Ghostty Terminal Configuration

Your `~/.config/ghostty/config` is already configured:
```conf
macos-option-as-alt = true  # Option key sends Alt (Meta in Emacs)
```

### Emacs Key Notation

| Terminal Key | Emacs Notation | Name |
|-------------|----------------|------|
| `Ctrl` | `C-` | Control |
| `Option` | `M-` | Meta |
| `Shift` | `S-` | Shift |

Examples:
- `Ctrl + x` followed by `Ctrl + f` → `C-x C-f`
- `Option + x` → `M-x`
- `Ctrl + c` followed by `p` → `C-c p`

## Troubleshooting

### LSP Not Working?
```bash
# Verify typescript-language-server is installed
which typescript-language-server

# Reinstall if needed
brew reinstall typescript-language-server
```

### Packages Not Installing?
```bash
# Check Elpaca status
M-x elpaca-status

# Rebuild specific package
M-x elpaca-rebuild RET package-name RET

# Full rebuild
M-x elpaca-rebuild-all
```

### Tree-sitter Grammars Missing?
Open `config.org` and look for `treesit-install-all-grammars` function.
It should auto-install on first run, but you can manually trigger:
```
M-x treesit-install-all-grammars
```

### Config Not Loading?
```bash
# Check for errors in generated files
emacs --debug-init

# View *Messages* buffer
C-h e
```

## Learning Resources

### Built-in Tutorial
```
C-h t  → Emacs tutorial (30 minutes)
```

### Help System
```
C-h f  → describe-function (what does this function do?)
C-h v  → describe-variable (what is this variable?)
C-h k  → describe-key (what does this key do?)
C-h m  → describe-mode (what mode am I in?)
```

### Comprehensive Keybinding Reference
```
M-g i → type "Keybinding" → jumps to reference section in config.org
```

## File Structure

```
~/.config/emacs/
├── config.org              # ← EDIT THIS (source of truth)
├── init.el                 # ← GENERATED (don't edit)
├── early-init.el           # ← GENERATED (don't edit)
├── tree-sitter/            # Pre-compiled grammars (13 languages)
│   ├── libtree-sitter-typescript.dylib
│   ├── libtree-sitter-tsx.dylib
│   └── ...
├── elpaca/                 # Package manager cache (gitignored)
├── .gitignore              # Excludes generated files
└── README.md               # This file
```

## Contributing to This Config

When you make improvements:

1. Edit `config.org` with clear prose explanations
2. Use proper org-mode structure with headers
3. Add `:tangle` directives to code blocks
4. Document your reasoning (literate programming!)
5. Test by tangling and restarting Emacs
6. Commit only `config.org` changes

## Version Control

This configuration is designed to be tracked with Git:

```bash
cd ~/Personal/emacs-terminal-config
git init
git add .config/emacs/config.org
git add .config/emacs/tree-sitter/
git add .config/emacs/.gitignore
git add .config/emacs/README.md
git add .config/ghostty/config
git commit -m "Initial literate Emacs configuration"
```

The `.gitignore` ensures generated files (`init.el`, `early-init.el`, `elpaca/`) are never committed.

## Support

For Emacs help:
- `C-h ?` → Help menu
- `M-x helpful-command` → Enhanced help

For BitGo-specific workflows, see the "Keybinding Reference & Tutorial" section in `config.org` (press `M-g i` and search for "Keybinding").

---

**Happy Hacking!** 🚀

*Last updated: October 2025*
