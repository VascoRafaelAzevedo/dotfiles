#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Clean install setup para Debian 13 (trixie)
# Instala e configura TUDO: Hyprland, Waybar, Nvim, Kitty, Tmux, Zsh,
# browsers, dev tools, fontes, apps e clona os dotfiles.
#
# Uso:
#   chmod +x bootstrap.sh
#   ./bootstrap.sh
#
# NOTA: Pede sudo no início. Mantém o token activo durante todo o script.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# CORES E HELPERS
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
section() { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════${NC}"; echo -e "${BOLD}${CYAN}  $*${NC}"; echo -e "${BOLD}${BLUE}══════════════════════════════════════════${NC}\n"; }
ok()      { echo -e "${GREEN}  ✓${NC} $*"; }
skip()    { echo -e "${YELLOW}  →${NC} $* (já instalado, a saltar)"; }

has() { command -v "$1" &>/dev/null; }
pkg_installed() { dpkg -l "$1" 2>/dev/null | grep -q "^ii"; }

# Instalar pacote apt se não estiver instalado
apt_install() {
    for pkg in "$@"; do
        if ! pkg_installed "$pkg"; then
            info "apt install: $pkg"
            sudo apt-get install -y "$pkg" 2>/dev/null || warn "Falhou a instalar $pkg"
        else
            skip "$pkg"
        fi
    done
}

DOTFILES_DIR="$HOME/dotfiles"
LOG_FILE="$HOME/bootstrap-install.log"

# ---------------------------------------------------------------------------
# INÍCIO
# ---------------------------------------------------------------------------
echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║       vasco-debian — bootstrap.sh           ║"
echo "║       Debian 13 (trixie) clean install      ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Redirigir output para log também
exec > >(tee -a "$LOG_FILE") 2>&1

# ---------------------------------------------------------------------------
# FASE 0: PREFLIGHT
# ---------------------------------------------------------------------------
section "FASE 0 — Preflight"

# Verificar Debian
if ! grep -q "trixie\|debian" /etc/os-release 2>/dev/null; then
    warn "Não é Debian 13 trixie. Continuando na mesma, mas pode haver problemas."
fi

# Verificar internet
if ! curl -s --max-time 5 https://deb.debian.org > /dev/null; then
    error "Sem ligação à internet. Abortar."
    exit 1
fi
ok "Ligação à internet OK"

# Pedir URL dos dotfiles (ou usar default)
if [ -d "$DOTFILES_DIR" ]; then
    info "Pasta dotfiles já existe em $DOTFILES_DIR — a usar existente."
    DOTFILES_REPO=""
else
    echo ""
    echo -e "${CYAN}Qual é o URL do teu repositório de dotfiles?${NC}"
    echo -e "(ex: https://github.com/vasco/dotfiles)"
    read -rp "  URL: " DOTFILES_REPO
    if [ -z "$DOTFILES_REPO" ]; then
        warn "Sem URL. Os dotfiles não serão clonados automaticamente."
    fi
fi

# Sudo persistente
sudo -v
(while true; do sudo -n true; sleep 50; done) &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

# Update
info "A actualizar o sistema..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
ok "Sistema actualizado"

# ---------------------------------------------------------------------------
# FASE 1: DEPENDÊNCIAS BASE (BUILD TOOLS)
# ---------------------------------------------------------------------------
section "FASE 1 — Dependências de compilação"

apt_install \
    build-essential cmake meson ninja-build pkg-config \
    git curl wget unzip tar zip gzip \
    libssl-dev libffi-dev \
    libwayland-dev wayland-protocols \
    libxkbcommon-dev libxkbcommon-x11-dev \
    libpangocairo-1.0-0 libpango1.0-dev \
    libcairo2-dev libcairo-gobject2 \
    libgdk-pixbuf-2.0-dev \
    libglib2.0-dev libgtk-3-dev \
    libsystemd-dev libudev-dev libinput-dev \
    libdrm-dev libgbm-dev \
    libdbus-1-dev libdbus-glib-1-dev \
    libpipewire-0.3-dev libspa-0.2-dev \
    libjson-glib-dev \
    libfmt-dev libspdlog-dev \
    libpugixml-dev \
    libmagic-dev libmagickwand-dev \
    python3-dev \
    jq bc xdotool

ok "Dependências de compilação instaladas"

# ---------------------------------------------------------------------------
# FASE 2: REPOSITÓRIOS EXTERNOS
# ---------------------------------------------------------------------------
section "FASE 2 — Repositórios externos"

# Brave Browser
if ! pkg_installed brave-browser; then
    info "A adicionar repo do Brave..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
        https://brave-browser-apt-release.s3.brave.com/ stable main" \
        | sudo tee /etc/apt/sources.list.d/brave-browser.list > /dev/null
    ok "Repo Brave adicionado"
else
    skip "Brave repo"
fi

# GitHub Desktop
if ! pkg_installed github-desktop; then
    info "A adicionar repo do GitHub Desktop..."
    wget -qO - https://apt.packages.shiftkey.dev/gpg.key \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/shiftkey-packages.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] \
        https://apt.packages.shiftkey.dev/ubuntu/ any main" \
        | sudo tee /etc/apt/sources.list.d/shiftkey-packages.list > /dev/null
    ok "Repo GitHub Desktop adicionado"
else
    skip "GitHub Desktop repo"
fi

# VSCode
if ! pkg_installed code; then
    info "A adicionar repo do VSCode..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
        https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    ok "Repo VSCode adicionado"
else
    skip "VSCode repo"
fi

# GitHub CLI
if ! pkg_installed gh; then
    info "A adicionar repo do GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    ok "Repo GitHub CLI adicionado"
else
    skip "GitHub CLI repo"
fi

# Tabby Terminal
if ! pkg_installed tabby-terminal; then
    info "A adicionar repo do Tabby..."
    curl -fsSL https://packagecloud.io/Eugeny/tabby/gpgkey \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/tabby.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/tabby.gpg] \
        https://packagecloud.io/Eugeny/tabby/debian/ any main" \
        | sudo tee /etc/apt/sources.list.d/tabby.list > /dev/null
    ok "Repo Tabby adicionado"
else
    skip "Tabby repo"
fi

# Spotify
if ! pkg_installed spotify-client; then
    info "A adicionar repo do Spotify..."
    curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg \
        | sudo gpg --dearmor \
        | sudo tee /usr/share/keyrings/spotify.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/spotify.gpg] \
        http://repository.spotify.com stable non-free" \
        | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
    ok "Repo Spotify adicionado"
