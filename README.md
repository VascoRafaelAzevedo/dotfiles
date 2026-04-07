# dotfiles — VascoRafaelAzevedo

Config pessoal para Debian 13 (trixie) + Hyprland (perfil minimalista).

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
├── wlogout/        wlogout layout + ícones + estilo Gruvbox
├── swaync/         swaync notification center
├── swappy/         swappy screenshot editor
├── cava/           cava visualizador de áudio
├── fastfetch/      fastfetch configs (default + compact)
├── qt5ct/          qt5ct theme config
├── kvantum/        Kvantum theme config
├── tabby/          Tabby terminal + SSH profiles
├── zsh/            .zshrc (Oh My Zsh + Powerlevel10k) + .p10k.zsh
└── git/            .gitconfig (com aliases e delta pager)
```

## Instalação rápida

```bash
git clone https://github.com/VascoRafaelAzevedo/dotfiles ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

O script cria symlinks, faz backup automático de configs existentes, e torna todos os scripts hypr executáveis.

## Setup numa máquina nova (Debian 13)

Para uma instalação limpa, usa o `setup.sh` interativo:

```bash
chmod +x setup.sh
./setup.sh              # modo interativo completo
./setup.sh --dry-run    # pré-visualiza o que seria instalado
./setup.sh --resume     # retoma instalação interrompida
./setup.sh --reset      # limpa estado guardado
```

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
- Integrações: zoxide, fzf, eza, bat

### Git
- Utilizador: Vasco Rafael Azevedo
- Email: 1230776@isep.ipp.pt
- Autenticação GitHub via `gh auth`
- Pager: delta (side-by-side diff)
- Aliases úteis: `lg`, `st`, `co`, `cb`, `cm`, `undo`, `unstage`, `recent`

---

## Troubleshooting

### Plugins do Nvim não instalam
- Abre `nvim`, o lazy.nvim deve auto-instalar. Se não: `:Lazy sync`
- Precisa de `git`, `node`, `npm` (para LSP servers via Mason)

### Waybar não aparece
```bash
killall waybar; waybar &
# verificar logs:
waybar 2>&1 | tail -20
```

### Hyprland scripts sem permissão de execução
```bash
find ~/.config/hypr/scripts ~/.config/hypr/UserScripts -name "*.sh" -exec chmod +x {} \;
chmod +x ~/.config/hypr/initial-boot.sh
```

### swww wallpaper não carrega
```bash
swww-daemon &
swww img ~/.config/hypr/wallpaper_effects/.wallpaper_current
```

### swaync sem notificações
```bash
swaync &
# ou reinicia:
pkill swaync; swaync &
```

### TPM (tmux plugins) não instala
- Dentro de tmux: `Ctrl+a` + `I` (maiúscula)

### Tema Kvantum não aplica
```bash
kvantummanager  # GUI para seleccionar tema
qt5ct           # GUI para qt5 theme engine
```

### Fontes Nerd Font não aparecem
```bash
fc-cache -fv
# verificar:
fc-list | grep -i "FantasqueSans"
```
