#!/usr/bin/env bash
# =============================================================================
#  setup.sh — Interactive installer para Debian 13 (trixie)
#  Autor: VascoRafaelAzevedo | dotfiles
#
#  Uso:
#    chmod +x setup.sh && ./setup.sh [--dry-run] [--resume]
#
#  Flags:
#    --dry-run    Mostra o que seria instalado sem instalar nada
#    --resume     Retoma a partir de uma sessão anterior (usa ~/.setup-state)
#    --reset      Limpa o estado guardado e começa do início
#
#  O script:
#    1. Faz perguntas sobre o que queres instalar
#    2. Mostra listas numeradas de apps opcionais por categoria
#    3. Só instala o que confirmares
#    4. É idempotente (podes correr várias vezes)
# =============================================================================
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# FLAGS
# ─────────────────────────────────────────────────────────────
DRY_RUN=false
RESUME=false
STATE_FILE="$HOME/.setup-state"

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --resume)  RESUME=true ;;
        --reset)   rm -f "$STATE_FILE"; echo "Estado limpo."; exit 0 ;;
        --help|-h)
            echo "Uso: $0 [--dry-run] [--resume] [--reset]"
            echo "  --dry-run  Mostra o que seria instalado sem instalar nada"
            echo "  --resume   Retoma sessão anterior guardada em ~/.setup-state"
            echo "  --reset    Limpa estado guardado"
            exit 0 ;;
    esac
done

# ─────────────────────────────────────────────────────────────
# CORES
# ─────────────────────────────────────────────────────────────
RED='\033[0;31m';   GREEN='\033[0;32m';   YELLOW='\033[1;33m'
BLUE='\033[0;34m';  CYAN='\033[0;36m';   MAGENTA='\033[0;35m'
BOLD='\033[1m';     DIM='\033[2m';       NC='\033[0m'

info()    { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${NC} $*"; }
error()   { echo -e "${RED}  ✗${NC} $*" >&2; }
step()    { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }
section() {
    echo ""
    echo -e "${BOLD}${BLUE}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${BLUE}│  ${CYAN}$*${BLUE}${NC}"
    echo -e "${BOLD}${BLUE}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
}
has()           { command -v "$1" &>/dev/null; }
pkg_installed() { dpkg -l "$1" 2>/dev/null | grep -q "^ii"; }
add_path()      { grep -qF "$1" "${ZSHRC:-$HOME/.zshrc}" 2>/dev/null || echo "$1" >> "${ZSHRC:-$HOME/.zshrc}"; }
latest_gh_release() { curl -s "https://api.github.com/repos/$1/releases/latest" | grep -oP '"tag_name":\s*"\K[^"]+'; }

# ─────────────────────────────────────────────────────────────
# VARIÁVEIS GLOBAIS (preenchidas durante Q&A)
# ─────────────────────────────────────────────────────────────
INSTALL_HYPRLAND=false
INSTALL_WM_EXTRAS=false     # waybar, rofi, wlogout, swww, hyprlock, hypridle
INSTALL_DOTFILES=false
DOTFILES_REPO=""

INSTALL_NVM=false
INSTALL_GO=false
INSTALL_JAVA=false
INSTALL_RUST=false
INSTALL_PHP=false
INSTALL_RUBY=false
INSTALL_DOTNET=false
INSTALL_FLUTTER=false
INSTALL_PYTHON_EXTRAS=false   # pyenv, poetry, pipx

INSTALL_DOCKER=false
INSTALL_DOCKER_COMPOSE=false
INSTALL_PORTAINER=false
INSTALL_KUBECTL=false
INSTALL_HELM=false
INSTALL_TERRAFORM=false
INSTALL_AWSCLI=false
INSTALL_ANSIBLE=false

INSTALL_ASUS=false
INSTALL_NVIDIA=false
INSTALL_BLUETOOTH=false

INSTALL_DEV_FOLDERS=false

# Browsers
INSTALL_VSCODE=false
INSTALL_GITHUB_DESKTOP=false
INSTALL_GH_CLI=false
INSTALL_TABBY=false
INSTALL_COPILOT_CLI=false

# Languages extended
INSTALL_KOTLIN=false
INSTALL_LUA=false
INSTALL_HASKELL=false
INSTALL_ELIXIR=false
INSTALL_ZIG=false
INSTALL_BUN=false
INSTALL_DENO=false
INSTALL_WASM=false
INSTALL_R=false
INSTALL_JULIA=false
INSTALL_SWIFT=false
INSTALL_ANDROID_SDK=false
INSTALL_ANDROID_STUDIO=false

# DevOps extended
INSTALL_K9S=false
INSTALL_PODMAN=false
INSTALL_GCLOUD=false
INSTALL_AZURECLI=false
INSTALL_VAGRANT=false
INSTALL_PACKER=false
INSTALL_PULUMI=false
INSTALL_TRIVY=false
INSTALL_LAZYDOCKER=false
INSTALL_CTOP=false
INSTALL_DIVE=false
INSTALL_ACT=false
INSTALL_NGROK=false

# Dev tools
INSTALL_POSTMAN=false
INSTALL_INSOMNIA=false
INSTALL_DBEAVER=false
INSTALL_TABLEPLUS=false
INSTALL_GITKRAKEN=false
INSTALL_MELD=false
INSTALL_DIFFUSE=false
INSTALL_WIRESHARK=false
INSTALL_BEEKEEPER=false
INSTALL_BRUNO=false
INSTALL_HOPPSCOTCH=false
INSTALL_PGADMIN=false
INSTALL_REDIS_COMMANDER=false
INSTALL_MONGO_EXPRESS=false
INSTALL_SEQ=false
INSTALL_SOAPUI=false
INSTALL_HTTPIE=false
INSTALL_POCKETBASE=false
INSTALL_LOCALSTACK=false
INSTALL_MAILHOG=false
INSTALL_MITMPROXY=false
INSTALL_TELEPRESENCE=false

# Databases
INSTALL_POSTGRES=false
INSTALL_MYSQL=false
INSTALL_REDIS_SERVER=false
INSTALL_MONGODB=false
INSTALL_SQLITE_TOOLS=false
INSTALL_ELASTICSEARCH=false
INSTALL_CASSANDRA=false
INSTALL_COCKROACHDB=false
INSTALL_INFLUXDB=false
INSTALL_MINIO=false

# Arrays com os números das apps opcionais seleccionadas por categoria
WM_EXTRAS_SEL=()
SEL_BROWSERS=()
SEL_LANGUAGES=()
SEL_DEVOPS=()
SEL_DEVTOOLS=()
SEL_DATABASES=()
SEL_TERMINAL=()
SEL_MULTIMEDIA=()
SEL_COMMUNICATION=()
SEL_PRODUCTIVITY=()
SEL_GAMING=()
SEL_FONTS=()
SEL_THEMES=()
SEL_SYSTEM=()

LOG_FILE="$HOME/setup-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ─────────────────────────────────────────────────────────────
# FUNÇÕES DE INTERACÇÃO
# ─────────────────────────────────────────────────────────────
ask_yn() {
    # ask_yn "Pergunta?" [default: y/n]
    local prompt="$1"
    local default="${2:-y}"
    local hint
    if [[ "$default" == "y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi

    while true; do
        echo -en "${BOLD}  ${prompt} ${DIM}${hint}${NC} "
        read -r reply
        reply="${reply:-$default}"
        case "${reply,,}" in
            y|yes|s|sim) return 0 ;;
            n|no|nao|não) return 1 ;;
            *) echo -e "${RED}  Responde y ou n.${NC}" ;;
        esac
    done
}

ask_input() {
    # ask_input "Prompt" [default]
    local prompt="$1"
    local default="${2:-}"
    local hint=""
    [[ -n "$default" ]] && hint=" ${DIM}(default: $default)${NC}"
    echo -en "${BOLD}  ${prompt}${hint}${BOLD}: ${NC}"
    read -r reply
    echo "${reply:-$default}"
}

# Mostra menu numerado e lê selecção (ex: "1,3,5-7,all,none")
# Uso: select_menu "Título" "item1" "item2" ...
# Resultado fica no array global MENU_RESULT (lista de índices 0-based)
MENU_RESULT=()
select_menu() {
    local title="$1"; shift
    local items=("$@")
    local total=${#items[@]}

    echo ""
    echo -e "${BOLD}${MAGENTA}  ╔══ ${title} ══╗${NC}"
    echo ""
    for i in "${!items[@]}"; do
        printf "    ${CYAN}%3d${NC}. %s\n" "$((i+1))" "${items[$i]}"
    done
    echo ""
    echo -e "  ${DIM}Digite os números separados por vírgulas (ex: 1,3,5)${NC}"
    echo -e "  ${DIM}  'all'  → seleccionar tudo${NC}"
    echo -e "  ${DIM}  'none' → não seleccionar nada${NC}"
    echo -en "  ${BOLD}Selecção: ${NC}"
    read -r raw

    MENU_RESULT=()
    raw="${raw// /}"   # remove spaces

    if [[ "${raw,,}" == "all" ]]; then
        for i in "${!items[@]}"; do MENU_RESULT+=("$i"); done
        return
    fi
    if [[ -z "$raw" || "${raw,,}" == "none" ]]; then
        return
    fi

    IFS=',' read -ra parts <<< "$raw"
    for part in "${parts[@]}"; do
        if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local from=$(( BASH_REMATCH[1] - 1 ))
            local to=$(( BASH_REMATCH[2] - 1 ))
            for (( k=from; k<=to && k<total; k++ )); do
                MENU_RESULT+=("$k")
            done
        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            local idx=$(( part - 1 ))
            (( idx >= 0 && idx < total )) && MENU_RESULT+=("$idx")
        fi
    done
}

in_array() {
    local val="$1"; shift
    for v in "$@"; do [[ "$v" == "$val" ]] && return 0; done
    return 1
}

# ─────────────────────────────────────────────────────────────
# CABEÇALHO
# ─────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║        INTERACTIVE SETUP — Debian 13 (trixie)    ║"
echo "  ║        VascoRafaelAzevedo/dotfiles                ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${DIM}Log: $LOG_FILE${NC}"
echo ""
echo -e "  ${GREEN}Core (sempre instalado):${NC} zsh, nvim, tmux, kitty, git, curl, build-tools, Oh My Zsh, Powerlevel10k"
echo ""

# Não correr como root directamente
if [[ $EUID -eq 0 ]]; then
    error "Não corras este script como root. Usa um utilizador normal com sudo."
    exit 1
fi

# Verificar internet
if ! curl -s --max-time 5 https://deb.debian.org > /dev/null; then
    error "Sem ligação à internet. Abortar."
    exit 1
fi
info "Ligação à internet OK"

# Verificar Debian
if ! grep -qi "debian\|trixie" /etc/os-release 2>/dev/null; then
    warn "Não detectado Debian 13. Este script foi testado em trixie."
fi

# Sudo agora para não pedir mais tarde
sudo -v
(while true; do sudo -n true; sleep 50; done) &
SUDO_PID=$!
trap 'kill "$SUDO_PID" 2>/dev/null; echo ""' EXIT INT TERM

# Carregar estado anterior se --resume
if [[ "$RESUME" == true ]]; then
    if [[ -f "$STATE_FILE" ]]; then
        info "A carregar sessão anterior de $STATE_FILE ..."
        # shellcheck source=/dev/null
        source "$STATE_FILE"
        echo -e "\n${GREEN}Estado carregado. A saltar Q&A e a ir directo para instalação.${NC}\n"
        # Saltar para a instalação
    else
        warn "Nenhum estado guardado encontrado ($STATE_FILE). A começar do início."
        RESUME=false
    fi
fi

if [[ "$RESUME" == false ]]; then
section "1/9 — AMBIENTE GRÁFICO"

echo -e "  ${BOLD}Queres instalar o Hyprland (tiling Wayland compositor)?${NC}"
echo -e "  ${DIM}Inclui: hyprland, hypridle, hyprlock, hyprpaper, xdg-portal, pipewire, wireplumber${NC}"
echo ""
if ask_yn "Instalar Hyprland?" y; then
    INSTALL_HYPRLAND=true
    echo ""
    echo -e "  ${BOLD}Extras do Hyprland:${NC}"
    echo -e "  ${DIM}(recomendado se for instalação completa)${NC}"
    echo ""

    extras=(
        "Waybar — barra de estado"
        "Rofi — launcher de aplicações"
        "Wlogout — menu de power (lock/sleep/reboot/shutdown)"
        "swww — wallpaper daemon (animado)"
        "Hyprlock — ecrã de bloqueio"
        "Hypridle — idle daemon (desliga ecrã ao fim de X min)"
        "Cliphist — gestor de clipboard"
        "Swappy — editor de screenshots"
        "Grim + Slurp — screenshots"
        "Nwg-displays — gestor de monitores (GUI)"
        "Nwg-look — gestor de temas GTK"
        "Wl-clipboard — clipboard CLI"
        "Playerctl — controlo de media (teclado)"
        "Polkit KDE agent"
        "Blueman — gestor de Bluetooth (tray)"
        "Network Manager Applet (nm-applet)"
        "Wallust — gerador de temas por wallpaper"
        "Pywal — alternativa ao wallust"
    )
    select_menu "Extras Hyprland — selecciona o que queres" "${extras[@]}"
    WM_EXTRAS_SEL=("${MENU_RESULT[@]}")

    INSTALL_WM_EXTRAS=true
    echo ""
    echo -e "  ${DIM}Seleccionados ${#WM_EXTRAS_SEL[@]} extras${NC}"
fi

# ═══════════════════════════════════════════════════════════════
# BLOCO 2: BROWSERS
# ═══════════════════════════════════════════════════════════════
section "2/9 — BROWSERS"

browsers=(
    "Firefox — browser open-source da Mozilla"
    "Brave — browser focado em privacidade (Chromium-based)"
    "Chromium — versão open-source do Chrome"
    "Google Chrome — browser Google"
    "LibreWolf — fork do Firefox ultra-privado"
    "Tor Browser — anonimato máximo"
    "Vivaldi — browser customizável"
    "Opera — browser com VPN grátis"
)
select_menu "BROWSERS" "${browsers[@]}"
SEL_BROWSERS=("${MENU_RESULT[@]}")

# ═══════════════════════════════════════════════════════════════
# BLOCO 3: LINGUAGENS E RUNTIMES
# ═══════════════════════════════════════════════════════════════
section "3/9 — LINGUAGENS & RUNTIMES"

echo -e "  ${DIM}Podes seleccionar múltiplas linguagens. Core já tem python3 básico.${NC}"
echo ""

languages=(
    "Node.js via NVM (gestor de versões) — v22 LTS por defeito"
    "Python extras: pyenv + poetry + pipx"
    "Go (golang) — versão mais recente"
    "Java JDK (OpenJDK 21 LTS)"
    "Rust via rustup (instala rustc + cargo)"
    "PHP + Composer"
    "Ruby via rbenv"
    ".NET SDK (Microsoft)"
    "Flutter + Dart (mobile/cross-platform)"
    "Kotlin (standalone, para Android)"
    "Lua (5.4)"
    "Haskell (GHCup)"
    "Elixir + Erlang"
    "Zig (baixa de ziglang.org)"
    "Bun (runtime JS alternativo ao Node)"
    "Deno (runtime JS/TS seguro)"
    "WASM tools (wabt, emscripten)"
    "R (estatística)"
    "Julia (computação científica)"
    "Swift (Apple, via swiftly installer)"
    "Android SDK + command line tools"
    "Android Studio (IDE completo)"
)
select_menu "LINGUAGENS & RUNTIMES" "${languages[@]}"
SEL_LANGUAGES=("${MENU_RESULT[@]}")

# Parse selecções individuais de linguagens
for idx in "${SEL_LANGUAGES[@]}"; do
    case $idx in
        0) INSTALL_NVM=true ;;
        1) INSTALL_PYTHON_EXTRAS=true ;;
        2) INSTALL_GO=true ;;
        3) INSTALL_JAVA=true ;;
        4) INSTALL_RUST=true ;;
        5) INSTALL_PHP=true ;;
        6) INSTALL_RUBY=true ;;
        7) INSTALL_DOTNET=true ;;
        8) INSTALL_FLUTTER=true ;;
        9) INSTALL_KOTLIN=true ;;
        10) INSTALL_LUA=true ;;
        11) INSTALL_HASKELL=true ;;
        12) INSTALL_ELIXIR=true ;;
        13) INSTALL_ZIG=true ;;
        14) INSTALL_BUN=true ;;
        15) INSTALL_DENO=true ;;
        16) INSTALL_WASM=true ;;
        17) INSTALL_R=true ;;
        18) INSTALL_JULIA=true ;;
        19) INSTALL_SWIFT=true ;;
        20) INSTALL_ANDROID_SDK=true ;;
        21) INSTALL_ANDROID_STUDIO=true ;;
    esac