else
    skip "Spotify repo"
fi

# Actualizar apt após adicionar repos
sudo apt-get update -qq

# ---------------------------------------------------------------------------
# FASE 3: PACOTES APT
# ---------------------------------------------------------------------------
section "FASE 3 — Pacotes apt"

# --- Wayland / Compositor ---
apt_install \
    kitty tmux zsh \
    waybar \
    btop \
    grim slurp swappy \
    wl-clipboard \
    playerctl \
    pavucontrol \
    blueman \
    network-manager-gnome \
    nwg-displays nwg-look \
    qt5ct qt6ct \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr \
    xdg-utils \
    wlogout \
    pipewire wireplumber pipewire-pulse pipewire-alsa \
    libpipewire-0.3-modules \
    polkit-kde-agent-1 \
    hyprpaper \
    libnotify-bin

# --- Browsers ---
apt_install firefox brave-browser

# --- Dev tools (apt) ---
apt_install \
    code \
    github-desktop \
    gh \
    tabby-terminal \
    default-jdk \
    python3 python3-pip python3-venv python3-full \
    golang-go

# --- Apps ---
apt_install \
    gimp pinta \
    vlc \
    thunar thunar-archive-plugin thunar-volman \
    gvfs gvfs-backends \
    file-roller \
    discord \
    spotify-client \
    qbittorrent \
    nextcloud-desktop \
    calibre \
    obsidian

# --- Utilitários ---
apt_install \
    ripgrep fd-find fzf bat eza \
    htop tree ncdu \
    imagemagick \
    ffmpeg \
    gnome-keyring libsecret-tools \
    xarchiver \
    brightnessctl \
    acpi \
    upower \
    lm-sensors \
    fonts-noto fonts-noto-color-emoji \
    xdg-user-dirs \
    dbus-x11

ok "Todos os pacotes apt instalados"

# ---------------------------------------------------------------------------
# FASE 4: HYPRLAND ECOSYSTEM (from source / JaKooLit)
# ---------------------------------------------------------------------------
section "FASE 4 — Hyprland ecosystem (from source)"

