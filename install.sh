#!/usr/bin/env bash
# install.sh — cria symlinks dos dotfiles para os locais certos
# Uso: ./install.sh
# Funciona a partir de ~/dotfiles

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[-]${NC} $1"; }

backup_and_link() {
    local src="$1"
    local dst="$2"

    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backup: $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    elif [ -L "$dst" ]; then
        rm "$dst"
    fi

    ln -sf "$src" "$dst"
    info "Linked: $dst → $src"
}

echo ""
echo "╔══════════════════════════════════╗"
echo "║   vasco-debian dotfiles install  ║"
echo "╚══════════════════════════════════╝"
echo ""

# ~/.config entries
backup_and_link "$DOTFILES_DIR/nvim"      "$CONFIG_DIR/nvim"
backup_and_link "$DOTFILES_DIR/kitty"     "$CONFIG_DIR/kitty"
backup_and_link "$DOTFILES_DIR/hypr"      "$CONFIG_DIR/hypr"
backup_and_link "$DOTFILES_DIR/waybar"    "$CONFIG_DIR/waybar"
backup_and_link "$DOTFILES_DIR/rofi"      "$CONFIG_DIR/rofi"
backup_and_link "$DOTFILES_DIR/btop"      "$CONFIG_DIR/btop"
backup_and_link "$DOTFILES_DIR/wlogout"   "$CONFIG_DIR/wlogout"
backup_and_link "$DOTFILES_DIR/tabby"     "$CONFIG_DIR/tabby"
backup_and_link "$DOTFILES_DIR/swaync"    "$CONFIG_DIR/swaync"
backup_and_link "$DOTFILES_DIR/swappy"    "$CONFIG_DIR/swappy"
backup_and_link "$DOTFILES_DIR/cava"      "$CONFIG_DIR/cava"
backup_and_link "$DOTFILES_DIR/fastfetch" "$CONFIG_DIR/fastfetch"
backup_and_link "$DOTFILES_DIR/qt5ct"     "$CONFIG_DIR/qt5ct"
backup_and_link "$DOTFILES_DIR/kvantum"   "$CONFIG_DIR/Kvantum"

# tmux
backup_and_link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.tmux"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "A instalar TPM (tmux plugin manager)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
# copiar scripts mru
cp "$DOTFILES_DIR/tmux/scripts/mru-next.sh"   "$HOME/.tmux/mru-next.sh"
cp "$DOTFILES_DIR/tmux/scripts/mru-update.sh" "$HOME/.tmux/mru-update.sh"
chmod +x "$HOME/.tmux/mru-next.sh" "$HOME/.tmux/mru-update.sh"
info "Tmux scripts copiados para ~/.tmux/"

# chmod para todos os scripts do hyprland
find "$CONFIG_DIR/hypr/scripts" "$CONFIG_DIR/hypr/UserScripts" \
    -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
[[ -f "$CONFIG_DIR/hypr/initial-boot.sh" ]] && chmod +x "$CONFIG_DIR/hypr/initial-boot.sh"
info "Scripts hyprland marcados como executáveis"

# zsh
backup_and_link "$DOTFILES_DIR/zsh/.zshrc"   "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# git
backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

echo ""
echo -e "${GREEN}✓ Instalação completa!${NC}"
echo ""
echo "Passos seguintes:"
echo "  1. Tmux: abre tmux e corre  Prefix + I  para instalar os plugins"
echo "  2. Nvim: abre nvim — o lazy.nvim instala os plugins automaticamente"
echo "  3. Hyprland: reinicia ou corre  hyprctl reload"
echo "  4. Waybar: reinicia com  killall waybar && waybar &"
echo ""