done

# ═══════════════════════════════════════════════════════════════
# BLOCO 4: CONTAINERS & DEVOPS
# ═══════════════════════════════════════════════════════════════
section "4/9 — CONTAINERS & DEVOPS"

devops_tools=(
    "Docker Engine + Docker Compose v2"
    "Portainer CE (web UI para Docker, corre num container)"
    "Podman (alternativa rootless ao Docker)"
    "kubectl (controlo de Kubernetes)"
    "Helm (package manager Kubernetes)"
    "k9s (TUI para Kubernetes)"
    "Terraform (infra as code)"
    "Ansible (automação de servidores)"
    "AWS CLI v2"
    "Google Cloud CLI (gcloud)"
    "Azure CLI"
    "Vagrant + VirtualBox"
    "Packer (build de VMs)"
    "Pulumi (infra as code alternativo)"
    "Trivy (scanner de vulnerabilidades)"
    "lazydocker (TUI para Docker)"
    "ctop (monitor de containers)"
    "dive (análise de layers Docker)"
    "act (correr GitHub Actions localmente)"
    "ngrok (túneis HTTP)"
)
select_menu "CONTAINERS & DEVOPS" "${devops_tools[@]}"
SEL_DEVOPS=("${MENU_RESULT[@]}")

for idx in "${SEL_DEVOPS[@]}"; do
    case $idx in
        0) INSTALL_DOCKER=true; INSTALL_DOCKER_COMPOSE=true ;;
        1) INSTALL_PORTAINER=true ;;
        2) INSTALL_PODMAN=true ;;
        3) INSTALL_KUBECTL=true ;;
        4) INSTALL_HELM=true ;;
        5) INSTALL_K9S=true ;;
        6) INSTALL_TERRAFORM=true ;;
        7) INSTALL_ANSIBLE=true ;;
        8) INSTALL_AWSCLI=true ;;
        9) INSTALL_GCLOUD=true ;;
        10) INSTALL_AZURECLI=true ;;
        11) INSTALL_VAGRANT=true ;;
        12) INSTALL_PACKER=true ;;
        13) INSTALL_PULUMI=true ;;
        14) INSTALL_TRIVY=true ;;
        15) INSTALL_LAZYDOCKER=true ;;
        16) INSTALL_CTOP=true ;;
        17) INSTALL_DIVE=true ;;
        18) INSTALL_ACT=true ;;
        19) INSTALL_NGROK=true ;;
    esac
done

# ═══════════════════════════════════════════════════════════════
# BLOCO 5: FERRAMENTAS DE DESENVOLVIMENTO
# ═══════════════════════════════════════════════════════════════
section "5/9 — FERRAMENTAS DE DESENVOLVIMENTO"

devtools=(
    "VS Code (Microsoft)"
    "GitHub Desktop"
    "GitHub CLI (gh)"
    "Postman (API testing)"
    "Insomnia (API testing alternativo)"
    "DBeaver CE (GUI para bases de dados)"
    "TablePlus (GUI para DBs — AppImage)"
    "GitKraken (GUI para git)"
    "Meld (diff visual)"
    "Diffuse (diff visual leve)"
    "Wireshark (análise de rede)"
    "Beekeeper Studio (GUI para DBs — open source)"
    "Bruno (API testing open source)"
    "Hoppscotch (AppImage — alternativa Postman)"
    "pgAdmin 4 (GUI para PostgreSQL)"
    "Redis Commander (web UI para Redis)"
    "Mongo Express (web UI para MongoDB)"
    "Seq (log aggregator — Docker)"
    "SoapUI (SOAP/REST testing)"
    "HTTPie Desktop"
    "Pocketbase (backend leve)"
    "Localstack (AWS local)"
    "Mailhog (SMTP local para dev)"
    "Mitmproxy (proxy HTTP para debug)"
    "Telepresence (debug remoto Kubernetes)"
)
select_menu "FERRAMENTAS DE DESENVOLVIMENTO" "${devtools[@]}"
SEL_DEVTOOLS=("${MENU_RESULT[@]}")

for idx in "${SEL_DEVTOOLS[@]}"; do
    case $idx in
        0) INSTALL_VSCODE=true ;;
        1) INSTALL_GITHUB_DESKTOP=true ;;
        2) INSTALL_GH_CLI=true ;;
        3) INSTALL_POSTMAN=true ;;
        4) INSTALL_INSOMNIA=true ;;
        5) INSTALL_DBEAVER=true ;;
        6) INSTALL_TABLEPLUS=true ;;
        7) INSTALL_GITKRAKEN=true ;;
        8) INSTALL_MELD=true ;;
        9) INSTALL_DIFFUSE=true ;;
        10) INSTALL_WIRESHARK=true ;;
        11) INSTALL_BEEKEEPER=true ;;
        12) INSTALL_BRUNO=true ;;
        13) INSTALL_HOPPSCOTCH=true ;;
        14) INSTALL_PGADMIN=true ;;
        15) INSTALL_REDIS_COMMANDER=true ;;
        16) INSTALL_MONGO_EXPRESS=true ;;
        17) INSTALL_SEQ=true ;;
        18) INSTALL_SOAPUI=true ;;
        19) INSTALL_HTTPIE=true ;;
        20) INSTALL_POCKETBASE=true ;;
        21) INSTALL_LOCALSTACK=true ;;
        22) INSTALL_MAILHOG=true ;;
        23) INSTALL_MITMPROXY=true ;;
        24) INSTALL_TELEPRESENCE=true ;;
    esac
done

# ═══════════════════════════════════════════════════════════════
# BLOCO 6: BASES DE DADOS
# ═══════════════════════════════════════════════════════════════
section "6/9 — BASES DE DADOS"

databases=(
    "PostgreSQL (servidor local)"
    "MySQL / MariaDB"
    "Redis"
    "MongoDB"
    "SQLite + ferramentas"
    "Elasticsearch"
    "Cassandra"
    "CockroachDB"
    "InfluxDB (time-series)"
    "MinIO (object storage S3-compatible)"
)
select_menu "BASES DE DADOS" "${databases[@]}"
SEL_DATABASES=("${MENU_RESULT[@]}")

for idx in "${SEL_DATABASES[@]}"; do
    case $idx in
        0) INSTALL_POSTGRES=true ;;
        1) INSTALL_MYSQL=true ;;
        2) INSTALL_REDIS_SERVER=true ;;
        3) INSTALL_MONGODB=true ;;
        4) INSTALL_SQLITE_TOOLS=true ;;
        5) INSTALL_ELASTICSEARCH=true ;;
        6) INSTALL_CASSANDRA=true ;;
        7) INSTALL_COCKROACHDB=true ;;
        8) INSTALL_INFLUXDB=true ;;
        9) INSTALL_MINIO=true ;;
    esac
done

# ═══════════════════════════════════════════════════════════════
# BLOCO 7: TERMINAL & CLI TOOLS
# ═══════════════════════════════════════════════════════════════
section "7/9 — TERMINAL & CLI TOOLS"

terminal_tools=(
    "btop — monitor de recursos (TUI bonito)"
    "lazygit — git TUI"
    "lazydocker — docker TUI (se não escolhido antes)"
    "yazi — file manager TUI moderno"
    "lf — file manager TUI leve"
    "ranger — file manager TUI Python"
    "nnn — file manager TUI minimalista"
    "zoxide — cd inteligente (aprende paths usados)"
    "fzf — fuzzy finder"
    "ripgrep (rg) — grep super rápido"
    "fd — find moderno"
    "eza — ls moderno (suporte icons)"
    "bat — cat com syntax highlighting"
    "delta — diff com syntax highlighting"
    "dust — du visual"
    "duf — df visual"
    "bottom (btm) — alternativa ao btop"
    "htop — monitor clássico"
    "ncdu — analisador de disco TUI"
    "tmux-sessionizer (script de sessões)"
    "atuin — histórico de shell com sync"
    "mcfly — histórico inteligente"
    "thefuck — corrige o último comando"
    "tldr — man pages resumidas"
    "cheat — cheatsheets no terminal"
    "glow — markdown no terminal"
    "superfile — file manager TUI moderno (Go)"
    "yq — yaml processor (como jq)"
    "jq — json processor"
    "xh — curl alternativo moderno"
    "httpie (CLI) — HTTP para humanos"
    "nmap — scanner de rede"
    "iperf3 — teste de largura de banda"
    "mtr — traceroute avançado"
    "netcat (nc) — utilidade de rede"
    "sshpass — automatizar SSH com password"
    "rsync — sincronização de ficheiros"
    "rclone — sync com cloud (drive, s3...)"
    "restic — backups incrementais encriptados"
    "timeshift — snapshots do sistema"
    "Starship prompt (alternativa ao p10k)"
    "oh-my-posh — prompt customizável cross-shell"
    "neofetch — info do sistema"
    "fastfetch — neofetch mais rápido"
    "lolcat — output colorido"
    "figlet / toilet — banners no terminal"
    "asciinema — gravação de sessões terminal"
    "terminalizer — gravação animada"
)
select_menu "TERMINAL & CLI TOOLS" "${terminal_tools[@]}"
SEL_TERMINAL=("${MENU_RESULT[@]}")