BUILD_DIR="$HOME/.bootstrap-build"
mkdir -p "$BUILD_DIR"

# ---- cliphist (Go) ----
if ! has cliphist; then
    info "A instalar cliphist..."
    go install go.senan.xyz/cliphist@latest
    sudo cp "$HOME/go/bin/cliphist" /usr/local/bin/
    ok "cliphist instalado"
else
    skip "cliphist"
fi

# ---- swww (wallpaper daemon) ----
if ! has swww; then
    info "A instalar swww (wallpaper daemon)..."
    cd "$BUILD_DIR"
    SWWW_VER="0.9.5"
    wget -q "https://github.com/LGFae/swww/releases/download/v${SWWW_VER}/swww-x86_64-unknown-linux-musl.tar.gz"
    tar -xzf "swww-x86_64-unknown-linux-musl.tar.gz"
    sudo cp swww swww-daemon /usr/local/bin/
    chmod +x /usr/local/bin/swww /usr/local/bin/swww-daemon
    ok "swww instalado"
else
    skip "swww"
fi

# ---- Neovim (AppImage — versão estável sempre actualizada) ----
if ! has nvim; then
    info "A instalar Neovim (AppImage)..."
    wget -q "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage" \
        -O /tmp/nvim.appimage
    chmod +x /tmp/nvim.appimage
    sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
    ok "Neovim instalado"
else
    skip "Neovim"
fi

# ---- Rofi-wayland ----
if ! has rofi; then
    info "A instalar rofi-wayland..."
    apt_install \
        libglib2.0-dev libcairo2-dev libpango1.0-dev \
        libxkbcommon-dev libwayland-dev wayland-protocols \
        libxcb1-dev flex bison
    cd "$BUILD_DIR"
    ROFI_VER="1.7.9+wayland1"
    wget -q "https://github.com/lbonn/rofi/releases/download/${ROFI_VER}/rofi-${ROFI_VER}.tar.bz2" 2>/dev/null \
        || git clone --depth=1 https://github.com/lbonn/rofi.git rofi-src
    if [ -d "rofi-src" ]; then
        cd rofi-src
        meson setup build --prefix=/usr/local -Dwayland=enabled -Dxcb=disabled
        ninja -C build
        sudo ninja -C build install
    fi
    ok "rofi-wayland instalado"
else
    skip "rofi"
fi

# ---- Hyprland ecosystem ----
# Usar JaKooLit Debian-Hyprland que já conheces
if ! has hyprland; then
    info "A instalar Hyprland via JaKooLit Debian-Hyprland..."
    cd "$BUILD_DIR"
    git clone --depth=1 https://github.com/JaKooLit/Debian-Hyprland.git
    cd Debian-Hyprland
    # Instalar sem prompt (silent install)
    chmod +x install.sh
    # O script JaKooLit compila tudo: hyprland, hypridle, hyprlock, etc.
    bash install.sh --silent 2>/dev/null || bash install.sh
    ok "Hyprland instalado"
else
    skip "Hyprland"
fi

# Verificar hypridle e hyprlock
if ! has hypridle; then
    warn "hypridle não foi instalado pelo JaKooLit script. A tentar manualmente..."
    cd "$BUILD_DIR"
    git clone --depth=1 https://github.com/hyprwm/hypridle.git
    cd hypridle
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
    cmake --build ./build --config Release --target hypridle -j$(nproc)
    sudo cmake --install build
fi

if ! has hyprlock; then
    warn "hyprlock não foi instalado pelo JaKooLit script. A tentar manualmente..."
    cd "$BUILD_DIR"
    git clone --depth=1 https://github.com/hyprwm/hyprlock.git
    cd hyprlock
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
    cmake --build ./build --config Release --target hyprlock -j$(nproc)
    sudo cmake --install build
fi

ok "Hyprland ecosystem completo"

# ---------------------------------------------------------------------------
# FASE 5: ASUS TOOLS (asusctl + supergfxctl)
# ---------------------------------------------------------------------------
section "FASE 5 — ASUS tools"

