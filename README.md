# emacs-portable

Fully portable Emacs config with Vim keybindings. Zero network required at runtime.

CI builds a clean zip containing **only `.el` files** — no binaries, no `.git`, no docs, no tests.
Download the artifact, unzip to `~/.emacs.d/`, done.

## What's included

- **Evil mode** — full Vim keybindings with `SPC` leader (Doom-style)
- **Magit** — Git interface (`SPC g g`)
- **Consult + Vertico + Orderless** — fuzzy find files, ripgrep, buffers
- **Which-key** — keybinding discovery popup
- **Eglot** (built-in Emacs 29+) — LSP for Python (pyright), SystemVerilog (DVT)
- **Org mode** (built-in) — notes, todos, agenda
- **Markdown mode** — syntax highlighting for `.md`
- **Verilog mode** (built-in) — SystemVerilog/Verilog support

## Usage

### Download from CI

1. Go to **Actions** tab → latest successful run
2. Download `emacs-portable` artifact
3. Unzip:
```bash
unzip emacs-portable.zip -d ~
# Creates ~/.emacs.d/ with everything ready
emacs
```

### Build locally

```bash
git clone --recursive https://github.com/<you>/emacs-portable.git
cd emacs-portable
./build.sh
# Output in build/.emacs.d/
```

### Test without affecting current config

```bash
emacs --init-directory ./build/.emacs.d/
```

## Key bindings

`SPC` is the leader key. Press it and wait — which-key shows all options.

### Most used

| Key | Action |
|-----|--------|
| `SPC f f` | Find file |
| `SPC s p` | Ripgrep project |
| `SPC b b` | Switch buffer |
| `SPC g g` | Magit (git) |
| `SPC SPC` | M-x (command palette) |
| `SPC w v` | Vertical split |
| `SPC w hjkl` | Navigate windows |
| `SPC c d` | Go to definition (LSP) |
| `SPC c r` | Find references (LSP) |

### Vim-style (normal mode)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover docs |
| `gcc` | Comment line |
| `gc` (visual) | Comment selection |
| `jk` | Exit insert mode |
| `C-j`/`C-k` | Navigate completion list |

### Magit

| Key | Action |
|-----|--------|
| `j`/`k` | Navigate |
| `s`/`u` | Stage/Unstage |
| `c` | Commit |
| `p` | Push |
| `F` | Pull |
| `q` | Quit |
| `?` | Show all commands |

## External dependencies

- **Emacs 29+** (for built-in eglot)
- **ripgrep** (`rg`) — for `SPC s p` project search
- **pyright** (optional) — `pip install --user pyright` for Python LSP
- **DVT** (optional) — for SystemVerilog LSP

## Updating packages

Packages are git submodules pinned to specific commits.

```bash
# Update a single package
cd vendor/magit
git pull origin main
cd ../..
git add vendor/magit
git commit -m "update magit"

# Update all
git submodule update --remote
git add vendor/
git commit -m "update all packages"
```

Push to trigger CI → download fresh zip.

## Repo structure

```
emacs-portable/
├── init.el              # Main config
├── early-init.el        # Early init (UI, GC, no package.el)
├── build.sh             # Build script (strips to .el only)
├── vendor/              # Git submodules (source)
│   ├── evil/
│   ├── magit/
│   ├── consult/
│   └── ...
└── .github/workflows/
    └── build.yml        # CI: build + zip artifact
```