# ═══════════════════════════════════════════════════════════════
# BLOCO 8: MULTIMEDIA & DESIGN
# ═══════════════════════════════════════════════════════════════
section "8/9 — MULTIMEDIA & DESIGN"

multimedia=(
    "VLC — player de media universal"
    "mpv — player minimalista e leve"
    "Spotify (cliente oficial)"
    "Spotube (cliente Spotify open-source)"
    "Spicetify (personalizar Spotify)"
    "Rhythmbox — player de música"
    "Cmus — player de música TUI"
    "ncmpcpp + mpd — player de música TUI avançado"
    "OBS Studio — gravação e streaming"
    "Kdenlive — editor de vídeo"
    "DaVinci Resolve (requer download manual)"
    "Shotcut — editor de vídeo simples"
    "HandBrake — conversor de vídeo"
    "FFmpeg — processamento de vídeo/áudio CLI"
    "GIMP — editor de imagem"
    "Pinta — editor de imagem simples"
    "Inkscape — editor vectorial"
    "Krita — pintura digital"
    "Blender — modelação 3D"
    "Darktable — edição de fotos RAW"
    "RawTherapee — edição de fotos RAW alternativa"
    "Flameshot — screenshot tool avançada"
    "Upscayl — upscaling de imagens (AI)"
    "Audacity — editor de áudio"
    "Ardour — DAW profissional"
    "LMMS — DAW grátis"
    "Cava — visualizador de audio (terminal)"
    "Freetube — cliente YouTube privado"
    "Celluloid — frontend do mpv (GTK)"
    "Stremio — streaming media"
)
select_menu "MULTIMEDIA & DESIGN" "${multimedia[@]}"
SEL_MULTIMEDIA=("${MENU_RESULT[@]}")

# ═══════════════════════════════════════════════════════════════
# BLOCO 9: APPS GERAIS
# ═══════════════════════════════════════════════════════════════
section "9/9 — APPS GERAIS"

# -- Comunicação --
echo -e "  ${BOLD}Comunicação:${NC}"
communication=(
    "Discord"
    "Slack"
    "Telegram Desktop"
    "Signal Desktop"
    "Zoom"
    "Microsoft Teams (AppImage)"
    "Element (Matrix client)"
    "Mattermost Desktop"
    "Skype"
    "Thunderbird (email)"
    "Geary (email leve)"
    "Betterbird (fork Thunderbird)"
    "Evolution (email + calendário)"
    "Whatsapp (unofficial, nativefier)"
)
select_menu "COMUNICAÇÃO" "${communication[@]}"
SEL_COMMUNICATION=("${MENU_RESULT[@]}")

# -- Produtividade --
echo -e "  ${BOLD}Produtividade:${NC}"
productivity=(
    "Obsidian — notas em markdown"
    "Notion Desktop (AppImage unofficial)"
    "Logseq — notas/PKM open-source"
    "Joplin — notas com sync"
    "Zettlr — markdown focado em academic"
    "LibreOffice — suite office completa"
    "OnlyOffice — suite office compatível Microsoft"
    "Calibre — gestor de ebooks"
    "Okular — viewer de PDFs"
    "Evince — viewer de PDFs leve"
    "Zathura — viewer de PDFs minimalista"
    "Nextcloud Desktop — sync cloud"
    "Dropbox"
    "Mega Sync"
    "FileZilla — FTP client"
    "PeaZip — arquivo/compressão"
    "Flatseal — gestor de permissões Flatpak"
    "Gnome Disk Utility"
    "GParted — particionamento"
    "Timeshift — backups sistema"
    "ProtonVPN"
    "Mullvad VPN"
    "qBittorrent — torrent client"
    "Transmission — torrent leve"
    "Deluge — torrent com plugins"
    "Bitwarden Desktop — gestor de passwords"
    "KeePassXC — gestor de passwords local"
    "Seahorse — gestor de chaves GnuPG"
)
select_menu "PRODUTIVIDADE" "${productivity[@]}"
SEL_PRODUCTIVITY=("${MENU_RESULT[@]}")

# -- Gaming --
echo -e "  ${BOLD}Gaming:${NC}"
gaming=(
    "Steam"
    "Lutris — launcher de jogos (Wine, emuladores)"
    "Heroic Games Launcher (Epic + GOG)"
    "Bottles — Wine/Proton manager"
    "GameMode — optimizações de performance"
    "MangoHud — overlay de performance"
    "ProtonUp-Qt — gestor de versões Proton"
    "RetroArch — emulador universal"
    "PCSX2 — emulador PS2"
    "RPCS3 — emulador PS3"
    "Yuzu / Ryujinx — emuladores Switch"
    "Cemu — emulador Wii U"
)
select_menu "GAMING" "${gaming[@]}"
SEL_GAMING=("${MENU_RESULT[@]}")

# ═══════════════════════════════════════════════════════════════
# HARDWARE & EXTRAS
# ═══════════════════════════════════════════════════════════════
section "HARDWARE & EXTRAS"

echo ""
if ask_yn "Estás numa máquina ASUS ROG/TUF? (instala asusctl + supergfxctl)" n; then
    INSTALL_ASUS=true
fi

echo ""
if ask_yn "Tens GPU NVIDIA? (instala drivers nvidia-driver)" n; then
    INSTALL_NVIDIA=true
fi

echo ""
if ask_yn "Queres suporte a Bluetooth? (bluez + blueman)" y; then
    INSTALL_BLUETOOTH=true
fi

echo ""
echo -e "  ${BOLD}Fontes Nerd Font a instalar:${NC}"
fonts=(
    "JetBrainsMono Nerd Font (Recomendado)"
    "FiraCode Nerd Font"
    "Hack Nerd Font"
    "CascadiaCode (Caskaydia) Nerd Font"
    "UbuntuMono Nerd Font"
    "Iosevka Nerd Font"
    "Meslo Nerd Font"
    "FantasqueSansMono Nerd Font"
    "Noto Fonts (emojis + CJK)"
    "Inter (UI font)"
    "Roboto"
    "Source Han Sans (CJK)"
)
select_menu "FONTES" "${fonts[@]}"
SEL_FONTS=("${MENU_RESULT[@]}")

echo ""
echo -e "  ${BOLD}Temas e aparência:${NC}"
themes=(
    "Bibata cursor (recomendado para Hyprland)"
    "Papirus icon theme"
    "Gruvbox GTK theme (gruvbox-material-gtk)"
    "Catppuccin GTK theme"
    "adw-gtk3 (imitar Adwaita no GTK3)"
    "Kvantum (temas Qt)"
    "Orchis GTK theme"
    "WhiteSur GTK theme (estilo macOS)"
)
select_menu "TEMAS" "${themes[@]}"
SEL_THEMES=("${MENU_RESULT[@]}")

# ═══════════════════════════════════════════════════════════════
# DOTFILES
# ═══════════════════════════════════════════════════════════════
section "DOTFILES & ESTRUTURA"

echo ""
if ask_yn "Clonar dotfiles de um repositório git?" y; then
    INSTALL_DOTFILES=true
    DOTFILES_REPO=$(ask_input "URL do repo" "https://github.com/VascoRafaelAzevedo/dotfiles")
fi

echo ""
if ask_yn "Criar estrutura de pastas DEV? (~/Desktop/DEV/Versioned/... etc)" y; then
    INSTALL_DEV_FOLDERS=true
fi

echo ""
if ask_yn "Instalar Tabby Terminal?" n; then
    INSTALL_TABBY=true
fi

echo ""
if ask_yn "Instalar GitHub Copilot CLI? (gh extension)" y; then
    INSTALL_COPILOT_CLI=true
fi

fi # end if RESUME == false

# ═══════════════════════════════════════════════════════════════
# RESUMO ANTES DE INSTALAR
# ═══════════════════════════════════════════════════════════════
section "RESUMO — O QUE VAI SER INSTALADO"

echo -e "  ${BOLD}Core (sempre):${NC} zsh, nvim, tmux, kitty, git, curl, Oh My Zsh, Powerlevel10k"
[[ "$INSTALL_HYPRLAND" == true ]] && echo -e "  ${GREEN}✓${NC} Hyprland + ${#WM_EXTRAS_SEL[@]} extras"
echo -e "  ${GREEN}✓${NC} ${#SEL_BROWSERS[@]} browsers"
echo -e "  ${GREEN}✓${NC} ${#SEL_LANGUAGES[@]} linguagens/runtimes"
echo -e "  ${GREEN}✓${NC} ${#SEL_DEVOPS[@]} ferramentas devops/containers"
echo -e "  ${GREEN}✓${NC} ${#SEL_DEVTOOLS[@]} ferramentas de desenvolvimento"
echo -e "  ${GREEN}✓${NC} ${#SEL_DATABASES[@]} bases de dados"
echo -e "  ${GREEN}✓${NC} ${#SEL_TERMINAL[@]} terminal tools"
echo -e "  ${GREEN}✓${NC} ${#SEL_MULTIMEDIA[@]} apps multimedia"
echo -e "  ${GREEN}✓${NC} ${#SEL_COMMUNICATION[@]} apps comunicação"
echo -e "  ${GREEN}✓${NC} ${#SEL_PRODUCTIVITY[@]} apps produtividade"
echo -e "  ${GREEN}✓${NC} ${#SEL_GAMING[@]} jogos/emuladores"
echo -e "  ${GREEN}✓${NC} ${#SEL_FONTS[@]} fontes"
echo -e "  ${GREEN}✓${NC} ${#SEL_THEMES[@]} temas"
[[ "$INSTALL_ASUS" == true ]] && echo -e "  ${GREEN}✓${NC} ASUS tools"
[[ "$INSTALL_NVIDIA" == true ]] && echo -e "  ${GREEN}✓${NC} NVIDIA drivers"
[[ "$INSTALL_BLUETOOTH" == true ]] && echo -e "  ${GREEN}✓${NC} Bluetooth"
[[ "$INSTALL_DOTFILES" == true ]] && echo -e "  ${GREEN}✓${NC} Dotfiles: $DOTFILES_REPO"
[[ "$INSTALL_DEV_FOLDERS" == true ]] && echo -e "  ${GREEN}✓${NC} Estrutura DEV"
echo ""

if ! ask_yn "Confirmas e inicias a instalação?" y; then
    echo -e "\n  ${YELLOW}Instalação cancelada.${NC}\n"
    exit 0
fi

# Guardar estado da sessão para --resume
{
    echo "INSTALL_HYPRLAND=$INSTALL_HYPRLAND"
    echo "INSTALL_WM_EXTRAS=$INSTALL_WM_EXTRAS"
    echo "INSTALL_DOTFILES=$INSTALL_DOTFILES"
    echo "DOTFILES_REPO='$DOTFILES_REPO'"
    echo "INSTALL_ASUS=$INSTALL_ASUS"
    echo "INSTALL_NVIDIA=$INSTALL_NVIDIA"
    echo "INSTALL_BLUETOOTH=$INSTALL_BLUETOOTH"
    echo "INSTALL_DEV_FOLDERS=$INSTALL_DEV_FOLDERS"
    echo "INSTALL_DOCKER=$INSTALL_DOCKER"
    echo "INSTALL_DOCKER_COMPOSE=$INSTALL_DOCKER_COMPOSE"
    echo "INSTALL_PORTAINER=$INSTALL_PORTAINER"
    echo "INSTALL_KUBECTL=$INSTALL_KUBECTL"
    echo "INSTALL_HELM=$INSTALL_HELM"
    echo "INSTALL_TERRAFORM=$INSTALL_TERRAFORM"
    echo "INSTALL_AWSCLI=$INSTALL_AWSCLI"
    echo "INSTALL_ANSIBLE=$INSTALL_ANSIBLE"
    echo "INSTALL_NVM=$INSTALL_NVM"
    echo "INSTALL_GO=$INSTALL_GO"
    echo "INSTALL_RUST=$INSTALL_RUST"
    echo "INSTALL_PYTHON_EXTRAS=$INSTALL_PYTHON_EXTRAS"
    echo "INSTALL_PHP=$INSTALL_PHP"
    echo "INSTALL_RUBY=$INSTALL_RUBY"
    echo "INSTALL_JAVA=$INSTALL_JAVA"
    echo "INSTALL_FLUTTER=$INSTALL_FLUTTER"
    echo "INSTALL_DOTNET=$INSTALL_DOTNET"
    echo "WM_EXTRAS_SEL=(${WM_EXTRAS_SEL[*]:-})"
    echo "SEL_BROWSERS=(${SEL_BROWSERS[*]:-})"
    echo "SEL_LANGUAGES=(${SEL_LANGUAGES[*]:-})"
    echo "SEL_DEVOPS=(${SEL_DEVOPS[*]:-})"
    echo "SEL_DEVTOOLS=(${SEL_DEVTOOLS[*]:-})"
    echo "SEL_DATABASES=(${SEL_DATABASES[*]:-})"
    echo "SEL_TERMINAL=(${SEL_TERMINAL[*]:-})"
    echo "SEL_MULTIMEDIA=(${SEL_MULTIMEDIA[*]:-})"
    echo "SEL_COMMUNICATION=(${SEL_COMMUNICATION[*]:-})"
    echo "SEL_PRODUCTIVITY=(${SEL_PRODUCTIVITY[*]:-})"
    echo "SEL_GAMING=(${SEL_GAMING[*]:-})"
    echo "SEL_FONTS=(${SEL_FONTS[*]:-})"
    echo "SEL_THEMES=(${SEL_THEMES[*]:-})"
} > "$STATE_FILE"
info "Estado guardado em $STATE_FILE (usa --resume para retomar)"