if ! has asusctl; then
    info "A instalar asusctl e supergfxctl..."
    cd "$BUILD_DIR"
    # Tentar via JaKooLit ASUS scripts (que já usas neste sistema)
    if [ -d "$HOME/Debian-Hyprland/asusctl" ]; then
        info "Usando JaKooLit asusctl existente..."
        cd "$HOME/Debian-Hyprland/asusctl"
        sudo make install 2>/dev/null || true
    else
        git clone --depth=1 https://github.com/JaKooLit/asusctl.git 2>/dev/null || true
        cd asusctl 2>/dev/null && sudo make install 2>/dev/null || true
    fi
    ok "ASUS tools instalados (se disponível)"
else
    skip "asusctl"
fi

# ---------------------------------------------------------------------------
# FASE 6: RUNTIMES DE LINGUAGENS
# ---------------------------------------------------------------------------
section "FASE 6 — Runtimes de linguagens"

# ---- NVM + Node v22 ----
if [ ! -d "$HOME/.nvm" ]; then
    info "A instalar NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm use 22
    nvm alias default 22
    ok "NVM + Node v22 instalado"
else
    skip "NVM"
fi

# ---- Python (já instalado via apt) ----
if has python3; then
    ok "Python3 já disponível: $(python3 --version)"
else
    warn "Python3 não encontrado"
fi

# ---- Go ----
if ! has go; then
    info "A instalar Go v1.24..."
    GO_VER="1.24.4"
    wget -q "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    echo 'export PATH="/usr/local/go/bin:$PATH"' | sudo tee /etc/profile.d/go.sh > /dev/null
    ok "Go v${GO_VER} instalado"
else
    skip "Go ($(go version | cut -d' ' -f3))"
fi

# ---- Java JDK ----
if has java; then
    ok "Java já disponível: $(java -version 2>&1 | head -1)"
else
    warn "Java não encontrado após apt install"
fi

# ---- Flutter ----
if [ ! -d "$HOME/flutter" ]; then
    info "A instalar Flutter (stable)..."
    git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
    export PATH="$HOME/flutter/bin:$PATH"
    flutter precache --quiet
    ok "Flutter instalado em ~/flutter"
else
    skip "Flutter (já existe ~/flutter)"
fi

