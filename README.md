# dotfiles — vasco-debian

Config pessoal para Debian + Hyprland (perfil minimalista).

## Estrutura

```
dotfiles/
├── nvim/           Neovim (lazy.nvim + plugins)
├── kitty/          Kitty terminal + tema Gruvbox Dark
├── tmux/           tmux.conf + scripts MRU
├── hypr/           Hyprland (configs, scripts, UserConfigs, waybar)
├── waybar/         Waybar i3-minimal (Gruvbox, bottom bar)
├── rofi/           Rofi launcher + tema minimal Gruvbox
├── btop/           btop.conf + tema Catppuccin Macchiato
├── zsh/            .zshrc (Oh My Zsh + Powerlevel10k) + .p10k.zsh
└── git/            .gitconfig
```

## Instalação rápida

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

O script cria symlinks e faz backup automático de configs existentes.

---

## Detalhes por ferramenta

### Neovim
- **Plugin manager**: lazy.nvim
- **Colorscheme**: Gruvbox
- **Plugins principais**: LSP, Telescope, Harpoon, Neo-tree, Avante (AI), Copilot, Treesitter, Lualine, Which-key, Autopairs, Alpha
- Após instalar, abre o nvim — os plugins instalam automaticamente.

### Kitty
- Tema: Gruvbox Dark
- Fonte: FantasqueSansM Nerd Font Mono Bold 12
- Scroll suave, sem bell

### Tmux
- Prefix: `Ctrl+a`
- True color / Gruvbox status bar com powerline
- Navegação vim-style entre painéis (integração com Neovim)
- Clipboard: `wl-copy` (Wayland)
- **Plugins (TPM)**:
  - `tmux-sensible`
  - `tmux-resurrect` (guarda sessão nvim)
  - `tmux-continuum` (auto-save a cada 10 min)
  - `tmux-yank`
- Após instalar, dentro do tmux: `Prefix + I`

### Hyprland (perfil minimalista)
- Decorações: `UserDecorations-minimal.conf` — Gruvbox estático, sem blur, sem sombras, gaps=0
- Animações: desligadas
- Teclado: `pt,us` — muda com `Shift+Alt`
- **Keybinds principais**:
  | Tecla | Ação |
  |---|---|
  | `Super + Return` | Terminal (kitty) |
  | `Super + D` | Rofi launcher |
  | `Super + Q` | Fechar janela |
  | `Super + F` | Fullscreen fake |
  | `Super + Space` | Float toggle |
  | `Super + [1-0]` | Mudar workspace |
  | `Shift+Alt` | Mudar layout teclado pt↔us |
  | `Ctrl+Alt+L` | Bloquear ecrã |
  | `Ctrl+Alt+P` | Menu power |
  | `Super + Print` | Screenshot |
  | `Super + Shift + S` | Screenshot com swappy |
- Monitores: `HDMI-A-1` (2560×1440@144) principal + `eDP-2` (1920×1080@144) laptop à esquerda
- Startup: waybar, nm-applet, blueman-applet, hypridle, swww-daemon, cliphist

### Waybar
- Posição: bottom, estilo i3-minimal Gruvbox
- Esquerda: workspaces por número
- Centro: relógio HH:MM:SS
- Direita: RAM, temperatura, áudio, rede, bateria, power profiles, power

### Rofi
- Tema: `themes/minimal.rasi` — Gruvbox Dark, square, sem arredondamentos

### Btop
- Tema: Catppuccin Macchiato
- Background transparente, vim keys off

### Zsh
- Shell: Zsh + Oh My Zsh
- Tema: Powerlevel10k
- Plugins: git, zsh-autosuggestions, zsh-syntax-highlighting
- NVM e Conda com lazy load (shell rápido)
- Aliases: `v`=nvim, `t`=tmux, `??`=gh copilot

### Git
- Utilizador: Vasco Rafael Azevedo
- Email: 1230776@isep.ipp.pt
- Autenticação GitHub via `gh auth`