# ═══════════════════════════════════════════════════════════════
# ─────────────────── INSTALAÇÃO ────────────────────────────
# ═══════════════════════════════════════════════════════════════

[[ "$DRY_RUN" == true ]] && warn "MODO DRY-RUN: nenhum pacote será instalado"

apt_install() {
    if [[ "$DRY_RUN" == true ]]; then
        for pkg in "$@"; do
            pkg_installed "$pkg" && info "[dry-run] Já instalado: $pkg" || echo -e "  ${DIM}[dry-run] apt install: $pkg${NC}"
        done
        return 0
    fi
    for pkg in "$@"; do
        if ! pkg_installed "$pkg"; then
            step "apt: $pkg"
            sudo apt-get install -y "$pkg" 2>/dev/null || warn "Falhou: $pkg"
        else
            info "Já instalado: $pkg"
        fi
    done
}

add_apt_repo() {
    local name="$1"; local keyurl="$2"; local keypath="$3"; local repostr="$4"; local listfile="$5"
    if [[ "$DRY_RUN" == true ]]; then
        [[ -f "$listfile" ]] || echo -e "  ${DIM}[dry-run] Adicionar repo: $name${NC}"
        return 0
    fi
    if [ ! -f "$listfile" ]; then
        step "Repo: $name"
        if [[ "$keyurl" == gpg:* ]]; then
            curl -fsSL "${keyurl#gpg:}" | gpg --dearmor | sudo tee "$keypath" > /dev/null
        else
            sudo curl -fsSLo "$keypath" "$keyurl"
        fi
        echo "$repostr" | sudo tee "$listfile" > /dev/null
        info "$name repo adicionado"
    fi
}

BUILD="$HOME/.setup-build"
mkdir -p "$BUILD"
NERD_VER="v3.3.0"

# ── FASE 0: Update & build tools ──────────────────────────
section "A — Base do sistema"
if [[ "$DRY_RUN" == false ]]; then
    sudo apt-get update -qq
    sudo apt-get upgrade -y -qq
fi
apt_install \
    build-essential cmake meson ninja-build pkg-config \
    git curl wget unzip tar zip \
    libssl-dev libffi-dev python3-dev \
    libwayland-dev wayland-protocols \
    libxkbcommon-dev libxkbcommon-x11-dev \
    libpangocairo-1.0-0 libpango1.0-dev \
    libcairo2-dev libgdk-pixbuf-2.0-dev \
    libglib2.0-dev libgtk-3-dev \
    libsystemd-dev libudev-dev libinput-dev \
    libdrm-dev libgbm-dev libdbus-1-dev \
    libpipewire-0.3-dev libspa-0.2-dev \
    libjson-glib-dev libfmt-dev libspdlog-dev \
    jq bc xdotool ca-certificates gnupg lsb-release \
    xdg-utils xdg-user-dirs

# ── FASE 1: Core sempre instalado ─────────────────────────
section "B — Core tools (obrigatório)"
apt_install zsh git curl wget

# Kitty
if ! has kitty; then
    step "Kitty terminal"
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty 2>/dev/null || true
    sudo ln -sf "$HOME/.local/kitty.app/bin/kitten" /usr/local/bin/kitten 2>/dev/null || true
    # Fallback ao apt
    pkg_installed kitty || apt_install kitty
fi

# Neovim
if ! has nvim; then
    step "Neovim (AppImage)"
    apt_install libfuse2 2>/dev/null || true   # required for AppImage on Debian
    wget -q "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage" -O /tmp/nvim.appimage
    chmod +x /tmp/nvim.appimage
    sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
fi

# Tmux
apt_install tmux
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    step "TPM (Tmux Plugin Manager)"
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Zsh + Oh My Zsh + Powerlevel10k
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s "$(which zsh)" "$USER"
fi
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    step "Oh My Zsh"
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$OMZ_CUSTOM/themes/powerlevel10k" ]; then
    step "Powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$OMZ_CUSTOM/themes/powerlevel10k"
fi
[ ! -d "$OMZ_CUSTOM/plugins/zsh-autosuggestions" ] && \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$OMZ_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
info "Core tools instalados"

# ── FASE 2: Hyprland ──────────────────────────────────────
if [[ "$INSTALL_HYPRLAND" == true ]]; then
    section "C — Hyprland ecosystem"

    # Dependências apt do WM
    apt_install \
        pipewire wireplumber pipewire-pulse pipewire-alsa \
        xdg-desktop-portal-gtk \
        libnotify-bin dunst \
        brightnessctl acpi upower \
        polkit-kde-agent-1

    # WM extras baseado na selecção
    for idx in "${WM_EXTRAS_SEL[@]}"; do
        case $idx in
            0) apt_install waybar ;;
            1) # rofi-wayland from source
               if ! has rofi; then
                   cd "$BUILD"
                   git clone --depth=1 https://github.com/lbonn/rofi.git rofi-src 2>/dev/null || true
                   [ -d "rofi-src" ] && cd rofi-src && \
                       meson setup build --prefix=/usr/local -Dwayland=enabled -Dxcb=disabled && \
                       ninja -C build && sudo ninja -C build install
               fi ;;
            2) apt_install wlogout ;;
            3) # swww
               if ! has swww; then
                   cd "$BUILD"
                   SWWW_VER=$(curl -s https://api.github.com/repos/LGFae/swww/releases/latest | jq -r '.tag_name')
                   wget -q "https://github.com/LGFae/swww/releases/download/${SWWW_VER}/swww-x86_64-unknown-linux-musl.tar.gz"
                   tar -xzf swww-*.tar.gz && sudo cp swww swww-daemon /usr/local/bin/ 2>/dev/null || true
               fi ;;
            4) # hyprlock
               if ! has hyprlock; then
                   cd "$BUILD" && git clone --depth=1 https://github.com/hyprwm/hyprlock.git 2>/dev/null || true
                   [ -d "hyprlock" ] && cd hyprlock && \
                       cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE=Release -S . -B build && \
                       cmake --build build -j"$(nproc)" && sudo cmake --install build
               fi ;;
            5) # hypridle
               if ! has hypridle; then
                   cd "$BUILD" && git clone --depth=1 https://github.com/hyprwm/hypridle.git 2>/dev/null || true
                   [ -d "hypridle" ] && cd hypridle && \
                       cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE=Release -S . -B build && \
                       cmake --build build -j"$(nproc)" && sudo cmake --install build
               fi ;;
            6) # cliphist
               if ! has cliphist && has go; then
                   go install go.senan.xyz/cliphist@latest
                   sudo cp "$HOME/go/bin/cliphist" /usr/local/bin/ 2>/dev/null || true
               fi ;;
            7) apt_install swappy ;;
            8) apt_install grim slurp ;;
            9) apt_install nwg-displays ;;
            10) apt_install nwg-look ;;
            11) apt_install wl-clipboard ;;
            12) apt_install playerctl ;;
            13) apt_install polkit-kde-agent-1 ;;
            14) apt_install blueman ;;
            15) apt_install network-manager-gnome ;;
            16) # wallust
               if ! has wallust; then
                   if has cargo; then
                       cargo install wallust
                   else
                       warn "wallust requer Rust/cargo. Instala Rust primeiro."
                   fi
               fi ;;
            17) # pywal
               pip3 install pywal --user 2>/dev/null || warn "pywal falhou" ;;
        esac
    done

    # Hyprland em si (via JaKooLit)
    if ! has hyprland; then
        step "Hyprland (via JaKooLit Debian-Hyprland)"
        cd "$BUILD"
        git clone --depth=1 https://github.com/JaKooLit/Debian-Hyprland.git 2>/dev/null || true
        if [ -d "Debian-Hyprland" ]; then
            cd Debian-Hyprland && chmod +x install.sh
            bash install.sh || warn "JaKooLit script terminou com erro. Verifica manualmente."
        fi
    fi
fi

# ── FASE 3: Repositórios externos ─────────────────────────
section "D — Repositórios externos"

# Brave
if in_array 1 "${SEL_BROWSERS[@]}"; then
    add_apt_repo "Brave" \
        "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" \
        "/usr/share/keyrings/brave-browser-archive-keyring.gpg" \
        "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" \
        "/etc/apt/sources.list.d/brave-browser.list"
fi

# VSCode
if [[ "${INSTALL_VSCODE:-false}" == true ]]; then
    add_apt_repo "VSCode" \
        "gpg:https://packages.microsoft.com/keys/microsoft.asc" \
        "/usr/share/keyrings/microsoft.gpg" \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        "/etc/apt/sources.list.d/vscode.list"
fi

# GitHub CLI
if [[ "${INSTALL_GH_CLI:-false}" == true ]]; then
    add_apt_repo "GitHub CLI" \
        "gpg:https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
        "/usr/share/keyrings/githubcli-archive-keyring.gpg" \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        "/etc/apt/sources.list.d/github-cli.list"
fi

# GitHub Desktop
if [[ "${INSTALL_GITHUB_DESKTOP:-false}" == true ]]; then
    add_apt_repo "GitHub Desktop" \
        "gpg:https://apt.packages.shiftkey.dev/gpg.key" \
        "/usr/share/keyrings/shiftkey-packages.gpg" \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main" \
        "/etc/apt/sources.list.d/shiftkey-packages.list"
fi

# Spotify
INSTALL_SPOTIFY=false
in_array 2 "${SEL_MULTIMEDIA[@]}" && INSTALL_SPOTIFY=true
if [[ "$INSTALL_SPOTIFY" == true ]]; then
    add_apt_repo "Spotify" \
        "gpg:https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg" \
        "/usr/share/keyrings/spotify.gpg" \
        "deb [signed-by=/usr/share/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" \
        "/etc/apt/sources.list.d/spotify.list"
fi

# Tabby
if [[ "${INSTALL_TABBY:-false}" == true ]]; then
    add_apt_repo "Tabby" \
        "gpg:https://packagecloud.io/Eugeny/tabby/gpgkey" \
        "/usr/share/keyrings/tabby.gpg" \
        "deb [signed-by=/usr/share/keyrings/tabby.gpg] https://packagecloud.io/Eugeny/tabby/debian/ any main" \
        "/etc/apt/sources.list.d/tabby.list"
fi

# MongoDB
if [[ "${INSTALL_MONGODB:-false}" == true ]]; then
    add_apt_repo "MongoDB" \
        "gpg:https://www.mongodb.org/static/pgp/server-7.0.asc" \
        "/usr/share/keyrings/mongodb-server-7.0.gpg" \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/7.0 main" \
        "/etc/apt/sources.list.d/mongodb-org-7.0.list"
fi

# Docker
if [[ "$INSTALL_DOCKER" == true ]]; then
    add_apt_repo "Docker" \
        "gpg:https://download.docker.com/linux/debian/gpg" \
        "/usr/share/keyrings/docker.gpg" \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        "/etc/apt/sources.list.d/docker.list"
fi

sudo apt-get update -qq

# ── FASE 4: APT packages opcionais ────────────────────────
section "E — Pacotes apt opcionais"