# ---- Android SDK (command line tools) ----
ANDROID_HOME="$HOME/Android"
if [ ! -d "$ANDROID_HOME/cmdline-tools" ]; then
    info "A instalar Android SDK command line tools..."
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    wget -q "$CMDTOOLS_URL" -O /tmp/cmdtools.zip
    unzip -q /tmp/cmdtools.zip -d /tmp/cmdtools-extract
    mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
    mv /tmp/cmdtools-extract/cmdline-tools/* "$ANDROID_HOME/cmdline-tools/latest/"
    rm -rf /tmp/cmdtools.zip /tmp/cmdtools-extract

    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
    yes | sdkmanager --licenses > /dev/null 2>&1 || true
    sdkmanager "platform-tools" "build-tools;35.0.0" "platforms;android-35" --quiet
    ok "Android SDK instalado"
else
    skip "Android SDK"
fi

# ---- Android Studio ----
if ! has android-studio && [ ! -d "/usr/local/android-studio" ]; then
    info "A instalar Android Studio..."
    AS_VER="2024.3.1.14"
    wget -q "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${AS_VER}/android-studio-${AS_VER}-linux.tar.gz" \
        -O /tmp/android-studio.tar.gz
    sudo tar -xzf /tmp/android-studio.tar.gz -C /usr/local/
    sudo ln -sf /usr/local/android-studio/bin/studio.sh /usr/local/bin/android-studio
    rm /tmp/android-studio.tar.gz
    ok "Android Studio instalado"
else
    skip "Android Studio"
fi

# ---------------------------------------------------------------------------
# FASE 7: ZSH + OH MY ZSH + POWERLEVEL10K
# ---------------------------------------------------------------------------
section "FASE 7 — Shell setup"

# Mudar default shell para Zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    info "A mudar default shell para Zsh..."
    sudo chsh -s "$(which zsh)" "$USER"
    ok "Shell mudada para Zsh"
else
    skip "Zsh já é o shell padrão"
fi

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "A instalar Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh My Zsh instalado"
else
    skip "Oh My Zsh"
fi

OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Powerlevel10k
if [ ! -d "$OMZ_CUSTOM/themes/powerlevel10k" ]; then
    info "A instalar Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$OMZ_CUSTOM/themes/powerlevel10k"
    ok "Powerlevel10k instalado"
else
    skip "Powerlevel10k"
fi

# zsh-autosuggestions
if [ ! -d "$OMZ_CUSTOM/plugins/zsh-autosuggestions" ]; then
    info "A instalar zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$OMZ_CUSTOM/plugins/zsh-autosuggestions"
    ok "zsh-autosuggestions instalado"
else
    skip "zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [ ! -d "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    info "A instalar zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
    ok "zsh-syntax-highlighting instalado"
else
    skip "zsh-syntax-highlighting"
fi

# ---------------------------------------------------------------------------
# FASE 8: TPM — TMUX PLUGIN MANAGER
# ---------------------------------------------------------------------------
section "FASE 8 — Tmux Plugin Manager"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "A instalar TPM..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ok "TPM instalado"
else
    skip "TPM"
fi

# ---------------------------------------------------------------------------
# FASE 9: FONTES — JetBrainsMono Nerd Font
# ---------------------------------------------------------------------------
section "FASE 9 — Nerd Fonts"

FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
    info "A instalar JetBrainsMono Nerd Font..."
    NERD_VER="v3.3.0"
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VER}/JetBrainsMono.zip" \
        -O /tmp/JetBrainsMono.zip
    unzip -q /tmp/JetBrainsMono.zip -d "$FONTS_DIR/JetBrainsMono/"
    rm /tmp/JetBrainsMono.zip
    fc-cache -fv > /dev/null
    ok "JetBrainsMono Nerd Font instalada"
else
    skip "JetBrainsMono Nerd Font"
fi

# FantasqueSansM (usada pelo kitty)
if ! fc-list | grep -qi "FantasqueSansM"; then
    info "A instalar FantasqueSansM Nerd Font (Kitty)..."
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VER}/FantasqueSansMono.zip" \
        -O /tmp/FantasqueSansMono.zip
    unzip -q /tmp/FantasqueSansMono.zip -d "$FONTS_DIR/FantasqueSansMono/"
    rm /tmp/FantasqueSansMono.zip
    fc-cache -fv > /dev/null
    ok "FantasqueSansM Nerd Font instalada"
else
    skip "FantasqueSansM Nerd Font"
fi

# ---------------------------------------------------------------------------
# FASE 10: APPS ESPECIAIS
# ---------------------------------------------------------------------------
section "FASE 10 — Apps especiais"

# ---- Spicetify ----
if ! has spicetify; then
    info "A instalar Spicetify..."
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
    export PATH="$HOME/.spicetify:$PATH"
    # Aplicar após Spotify estar configurado
    info "A aplicar Spicetify ao Spotify..."
    spicetify backup apply 2>/dev/null || warn "Spicetify: corre 'spicetify backup apply' manualmente após iniciar o Spotify uma vez."
    ok "Spicetify instalado"
else
    skip "Spicetify"
fi

# ---- Postman ----
if ! has postman && [ ! -d "$HOME/.local/share/Postman" ]; then
    info "A instalar Postman..."
    wget -q "https://dl.pstmn.io/download/latest/linux64" -O /tmp/postman.tar.gz
    tar -xzf /tmp/postman.tar.gz -C "$HOME/.local/share/"
    ln -sf "$HOME/.local/share/Postman/Postman" "$HOME/.local/bin/postman"
    rm /tmp/postman.tar.gz
    # Criar .desktop entry
    cat > "$HOME/.local/share/applications/postman.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Postman
Exec=/home/$USER/.local/share/Postman/Postman
Icon=/home/$USER/.local/share/Postman/app/resources/app/assets/icon.png
Terminal=false
Categories=Development;
DESKTOP
    ok "Postman instalado"
else
    skip "Postman"
fi

# ---- nwg-look + qt5ct + qt6ct (GTK/Qt theming) ----
# Já instalados em Fase 3 via apt
ok "nwg-look + qt5ct + qt6ct já tratados na Fase 3"

# ---- polkit-kde-authentication-agent ----
# Já instalado em Fase 3 via apt
ok "polkit-kde já tratado na Fase 3"

# ---------------------------------------------------------------------------
# FASE 11: DOTFILES
# ---------------------------------------------------------------------------
section "FASE 11 — Dotfiles"

if [ -n "${DOTFILES_REPO:-}" ] && [ ! -d "$DOTFILES_DIR" ]; then
    info "A clonar dotfiles de $DOTFILES_REPO..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    ok "Dotfiles clonados para $DOTFILES_DIR"
fi

if [ -d "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/install.sh" ]; then
    info "A correr install.sh dos dotfiles..."
    chmod +x "$DOTFILES_DIR/install.sh"
    bash "$DOTFILES_DIR/install.sh"
    ok "Dotfiles instalados"
else
    warn "Dotfiles não encontrados em $DOTFILES_DIR. Configura manualmente."
fi

# ---------------------------------------------------------------------------
# FASE 12: ESTRUTURA DE PASTAS DEV
# ---------------------------------------------------------------------------
section "FASE 12 — Estrutura de pastas DEV"

mkdir -p "$HOME/Desktop/DEV/Versioned/College"
mkdir -p "$HOME/Desktop/DEV/Versioned/Personal"
mkdir -p "$HOME/Desktop/DEV/Versioned/Work"
mkdir -p "$HOME/Desktop/DEV/Unversioned/College"
mkdir -p "$HOME/Desktop/DEV/Unversioned/Personal"
mkdir -p "$HOME/Desktop/DEV/Unversioned/Work"
ok "Estrutura DEV criada:"
echo "  ~/Desktop/DEV/"
echo "  ├── Versioned/"
echo "  │   ├── College/"
echo "  │   ├── Personal/"
echo "  │   └── Work/"
echo "  └── Unversioned/"
echo "      ├── College/"
echo "      ├── Personal/"
echo "      └── Work/"

# ---------------------------------------------------------------------------
# FASE 13: POST-INSTALL — ENVIRONMENT VARS NO .ZSHRC (se dotfiles não fizeram)
# ---------------------------------------------------------------------------
section "FASE 13 — Variáveis de ambiente"

ZSHRC="$HOME/.zshrc"

append_if_missing() {
    local line="$1"
    local file="$2"
    grep -qF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# Android
append_if_missing 'export ANDROID_HOME="$HOME/Android"' "$ZSHRC"
append_if_missing 'export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"' "$ZSHRC"

# Flutter
append_if_missing 'export PATH="$HOME/flutter/bin:$PATH"' "$ZSHRC"

# Go
append_if_missing 'export PATH="/usr/local/go/bin:$PATH"' "$ZSHRC"

# Spicetify
append_if_missing 'export PATH="$HOME/.spicetify:$PATH"' "$ZSHRC"

# Local bin
append_if_missing 'export PATH="$HOME/.local/bin:$PATH"' "$ZSHRC"

ok "Variáveis de ambiente adicionadas ao .zshrc"

# ---------------------------------------------------------------------------
# LIMPEZA
# ---------------------------------------------------------------------------
section "Limpeza"
sudo apt-get autoremove -y -qq
sudo apt-get clean -qq
ok "Sistema limpo"

# ---------------------------------------------------------------------------
# RESUMO FINAL
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║         BOOTSTRAP COMPLETO!  ✓              ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Passos manuais ainda necessários:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Reinicia o sistema:         ${YELLOW}sudo reboot${NC}"
echo -e "  ${CYAN}2.${NC} Inicia o Hyprland no login manager"
echo -e "  ${CYAN}3.${NC} Abre o Spotify uma vez e corre: ${YELLOW}spicetify backup apply${NC}"
echo -e "  ${CYAN}4.${NC} Autentica o GitHub CLI:     ${YELLOW}gh auth login${NC}"
echo -e "  ${CYAN}5.${NC} Configura o git:            ${YELLOW}git config --global user.name \"...\"${NC}"
echo -e "  ${CYAN}6.${NC} Abre nvim — plugins instalam-se automaticamente"
echo -e "  ${CYAN}7.${NC} No tmux, corre:             ${YELLOW}Prefix + I${NC} para instalar plugins"
echo -e "  ${CYAN}8.${NC} Instala Android Studio SDK: ${YELLOW}android-studio${NC}"
echo -e "  ${CYAN}9.${NC} Flutter doctor:             ${YELLOW}flutter doctor${NC}"
echo -e " ${CYAN}10.${NC} Wallpaper: coloca imagens em ${YELLOW}~/Pictures/wallpapers/${NC}"
echo -e " ${CYAN}11.${NC} Nextcloud: faz login na app"
echo -e " ${CYAN}12.${NC} Tabby: as configs SSH foram restauradas pelos dotfiles"
echo ""
echo -e "  Log completo em: ${YELLOW}$LOG_FILE${NC}"
echo ""