# Browsers
for idx in "${SEL_BROWSERS[@]}"; do
    case $idx in
        0) apt_install firefox ;;
        1) apt_install brave-browser ;;
        2) apt_install chromium ;;
        3) # Google Chrome .deb
           if ! pkg_installed google-chrome-stable; then
               wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
               sudo dpkg -i /tmp/chrome.deb || sudo apt-get -f install -y
           fi ;;
        4) # LibreWolf
           if ! has librewolf; then
               add_apt_repo "LibreWolf" \
                   "gpg:https://deb.librewolf.net/keyring.gpg" \
                   "/usr/share/keyrings/librewolf.gpg" \
                   "deb [arch=amd64 signed-by=/usr/share/keyrings/librewolf.gpg] https://deb.librewolf.net $(lsb_release -cs) main" \
                   "/etc/apt/sources.list.d/librewolf.list"
               sudo apt-get update -qq && apt_install librewolf
           fi ;;
        5) # Tor Browser
           if ! has torbrowser-launcher; then
               apt_install torbrowser-launcher
           fi ;;
        6) # Vivaldi
           if ! has vivaldi-stable; then
               wget -qO /tmp/vivaldi.gpg https://repo.vivaldi.com/archive/linux_signing_key.pub
               sudo gpg --dearmor -o /usr/share/keyrings/vivaldi-browser.gpg /tmp/vivaldi.gpg
               echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vivaldi-browser.gpg] https://repo.vivaldi.com/archive/deb/ stable main" \
                   | sudo tee /etc/apt/sources.list.d/vivaldi.list > /dev/null
               sudo apt-get update -qq && apt_install vivaldi-stable
           fi ;;
        7) # Opera
           if ! has opera; then
               wget -qO /tmp/opera.gpg https://deb.opera.com/archive.key
               sudo gpg --dearmor -o /usr/share/keyrings/opera-browser.gpg /tmp/opera.gpg
               echo "deb [arch=amd64 signed-by=/usr/share/keyrings/opera-browser.gpg] https://deb.opera.com/opera-stable/ stable non-free" \
                   | sudo tee /etc/apt/sources.list.d/opera.list > /dev/null
               sudo apt-get update -qq && apt_install opera-stable
           fi ;;
    esac
done

# Dev tools apt
[[ "${INSTALL_VSCODE:-false}" == true ]] && apt_install code
[[ "${INSTALL_GITHUB_DESKTOP:-false}" == true ]] && apt_install github-desktop
[[ "${INSTALL_GH_CLI:-false}" == true ]] && apt_install gh
[[ "${INSTALL_TABBY:-false}" == true ]] && apt_install tabby-terminal
[[ "${INSTALL_MELD:-false}" == true ]] && apt_install meld
[[ "${INSTALL_WIRESHARK:-false}" == true ]] && apt_install wireshark
[[ "${INSTALL_DIFFUSE:-false}" == true ]] && apt_install diffuse
[[ "${INSTALL_HTTPIE:-false}" == true ]] && apt_install httpie
[[ "${INSTALL_MITMPROXY:-false}" == true ]] && apt_install mitmproxy

# Databases apt
[[ "${INSTALL_POSTGRES:-false}" == true ]] && apt_install postgresql postgresql-client
[[ "${INSTALL_MYSQL:-false}" == true ]] && apt_install mariadb-server mariadb-client
[[ "${INSTALL_REDIS_SERVER:-false}" == true ]] && apt_install redis-server
[[ "${INSTALL_MONGODB:-false}" == true ]] && apt_install mongodb-org
[[ "${INSTALL_SQLITE_TOOLS:-false}" == true ]] && apt_install sqlite3 sqlitebrowser

# Elasticsearch
if [[ "${INSTALL_ELASTICSEARCH:-false}" == true ]] && ! has elasticsearch; then
    step "Elasticsearch"
    wget -qO /tmp/elasticsearch.gpg https://artifacts.elastic.co/GPG-KEY-elasticsearch
    sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch.gpg /tmp/elasticsearch.gpg
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" \
        | sudo tee /etc/apt/sources.list.d/elastic-8.x.list > /dev/null
    sudo apt-get update -qq && apt_install elasticsearch
    sudo systemctl enable elasticsearch
fi

# Cassandra
if [[ "${INSTALL_CASSANDRA:-false}" == true ]] && ! has cassandra; then
    step "Apache Cassandra"
    wget -qO /tmp/cassandra.gpg https://downloads.apache.org/cassandra/KEYS
    sudo gpg --dearmor -o /usr/share/keyrings/cassandra.gpg /tmp/cassandra.gpg
    echo "deb [signed-by=/usr/share/keyrings/cassandra.gpg] https://debian.cassandra.apache.org 41x main" \
        | sudo tee /etc/apt/sources.list.d/cassandra.list > /dev/null
    sudo apt-get update -qq && apt_install cassandra
fi

# InfluxDB
if [[ "${INSTALL_INFLUXDB:-false}" == true ]] && ! has influxd; then
    step "InfluxDB"
    wget -qO /tmp/influxdb.gpg https://repos.influxdata.com/influxdata-archive_compat.key
    sudo gpg --dearmor -o /usr/share/keyrings/influxdb.gpg /tmp/influxdb.gpg
    echo "deb [signed-by=/usr/share/keyrings/influxdb.gpg] https://repos.influxdata.com/debian stable main" \
        | sudo tee /etc/apt/sources.list.d/influxdb.list > /dev/null
    sudo apt-get update -qq && apt_install influxdb2
fi

# MinIO (S3-compatible object storage)
if [[ "${INSTALL_MINIO:-false}" == true ]] && ! has minio; then
    step "MinIO"
    wget -q https://dl.min.io/server/minio/release/linux-amd64/minio -O /tmp/minio
    chmod +x /tmp/minio && sudo mv /tmp/minio /usr/local/bin/minio
    wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
    chmod +x /tmp/mc && sudo mv /tmp/mc /usr/local/bin/mc
fi

# CockroachDB
if [[ "${INSTALL_COCKROACHDB:-false}" == true ]] && ! has cockroach; then
    step "CockroachDB"
    CRDB_VER=$(curl -s https://api.github.com/repos/cockroachdb/cockroach/releases/latest | jq -r '.tag_name')
    wget -q "https://binaries.cockroachdb.com/cockroach-${CRDB_VER}.linux-amd64.tgz" -O /tmp/cockroach.tgz
    tar -xzf /tmp/cockroach.tgz -C /tmp/
    sudo cp "/tmp/cockroach-${CRDB_VER}.linux-amd64/cockroach" /usr/local/bin/
    rm -rf /tmp/cockroach.tgz "/tmp/cockroach-${CRDB_VER}.linux-amd64"
fi

# Docker (with compose plugin — INSTALL_DOCKER_COMPOSE is bundled as docker-compose-plugin)
if [[ "$INSTALL_DOCKER" == true ]]; then
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    sudo systemctl enable docker
    info "Docker instalado. Re-login necessário para usar sem sudo."
elif [[ "${INSTALL_DOCKER_COMPOSE:-false}" == true ]]; then
    # Compose standalone sem Docker engine (raro, mas suportado)
    step "Docker Compose standalone"
    COMPOSE_VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-linux-x86_64" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Multimedia apt
for idx in "${SEL_MULTIMEDIA[@]}"; do
    case $idx in
        0) apt_install vlc ;;
        1) apt_install mpv ;;
        2) apt_install spotify-client ;;
        3) # Spotube
           if ! has spotube; then
               SPT_VER=$(curl -s https://api.github.com/repos/KRTirtho/spotube/releases/latest | jq -r '.tag_name' | tr -d 'v')
               wget -q "https://github.com/KRTirtho/spotube/releases/download/v${SPT_VER}/Spotube-linux-x86_64.deb" -O /tmp/spotube.deb
               sudo dpkg -i /tmp/spotube.deb || sudo apt-get -f install -y
           fi ;;
        5) apt_install rhythmbox ;;
        6) apt_install cmus ;;
        7) apt_install ncmpcpp mpd ;;
        8) apt_install obs-studio ;;
        9) apt_install kdenlive ;;
        10) warn "DaVinci Resolve: download manual em https://www.blackmagicdesign.com/products/davinciresolve" ;;
        11) apt_install shotcut ;;
        12) apt_install handbrake ;;
        13) apt_install ffmpeg ;;
        14) apt_install gimp ;;
        15) apt_install pinta ;;
        16) apt_install inkscape ;;
        17) apt_install krita ;;
        18) apt_install blender ;;
        19) apt_install darktable ;;
        20) apt_install rawtherapee ;;
        22) # Upscayl (AppImage)
            if ! has upscayl; then
                UPSC_VER=$(curl -s https://api.github.com/repos/upscayl/upscayl/releases/latest | jq -r '.tag_name' | tr -d 'v')
                wget -q "https://github.com/upscayl/upscayl/releases/download/v${UPSC_VER}/upscayl-${UPSC_VER}-linux.AppImage" -O "$HOME/.local/bin/upscayl"
                chmod +x "$HOME/.local/bin/upscayl"
            fi ;;
        23) apt_install audacity ;;
        24) apt_install ardour ;;
        25) apt_install lmms ;;
        26) apt_install cava ;;
        27) # Freetube
            if ! has freetube; then
                FT_VER=$(curl -s https://api.github.com/repos/FreeTubeApp/FreeTube/releases/latest | jq -r '.tag_name' | tr -d 'v')
                wget -q "https://github.com/FreeTubeApp/FreeTube/releases/download/v${FT_VER}/freetube_${FT_VER}_amd64.deb" -O /tmp/freetube.deb
                sudo dpkg -i /tmp/freetube.deb || sudo apt-get -f install -y
            fi ;;
        28) apt_install celluloid ;;
        29) # Stremio
            if ! has stremio; then
                wget -q "https://www.stremio.com/download/linux/latest" -O /tmp/stremio.deb 2>/dev/null || \
                    warn "Stremio: download manual em https://www.stremio.com/downloads"
                [ -f /tmp/stremio.deb ] && { sudo dpkg -i /tmp/stremio.deb || sudo apt-get -f install -y; }
            fi ;;
    esac
done

# Comunicação apt
for idx in "${SEL_COMMUNICATION[@]}"; do
    case $idx in
        0) apt_install discord || true
           if ! pkg_installed discord; then
               wget -q "https://discord.com/api/download?platform=linux&format=deb" -O /tmp/discord.deb
               sudo dpkg -i /tmp/discord.deb || sudo apt-get -f install -y
           fi ;;
        1) apt_install slack-desktop || true ;;
        2) apt_install telegram-desktop ;;
        3) # Signal
           add_apt_repo "Signal" \
               "gpg:https://updates.signal.org/desktop/apt/keys.asc" \
               "/usr/share/keyrings/signal-desktop-keyring.gpg" \
               "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" \
               "/etc/apt/sources.list.d/signal-xenial.list"
           sudo apt-get update -qq && apt_install signal-desktop ;;
        9) apt_install thunderbird ;;
        10) apt_install geary ;;
        12) apt_install evolution ;;
    esac
done

# Produtividade apt
for idx in "${SEL_PRODUCTIVITY[@]}"; do
    case $idx in
        5) apt_install libreoffice ;;
        6) # OnlyOffice
           if ! has onlyoffice-desktopeditors; then
               wget -q "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb" -O /tmp/onlyoffice.deb
               sudo dpkg -i /tmp/onlyoffice.deb || sudo apt-get -f install -y
           fi ;;
        7) apt_install calibre ;;
        8) apt_install okular ;;
        9) apt_install evince ;;
        10) apt_install zathura ;;
        11) apt_install nextcloud-desktop ;;
        14) apt_install filezilla ;;
        15) apt_install peazip 2>/dev/null || apt_install p7zip-full p7zip-rar ;;
        16) apt_install flatpak 2>/dev/null; warn "Flatseal: instala via Flatpak: flatpak install flathub com.github.tchx84.Flatseal" ;;
        17) apt_install gnome-disk-utility ;;
        18) apt_install gparted ;;
        19) apt_install timeshift ;;
        20) # ProtonVPN
            if ! has protonvpn; then
                wget -q "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.4_all.deb" -O /tmp/protonvpn.deb
                sudo dpkg -i /tmp/protonvpn.deb && sudo apt-get update -qq && apt_install proton-vpn-gnome-desktop
            fi ;;
        21) # Mullvad VPN
            if ! has mullvad; then
                wget -q "https://mullvad.net/download/app/deb/latest" -O /tmp/mullvad.deb
                sudo dpkg -i /tmp/mullvad.deb || sudo apt-get -f install -y
            fi ;;
        22) apt_install qbittorrent ;;
        23) apt_install transmission ;;
        24) apt_install deluge ;;
        26) apt_install keepassxc ;;
        27) apt_install seahorse ;;
    esac
done

# Gaming apt
for idx in "${SEL_GAMING[@]}"; do
    case $idx in
        0) # Steam
           apt_install steam-installer || {
               wget -q "https://cdn.akamai.steamstatic.com/client/installer/steam.deb" -O /tmp/steam.deb
               sudo dpkg -i /tmp/steam.deb || sudo apt-get -f install -y
           } ;;
        1) apt_install lutris ;;
        4) apt_install gamemode ;;
        5) apt_install mangohud ;;
        7) apt_install retroarch ;;
    esac
done

# Terminal tools apt
for idx in "${SEL_TERMINAL[@]}"; do
    case $idx in
        0) apt_install btop ;;
        6) apt_install nnn ;;
        7) apt_install zoxide ;;
        8) apt_install fzf ;;
        9) apt_install ripgrep ;;
        10) apt_install fd-find ;;
        12) apt_install bat ;;
        16) apt_install bottom 2>/dev/null || true ;;   # bottom (btm)
        17) apt_install htop ;;
        18) apt_install ncdu ;;
        20) # atuin — use official installer (not in Debian apt)
            if ! has atuin; then
                curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | bash || warn "atuin: falhou installer"
            fi ;;
        22) apt_install thefuck ;;
        23) apt_install tldr ;;
        24) # cheat — binary download
            if ! has cheat; then
                wget -q "https://github.com/cheat/cheat/releases/latest/download/cheat-linux-amd64.gz" -O /tmp/cheat.gz
                gunzip /tmp/cheat.gz && sudo mv /tmp/cheat /usr/local/bin/cheat && sudo chmod +x /usr/local/bin/cheat
            fi ;;
        25) apt_install glow ;;
        27) apt_install yq ;;
        28) apt_install jq ;;
        29) # xh — curl alternative
            if ! has xh; then
                curl -sfL https://raw.githubusercontent.com/ducaale/xh/master/install.sh | sudo bash || \
                    { has cargo && cargo install xh; }
            fi ;;
        30) apt_install httpie ;;
        31) apt_install nmap ;;
        32) apt_install iperf3 ;;
        33) apt_install mtr ;;
        34) apt_install netcat-openbsd ;;
        35) apt_install sshpass ;;
        36) apt_install rsync ;;
        39) apt_install timeshift ;;
        42) apt_install neofetch ;;
        44) apt_install lolcat ;;
        45) apt_install figlet toilet ;;
        46) apt_install asciinema ;;
    esac
done

# Bluetooth
if [[ "$INSTALL_BLUETOOTH" == true ]]; then
    apt_install bluez bluetooth blueman
    sudo systemctl enable bluetooth
fi

# NVIDIA
if [[ "$INSTALL_NVIDIA" == true ]]; then
    step "NVIDIA drivers"
    sudo apt-get install -y nvidia-driver firmware-misc-nonfree || warn "NVIDIA: adiciona non-free ao sources.list se falhar"
fi

# ASUS
if [[ "$INSTALL_ASUS" == true ]]; then
    step "ASUS tools (asusctl + supergfxctl)"
    apt_install libdbus-1-dev libclang-dev
    if ! has asusctl; then
        cd "$BUILD"
        git clone --depth=1 https://gitlab.com/asus-linux/asusctl.git 2>/dev/null || true
        [ -d "asusctl" ] && cd asusctl && cargo build --release && sudo make install
    fi
fi

# ── FASE 5: Linguagens / runtimes ─────────────────────────
section "F — Linguagens & runtimes"

# NVM + Node
if [[ "$INSTALL_NVM" == true ]]; then
    if [ ! -d "$HOME/.nvm" ]; then
        step "NVM + Node.js v22"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        source "$NVM_DIR/nvm.sh"
        nvm install 22 && nvm alias default 22
    fi
fi

# Python extras
if [[ "$INSTALL_PYTHON_EXTRAS" == true ]]; then
    apt_install python3 python3-pip python3-venv python3-full pipx
    if ! has pyenv; then
        step "pyenv"
        curl https://pyenv.run | bash
    fi
    if ! has poetry; then
        step "poetry"
        curl -sSL https://install.python-poetry.org | python3 -
    fi
fi

# Go
if [[ "$INSTALL_GO" == true ]] && ! has go; then
    step "Go (latest stable)"
    GO_VER=$(curl -s https://go.dev/VERSION?m=text | head -1 | tr -d 'go')
    wget -q "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz
    echo 'export PATH="/usr/local/go/bin:$PATH"' | sudo tee /etc/profile.d/go.sh > /dev/null
fi

# Java
[[ "$INSTALL_JAVA" == true ]] && apt_install default-jdk

# Rust
if [[ "$INSTALL_RUST" == true ]] && ! has rustc; then
    step "Rust (rustup)"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    source "$HOME/.cargo/env"
fi

# PHP + Composer
if [[ "$INSTALL_PHP" == true ]]; then
    apt_install php php-cli php-common php-mbstring php-xml php-curl php-zip php-mysql php-pgsql
    if ! has composer; then
        step "Composer"
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
    fi
fi

# Ruby + rbenv
if [[ "$INSTALL_RUBY" == true ]]; then
    if ! has rbenv; then
        step "rbenv + ruby-build"
        curl -fsSL https://rbenv.github.io/rbenv-installer/bin/rbenv-installer | bash
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
        rbenv install 3.3.0 && rbenv global 3.3.0
    fi
fi

# .NET
if [[ "$INSTALL_DOTNET" == true ]]; then
    if ! has dotnet; then
        step ".NET SDK"
        DEBIAN_VER=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
        wget -q "https://packages.microsoft.com/config/debian/${DEBIAN_VER}/packages-microsoft-prod.deb" -O /tmp/ms-prod.deb
        sudo dpkg -i /tmp/ms-prod.deb
        sudo apt-get update -qq && apt_install dotnet-sdk-8.0
    fi
fi

# Flutter
if [[ "$INSTALL_FLUTTER" == true ]] && [ ! -d "$HOME/flutter" ]; then
    step "Flutter (stable)"
    git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
    export PATH="$HOME/flutter/bin:$PATH"
    flutter precache --quiet
fi

# Android SDK
if [[ "${INSTALL_ANDROID_SDK:-false}" == true ]] && [ ! -d "$HOME/Android/cmdline-tools" ]; then
    step "Android SDK"
    mkdir -p "$HOME/Android/cmdline-tools/latest"
    wget -q "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -O /tmp/cmdtools.zip
    unzip -q /tmp/cmdtools.zip -d /tmp/cmdtools-ex
    mv /tmp/cmdtools-ex/cmdline-tools/* "$HOME/Android/cmdline-tools/latest/"
    export ANDROID_HOME="$HOME/Android"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    yes | sdkmanager --licenses > /dev/null 2>&1 || true
    sdkmanager "platform-tools" "build-tools;35.0.0" "platforms;android-35" --quiet
fi

# Android Studio
if [[ "${INSTALL_ANDROID_STUDIO:-false}" == true ]] && [ ! -d "/usr/local/android-studio" ]; then
    step "Android Studio"
    wget -q "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.3.1.14/android-studio-2024.3.1.14-linux.tar.gz" -O /tmp/as.tar.gz
    sudo tar -xzf /tmp/as.tar.gz -C /usr/local/
    sudo ln -sf /usr/local/android-studio/bin/studio.sh /usr/local/bin/android-studio
    rm /tmp/as.tar.gz
fi

# Kotlin
if [[ "${INSTALL_KOTLIN:-false}" == true ]] && ! has kotlin; then
    step "Kotlin (sdk)"
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install kotlin
fi

# Lua
[[ "${INSTALL_LUA:-false}" == true ]] && apt_install lua5.4 luarocks

# Haskell
if [[ "${INSTALL_HASKELL:-false}" == true ]] && ! has ghc; then
    step "Haskell (GHCup)"
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh
fi

# Elixir
[[ "${INSTALL_ELIXIR:-false}" == true ]] && apt_install elixir erlang

# Zig
if [[ "${INSTALL_ZIG:-false}" == true ]] && ! has zig; then
    step "Zig"
    ZIG_VER=$(curl -s https://ziglang.org/download/index.json | jq -r '.master.version' 2>/dev/null || echo "0.13.0")
    wget -q "https://ziglang.org/download/${ZIG_VER}/zig-linux-x86_64-${ZIG_VER}.tar.xz" -O /tmp/zig.tar.xz
    sudo tar -xJf /tmp/zig.tar.xz -C /usr/local/
    sudo ln -sf "/usr/local/zig-linux-x86_64-${ZIG_VER}/zig" /usr/local/bin/zig
fi

# Bun
[[ "${INSTALL_BUN:-false}" == true ]] && ! has bun && curl -fsSL https://bun.sh/install | bash

# Deno
[[ "${INSTALL_DENO:-false}" == true ]] && ! has deno && curl -fsSL https://deno.land/install.sh | sh

# R
[[ "${INSTALL_R:-false}" == true ]] && apt_install r-base r-base-dev

# Julia
if [[ "${INSTALL_JULIA:-false}" == true ]] && ! has julia; then
    step "Julia (juliaup)"
    curl -fsSL https://install.julialang.org | sh -s -- --yes
    add_path 'export PATH="$HOME/.juliaup/bin:$PATH"'
fi

# Swift
if [[ "${INSTALL_SWIFT:-false}" == true ]] && ! has swift; then
    step "Swift (swiftly)"
    curl -fsSL https://swift.org/install/swiftly/swiftly-$(uname -m).tar.gz | tar -xz -C /tmp
    /tmp/swiftly init --quiet --no-modify-profile
    add_path 'export PATH="$HOME/.local/share/swiftly/bin:$PATH"'
fi

# WASM (WebAssembly tools)
if [[ "${INSTALL_WASM:-false}" == true ]]; then
    step "WASM tools (wabt + emscripten)"
    apt_install wabt
    if ! has emcc; then
        git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$HOME/emsdk" 2>/dev/null || \
            (cd "$HOME/emsdk" && git pull)
        cd "$HOME/emsdk"
        ./emsdk install latest && ./emsdk activate latest
        add_path 'source "$HOME/emsdk/emsdk_env.sh"'
        cd -
    fi
fi

# ── FASE 6: Devops/Containers ─────────────────────────────
section "G — DevOps & Containers"

# Portainer (Docker container)
if [[ "${INSTALL_PORTAINER:-false}" == true ]] && has docker; then
    step "Portainer CE"
    docker volume create portainer_data 2>/dev/null || true
    docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest 2>/dev/null || warn "Portainer: já existe ou Docker não está a correr"
fi

# Podman
[[ "${INSTALL_PODMAN:-false}" == true ]] && apt_install podman podman-compose

# kubectl
if [[ "${INSTALL_KUBECTL:-false}" == true ]] && ! has kubectl; then
    step "kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl && sudo mv kubectl /usr/local/bin/
fi

# Helm
if [[ "${INSTALL_HELM:-false}" == true ]] && ! has helm; then
    step "Helm"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# k9s
if [[ "${INSTALL_K9S:-false}" == true ]] && ! has k9s; then
    step "k9s"
    K9S_VER=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name')
    wget -q "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_linux_amd64.deb" -O /tmp/k9s.deb
    sudo dpkg -i /tmp/k9s.deb
fi

# Terraform
if [[ "${INSTALL_TERRAFORM:-false}" == true ]] && ! has terraform; then
    step "Terraform"
    add_apt_repo "HashiCorp" \
        "gpg:https://apt.releases.hashicorp.com/gpg" \
        "/usr/share/keyrings/hashicorp-archive-keyring.gpg" \
        "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        "/etc/apt/sources.list.d/hashicorp.list"
    sudo apt-get update -qq && apt_install terraform
fi

# Ansible
[[ "${INSTALL_ANSIBLE:-false}" == true ]] && pip3 install ansible --user

# AWS CLI
if [[ "${INSTALL_AWSCLI:-false}" == true ]] && ! has aws; then
    step "AWS CLI v2"
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp/awscli-extract
    sudo /tmp/awscli-extract/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/awscli-extract
fi

# Google Cloud CLI
if [[ "${INSTALL_GCLOUD:-false}" == true ]] && ! has gcloud; then
    step "Google Cloud CLI"
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
    sudo apt-get update -qq && apt_install google-cloud-cli
fi

# Azure CLI
if [[ "${INSTALL_AZURECLI:-false}" == true ]] && ! has az; then
    step "Azure CLI"
    curl -sL https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
        | sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null
    sudo apt-get update -qq && apt_install azure-cli
fi

# Vagrant (HashiCorp repo — terraform already adds it)
if [[ "${INSTALL_VAGRANT:-false}" == true ]] && ! has vagrant; then
    step "Vagrant"
    # HashiCorp repo already added by Terraform section if selected; add if needed
    if [[ ! -f /etc/apt/sources.list.d/hashicorp.list ]]; then
        add_apt_repo "HashiCorp" \
            "gpg:https://apt.releases.hashicorp.com/gpg" \
            "/usr/share/keyrings/hashicorp-archive-keyring.gpg" \
            "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
            "/etc/apt/sources.list.d/hashicorp.list"
        sudo apt-get update -qq
    fi
    apt_install vagrant
fi

# Packer
if [[ "${INSTALL_PACKER:-false}" == true ]] && ! has packer; then
    step "Packer"
    if [[ ! -f /etc/apt/sources.list.d/hashicorp.list ]]; then
        add_apt_repo "HashiCorp" \
            "gpg:https://apt.releases.hashicorp.com/gpg" \
            "/usr/share/keyrings/hashicorp-archive-keyring.gpg" \
            "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
            "/etc/apt/sources.list.d/hashicorp.list"
        sudo apt-get update -qq
    fi
    apt_install packer
fi

# Pulumi
if [[ "${INSTALL_PULUMI:-false}" == true ]] && ! has pulumi; then
    step "Pulumi"
    curl -fsSL https://get.pulumi.com | sh
    add_path 'export PATH="$HOME/.pulumi/bin:$PATH"'
fi

# Trivy (container/FS vulnerability scanner)
if [[ "${INSTALL_TRIVY:-false}" == true ]] && ! has trivy; then
    step "Trivy"
    curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
        | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
        | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
    sudo apt-get update -qq && apt_install trivy
fi

# ngrok
if [[ "${INSTALL_NGROK:-false}" == true ]] && ! has ngrok; then
    step "ngrok"
    curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/ngrok.gpg
    echo "deb [signed-by=/usr/share/keyrings/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com buster main" \
        | sudo tee /etc/apt/sources.list.d/ngrok.list > /dev/null
    sudo apt-get update -qq && apt_install ngrok
fi

# act (run GitHub Actions locally)
if [[ "${INSTALL_ACT:-false}" == true ]] && ! has act; then
    step "act"
    curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash -s -- -b /usr/local/bin
fi

# lazydocker
if ([[ "${INSTALL_LAZYDOCKER:-false}" == true ]] || in_array 15 "${SEL_DEVOPS[@]}" || in_array 2 "${SEL_TERMINAL[@]}") && ! has lazydocker; then
    step "lazydocker"
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
fi

# ctop (container top)
if [[ "${INSTALL_CTOP:-false}" == true ]] && ! has ctop; then
    step "ctop"
    CTOP_VER=$(curl -s https://api.github.com/repos/bcicen/ctop/releases/latest | jq -r '.tag_name' | tr -d 'v')
    wget -q "https://github.com/bcicen/ctop/releases/download/v${CTOP_VER}/ctop-${CTOP_VER}-linux-amd64" -O /tmp/ctop
    chmod +x /tmp/ctop && sudo mv /tmp/ctop /usr/local/bin/ctop
fi

# dive (Docker image analyser)
if [[ "${INSTALL_DIVE:-false}" == true ]] && ! has dive; then
    step "dive"
    DIVE_VER=$(curl -s https://api.github.com/repos/wagoodman/dive/releases/latest | jq -r '.tag_name' | tr -d 'v')
    wget -q "https://github.com/wagoodman/dive/releases/download/v${DIVE_VER}/dive_${DIVE_VER}_linux_amd64.deb" -O /tmp/dive.deb
    sudo dpkg -i /tmp/dive.deb || sudo apt-get -f install -y
fi

# LocalStack (AWS emulator)
if [[ "${INSTALL_LOCALSTACK:-false}" == true ]] && ! has localstack; then
    step "LocalStack"
    pip3 install localstack --user
fi

# MailHog (email testing)
if [[ "${INSTALL_MAILHOG:-false}" == true ]] && ! has MailHog; then
    step "MailHog"
    wget -q "https://github.com/mailhog/MailHog/releases/latest/download/MailHog_linux_amd64" -O /tmp/mailhog
    chmod +x /tmp/mailhog && sudo mv /tmp/mailhog /usr/local/bin/MailHog
    # systemd service
    sudo tee /etc/systemd/system/mailhog.service > /dev/null << 'MHSERVICE'
[Unit]
Description=MailHog Email Testing Service
[Service]
ExecStart=/usr/local/bin/MailHog
Restart=always
[Install]
WantedBy=multi-user.target
MHSERVICE
    sudo systemctl daemon-reload && sudo systemctl enable mailhog
fi

# Telepresence (K8s local dev)
if [[ "${INSTALL_TELEPRESENCE:-false}" == true ]] && ! has telepresence; then
    step "Telepresence"
    TP_VER=$(curl -s https://api.github.com/repos/telepresenceio/telepresence/releases/latest | jq -r '.tag_name' | tr -d 'v')
    sudo curl -fL "https://app.getambassador.io/download/tel2oss/releases/download/v${TP_VER}/telepresence-linux-amd64" \
        -o /usr/local/bin/telepresence
    sudo chmod +x /usr/local/bin/telepresence
fi

# ── FASE 7: Terminal tools (Go/cargo/binary) ──────────────
section "H — Terminal tools binários"

export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

for idx in "${SEL_TERMINAL[@]}"; do
    case $idx in
        1) # lazygit — use binary release (works without Go)
           if ! has lazygit; then
               LG_VER=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r '.tag_name' | tr -d 'v')
               wget -q "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz" -O /tmp/lazygit.tar.gz
               tar -xzf /tmp/lazygit.tar.gz -C /tmp/ lazygit
               sudo mv /tmp/lazygit /usr/local/bin/lazygit
           fi ;;
        3) # yazi
           if ! has yazi && has cargo; then
               cargo install --locked yazi-fm yazi-cli
           elif ! has yazi; then
               YZ_VER=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | jq -r '.tag_name')
               wget -q "https://github.com/sxyazi/yazi/releases/download/${YZ_VER}/yazi-x86_64-unknown-linux-gnu.zip" -O /tmp/yazi.zip
               unzip -q /tmp/yazi.zip -d /tmp/yazi-extract
               sudo cp /tmp/yazi-extract/*/yazi /usr/local/bin/
           fi ;;
        4) # lf
           if ! has lf; then
               LF_VER=$(curl -s https://api.github.com/repos/gokcehan/lf/releases/latest | jq -r '.tag_name')
               wget -q "https://github.com/gokcehan/lf/releases/download/${LF_VER}/lf-linux-amd64.tar.gz" -O /tmp/lf.tar.gz
               tar -xzf /tmp/lf.tar.gz -C /tmp/ lf
               sudo mv /tmp/lf /usr/local/bin/lf
           fi ;;
        5) # ranger
           pip3 install ranger-fm --user ;;
        11) # eza
            if ! has eza && has cargo; then cargo install eza
            else apt_install eza 2>/dev/null || true; fi ;;
        13) # delta
            if ! has delta; then
                DELTA_VER=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | jq -r '.tag_name')
                wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/git-delta_${DELTA_VER}_amd64.deb" -O /tmp/delta.deb
                sudo dpkg -i /tmp/delta.deb || { has cargo && cargo install git-delta; }
            fi ;;
        14) # dust
            has cargo && cargo install du-dust ;;
        15) # duf
            apt_install duf 2>/dev/null || {
                DUF_VER=$(curl -s https://api.github.com/repos/muesli/duf/releases/latest | jq -r '.tag_name' | tr -d 'v')
                wget -q "https://github.com/muesli/duf/releases/download/v${DUF_VER}/duf_${DUF_VER}_linux_amd64.deb" -O /tmp/duf.deb
                sudo dpkg -i /tmp/duf.deb
            } ;;
        19) # tmux-sessionizer
            mkdir -p "$HOME/.local/bin"
            cat > "$HOME/.local/bin/ts" << 'TS_SCRIPT'
#!/usr/bin/env bash
if [[ $# -eq 1 ]]; then
    selected="$1"
else
    selected=$(find ~/Desktop/DEV ~/dotfiles ~ -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf)
fi
[ -z "$selected" ] && exit 0
selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected" && exit 0
fi
if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi
tmux switch-client -t "$selected_name"
TS_SCRIPT
            chmod +x "$HOME/.local/bin/ts" ;;
        21) # mcfly
            if ! has mcfly; then
                curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sudo sh -s -- --git cantino/mcfly
            fi ;;
        26) # superfile
            if ! has spf; then
                bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
            fi ;;
        37) # rclone
            if ! has rclone; then
                curl https://rclone.org/install.sh | sudo bash
            fi ;;
        38) # restic
            apt_install restic 2>/dev/null || true ;;
        40) # Starship
            if ! has starship; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            fi ;;
        41) # oh-my-posh
            if ! has oh-my-posh; then
                sudo wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
                sudo chmod +x /usr/local/bin/oh-my-posh
            fi ;;
        43) # fastfetch
            apt_install fastfetch 2>/dev/null || {
                wget -q "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb" -O /tmp/ff.deb
                sudo dpkg -i /tmp/ff.deb
            } ;;
        47) # terminalizer
            has npm && npm install -g terminalizer 2>/dev/null || warn "terminalizer precisa de Node/npm" ;;
    esac
done

# ── FASE 8: Dev tools binários/AppImage ──────────────────
section "I — Dev tools (binários/AppImage)"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

# Postman
if [[ "${INSTALL_POSTMAN:-false}" == true ]] && [ ! -d "$HOME/.local/share/Postman" ]; then
    step "Postman"
    wget -q "https://dl.pstmn.io/download/latest/linux64" -O /tmp/postman.tar.gz
    tar -xzf /tmp/postman.tar.gz -C "$HOME/.local/share/"
    ln -sf "$HOME/.local/share/Postman/Postman" "$HOME/.local/bin/postman"
    cat > "$HOME/.local/share/applications/postman.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Postman
Exec=$HOME/.local/share/Postman/Postman
Icon=$HOME/.local/share/Postman/app/resources/app/assets/icon.png
Terminal=false
Categories=Development;
EOF
fi

# Insomnia
if [[ "${INSTALL_INSOMNIA:-false}" == true ]]; then
    if ! has insomnia; then
        add_apt_repo "Insomnia" \
            "gpg:https://insomnia.rest/keys/debian-public.key.asc" \
            "/usr/share/keyrings/insomnia.gpg" \
            "deb [signed-by=/usr/share/keyrings/insomnia.gpg] https://dl.todesktop.com/210105sqiCDN78r stable main" \
            "/etc/apt/sources.list.d/insomnia.list"
        sudo apt-get update -qq && apt_install insomnia
    fi
fi

# DBeaver
if [[ "${INSTALL_DBEAVER:-false}" == true ]]; then
    if ! has dbeaver; then
        wget -q "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb" -O /tmp/dbeaver.deb
        sudo dpkg -i /tmp/dbeaver.deb || sudo apt-get -f install -y
    fi
fi

# Bruno
if [[ "${INSTALL_BRUNO:-false}" == true ]] && ! has bruno; then
    add_apt_repo "Bruno" \
        "gpg:https://packagecloud.io/usebruno/bruno/gpgkey" \
        "/usr/share/keyrings/bruno.gpg" \
        "deb [signed-by=/usr/share/keyrings/bruno.gpg] https://packagecloud.io/usebruno/bruno/deb/ any main" \
        "/etc/apt/sources.list.d/bruno.list"
    sudo apt-get update -qq && apt_install bruno
fi

# Beekeeper Studio (DB GUI)
if [[ "${INSTALL_BEEKEEPER:-false}" == true ]] && ! has beekeeper-studio; then
    step "Beekeeper Studio"
    wget -qO /tmp/beekeeper.gpg https://deb.beekeeperstudio.io/beekeeper.key
    sudo gpg --dearmor -o /usr/share/keyrings/beekeeper.gpg /tmp/beekeeper.gpg
    echo "deb [signed-by=/usr/share/keyrings/beekeeper.gpg] https://deb.beekeeperstudio.io stable main" \
        | sudo tee /etc/apt/sources.list.d/beekeeper-studio.list > /dev/null
    sudo apt-get update -qq && apt_install beekeeper-studio
fi

# TablePlus
if [[ "${INSTALL_TABLEPLUS:-false}" == true ]] && ! has tableplus; then
    step "TablePlus"
    wget -qO /tmp/tableplus.gpg https://deb.tableplus.com/apt.tableplus.com.gpg.key
    sudo gpg --dearmor -o /usr/share/keyrings/tableplus.gpg /tmp/tableplus.gpg
    echo "deb [signed-by=/usr/share/keyrings/tableplus.gpg] https://deb.tableplus.com/debian/22 tableplus main" \
        | sudo tee /etc/apt/sources.list.d/tableplus.list > /dev/null
    sudo apt-get update -qq && apt_install tableplus
fi

# GitKraken
if [[ "${INSTALL_GITKRAKEN:-false}" == true ]] && ! has gitkraken; then
    step "GitKraken"
    GK_VER=$(curl -s https://api.github.com/repos/gitkraken/gitkraken-docker/releases/latest | jq -r '.tag_name' | tr -d 'v') || GK_VER="10.3.0"
    wget -q "https://release.axocdn.com/linux/gitkraken-amd64.deb" -O /tmp/gitkraken.deb
    sudo dpkg -i /tmp/gitkraken.deb || sudo apt-get -f install -y
fi

# PgAdmin (PostgreSQL GUI)
if [[ "${INSTALL_PGADMIN:-false}" == true ]] && ! has pgadmin4; then
    step "pgAdmin 4"
    curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
    echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" \
        | sudo tee /etc/apt/sources.list.d/pgadmin4.list > /dev/null
    sudo apt-get update -qq && apt_install pgadmin4-desktop
fi

# Redis Commander (Redis GUI — via npm)
if [[ "${INSTALL_REDIS_COMMANDER:-false}" == true ]] && ! has redis-commander; then
    step "Redis Commander"
    has npm || warn "Redis Commander precisa de Node/npm"
    has npm && npm install -g redis-commander
fi

# Mongo Express (MongoDB GUI — via npm/Docker)
if [[ "${INSTALL_MONGO_EXPRESS:-false}" == true ]] && has docker; then
    step "Mongo Express (Docker)"
    docker pull mongo-express 2>/dev/null || warn "Mongo Express: 'docker run -p 8081:8081 mongo-express'"
fi

# Hoppscotch (API client — web/AppImage)
if [[ "${INSTALL_HOPPSCOTCH:-false}" == true ]]; then
    step "Hoppscotch (web app — abre https://hoppscotch.io)"
    # Hoppscotch é web-based; opcional instalar como PWA no browser
    info "Hoppscotch disponível em https://hoppscotch.io (sem install necessário)"
fi

# SEQ (log server)
if [[ "${INSTALL_SEQ:-false}" == true ]]; then
    step "SEQ (via Docker)"
    if has docker; then
        docker pull datalust/seq 2>/dev/null || true
        info "SEQ disponível. Inicia com: docker run -p 80:80 -p 5341:5341 datalust/seq"
    else
        warn "SEQ precisa de Docker"
    fi
fi

# SoapUI (SOAP/REST tester)
if [[ "${INSTALL_SOAPUI:-false}" == true ]] && [ ! -d "$HOME/.local/share/SoapUI" ]; then
    step "SoapUI"
    SUI_VER=$(curl -s https://api.github.com/repos/SmartBear/soapui/releases/latest | jq -r '.tag_name' | tr -d 'soapui-')
    SUI_VER="${SUI_VER:-5.7.2}"
    wget -q "https://dl.eviware.com/soapuios/${SUI_VER}/SoapUI-${SUI_VER}-linux-bin.tar.gz" -O /tmp/soapui.tar.gz
    mkdir -p "$HOME/.local/share/SoapUI"
    tar -xzf /tmp/soapui.tar.gz -C "$HOME/.local/share/SoapUI" --strip-components=1
    ln -sf "$HOME/.local/share/SoapUI/bin/soapui.sh" "$HOME/.local/bin/soapui"
    chmod +x "$HOME/.local/bin/soapui"
fi

# PocketBase (self-hosted BaaS)
if [[ "${INSTALL_POCKETBASE:-false}" == true ]] && ! has pocketbase; then
    step "PocketBase"
    PB_VER=$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest | jq -r '.tag_name' | tr -d 'v')
    wget -q "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VER}/pocketbase_${PB_VER}_linux_amd64.zip" -O /tmp/pocketbase.zip
    unzip -q /tmp/pocketbase.zip -d /tmp/pocketbase-extract
    sudo mv /tmp/pocketbase-extract/pocketbase /usr/local/bin/pocketbase
    chmod +x /usr/local/bin/pocketbase
    rm -rf /tmp/pocketbase.zip /tmp/pocketbase-extract
fi

# Obsidian
if in_array 0 "${SEL_PRODUCTIVITY[@]}" && ! has obsidian; then
    step "Obsidian (AppImage)"
    OBS_VER=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | jq -r '.tag_name' | tr -d 'v')
    wget -q "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBS_VER}/Obsidian-${OBS_VER}.AppImage" -O "$HOME/.local/bin/obsidian"
    chmod +x "$HOME/.local/bin/obsidian"
fi

# Bitwarden Desktop
if in_array 25 "${SEL_PRODUCTIVITY[@]}" && ! has bitwarden; then
    step "Bitwarden (AppImage)"
    BW_VER=$(curl -s https://api.github.com/repos/bitwarden/clients/releases | jq -r '[.[] | select(.tag_name | startswith("desktop"))][0].tag_name' | tr -d 'desktop-v')
    wget -q "https://github.com/bitwarden/clients/releases/download/desktop-v${BW_VER}/Bitwarden-${BW_VER}-x86_64.AppImage" -O "$HOME/.local/bin/bitwarden"
    chmod +x "$HOME/.local/bin/bitwarden"
fi

# Spicetify
if in_array 4 "${SEL_MULTIMEDIA[@]}" && ! has spicetify; then
    step "Spicetify"
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
    export PATH="$HOME/.spicetify:$PATH"
    spicetify backup apply 2>/dev/null || warn "Spicetify: corre 'spicetify backup apply' após iniciar o Spotify"
fi

# Flameshot (screenshots)
in_array 21 "${SEL_MULTIMEDIA[@]}" && apt_install flameshot

# Heroic Games Launcher
if in_array 2 "${SEL_GAMING[@]}" && ! has heroic; then
    step "Heroic Games Launcher"
    H_VER=$(curl -s https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | jq -r '.tag_name' | tr -d 'v')
    wget -q "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${H_VER}/heroic_${H_VER}_amd64.deb" -O /tmp/heroic.deb
    sudo dpkg -i /tmp/heroic.deb || sudo apt-get -f install -y
fi

# Bottles
in_array 3 "${SEL_GAMING[@]}" && apt_install bottles 2>/dev/null || true

# ProtonUp-Qt
if in_array 6 "${SEL_GAMING[@]}" && ! has protonup-qt; then
    pip3 install protonup-qt --user 2>/dev/null || true
fi

# GitHub Copilot CLI
if [[ "${INSTALL_COPILOT_CLI:-false}" == true ]] && has gh; then
    gh extension install github/gh-copilot 2>/dev/null || true
fi

# ── FASE 9: Fontes ────────────────────────────────────────
section "J — Nerd Fonts"

FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

NERD_NAMES=(
    "JetBrainsMono"
    "FiraCode"
    "Hack"
    "CascadiaCode"
    "UbuntuMono"
    "Iosevka"
    "Meslo"
    "FantasqueSansMono"
)

for idx in "${SEL_FONTS[@]}"; do
    case $idx in
        0|1|2|3|4|5|6|7)
            font="${NERD_NAMES[$idx]}"
            if ! fc-list | grep -qi "$font"; then
                step "Font: $font"
                wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VER}/${font}.zip" -O "/tmp/${font}.zip"
                unzip -q "/tmp/${font}.zip" -d "$FONTS_DIR/${font}/"
                rm "/tmp/${font}.zip"
            fi ;;
        8) apt_install fonts-noto fonts-noto-color-emoji ;;
        9) apt_install fonts-inter || true ;;
        10) apt_install fonts-roboto ;;
    esac
done

fc-cache -fv > /dev/null && info "Cache de fontes actualizado"

# ── FASE 10: Temas ────────────────────────────────────────
section "K — Temas & aparência"

for idx in "${SEL_THEMES[@]}"; do
    case $idx in
        0) # Bibata cursor
           if ! [ -d "$HOME/.local/share/icons/Bibata-Modern-Classic" ]; then
               step "Bibata cursor"
               BIBA_VER=$(curl -s https://api.github.com/repos/ful1e5/Bibata_Cursor/releases/latest | jq -r '.tag_name')
               wget -q "https://github.com/ful1e5/Bibata_Cursor/releases/download/${BIBA_VER}/Bibata-Modern-Classic.tar.xz" -O /tmp/bibata.tar.xz
               mkdir -p "$HOME/.local/share/icons"
               tar -xJf /tmp/bibata.tar.xz -C "$HOME/.local/share/icons/"
           fi ;;
        1) # Papirus
           apt_install papirus-icon-theme ;;
        2) # Gruvbox GTK
           if ! [ -d "$HOME/.themes/Gruvbox-Dark" ]; then
               step "Gruvbox GTK theme"
               git clone --depth=1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/gruvbox-gtk
               mkdir -p "$HOME/.themes"
               cp -r /tmp/gruvbox-gtk/themes/* "$HOME/.themes/"
           fi ;;
        3) # Catppuccin GTK
           if ! [ -d "$HOME/.themes/catppuccin-mocha" ]; then
               step "Catppuccin GTK theme"
               C_VER=$(curl -s https://api.github.com/repos/catppuccin/gtk/releases/latest | jq -r '.tag_name')
               wget -q "https://github.com/catppuccin/gtk/releases/download/${C_VER}/catppuccin-mocha-standard-blue-dark.zip" -O /tmp/catppuccin-gtk.zip
               mkdir -p "$HOME/.themes"
               unzip -q /tmp/catppuccin-gtk.zip -d "$HOME/.themes/"
           fi ;;
        4) # adw-gtk3
           apt_install adw-gtk3 2>/dev/null || {
               ADWGTK_VER=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | jq -r '.tag_name')
               wget -q "https://github.com/lassekongo83/adw-gtk3/releases/download/${ADWGTK_VER}/adw-gtk3v${ADWGTK_VER#v}.tar.xz" -O /tmp/adw.tar.xz
               tar -xJf /tmp/adw.tar.xz -C "$HOME/.themes/"
           } ;;
        5) # Kvantum
           apt_install qt5-style-kvantum qt5-style-kvantum-themes ;;
    esac
done

# ── FASE 11: Dotfiles ─────────────────────────────────────
section "L — Dotfiles"

if [[ "$INSTALL_DOTFILES" == true ]]; then
    DOTFILES_DIR="$HOME/dotfiles"
    if [ -d "$DOTFILES_DIR" ]; then
        step "Actualizando dotfiles existentes"
        cd "$DOTFILES_DIR" && git pull
    else
        step "A clonar dotfiles"
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
    if [ -f "$DOTFILES_DIR/install.sh" ]; then
        chmod +x "$DOTFILES_DIR/install.sh"
        bash "$DOTFILES_DIR/install.sh"
        info "Dotfiles instalados via install.sh"
    fi
fi

# ── FASE 12: Estrutura DEV ────────────────────────────────
if [[ "$INSTALL_DEV_FOLDERS" == true ]]; then
    section "M — Estrutura de pastas DEV"
    for category in College Personal Work; do
        mkdir -p "$HOME/Desktop/DEV/Versioned/$category"
        mkdir -p "$HOME/Desktop/DEV/Unversioned/$category"
    done
    info "Criado: ~/Desktop/DEV/{Versioned,Unversioned}/{College,Personal,Work}"
fi

# ── FASE 13: PATH no .zshrc ───────────────────────────────
section "N — Variáveis de ambiente"

ZSHRC="$HOME/.zshrc"

[[ "$INSTALL_GO" == true ]] && add_path 'export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"'
[[ "$INSTALL_FLUTTER" == true ]] && add_path 'export PATH="$HOME/flutter/bin:$PATH"'
[[ "${INSTALL_ANDROID_SDK:-false}" == true ]] && {
    add_path 'export ANDROID_HOME="$HOME/Android"'
    add_path 'export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"'
}
[[ "$INSTALL_RUST" == true ]] && add_path 'source "$HOME/.cargo/env"'
[[ "$INSTALL_PHP" == true ]] && add_path 'export PATH="$HOME/.composer/vendor/bin:$PATH"'
[[ "$INSTALL_RUBY" == true ]] && add_path 'export PATH="$HOME/.rbenv/bin:$PATH"' && add_path 'eval "$(rbenv init -)"'
[[ "${INSTALL_KOTLIN:-false}" == true ]] && add_path 'source "$HOME/.sdkman/bin/sdkman-init.sh"'
add_path 'export PATH="$HOME/.local/bin:$HOME/.spicetify:$PATH"'

# ── LIMPEZA ───────────────────────────────────────────────
section "LIMPEZA"
sudo apt-get autoremove -y -qq
sudo apt-get clean -qq
rm -rf "$BUILD"
info "Limpeza feita"

# ═══════════════════════════════════════════════════════════════
# FIM
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔════════════════════════════════════════════════════╗"
echo "  ║           SETUP COMPLETO! 🎉                      ║"
echo "  ╚════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Passos manuais:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Reinicia:                 ${YELLOW}sudo reboot${NC}"
echo -e "  ${CYAN}2.${NC} Login no GitHub CLI:      ${YELLOW}gh auth login${NC}"
echo -e "  ${CYAN}3.${NC} Nvim (plugins auto):      ${YELLOW}nvim${NC}"
echo -e "  ${CYAN}4.${NC} Tmux plugins:             ${YELLOW}tmux → Prefix+I${NC}"
echo -e "  ${CYAN}5.${NC} Docker sem sudo:          ${YELLOW}newgrp docker${NC}"
[[ "$INSTALL_SPOTIFY" == true ]] && \
echo -e "  ${CYAN}6.${NC} Spicetify:                ${YELLOW}spicetify backup apply${NC}"
[[ "${INSTALL_FLUTTER:-false}" == true ]] && \
echo -e "  ${CYAN}7.${NC} Flutter check:            ${YELLOW}flutter doctor${NC}"
echo ""
echo -e "  Log completo: ${YELLOW}$LOG_FILE${NC}"
echo ""
