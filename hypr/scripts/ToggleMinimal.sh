#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# ToggleMinimal.sh — toggles between the full and i3-minimal Hyprland profiles
#
# Minimal profile:
#   - Waybar: [BOT] i3-Minimal config + [i3] Minimal.css
#   - Decorations: square windows, no blur/shadow/dim, static Gruvbox borders
# Full profile:
#   - Restores the waybar symlinks that were active before switching to minimal
#   - hyprctl reload restores all original decoration values from config files
#
# Keybind: Super+Ctrl+M (defined in UserKeybinds.conf)

WAYBAR_CONFIG="$HOME/.config/waybar/config"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
WAYBAR_CONFIGS_DIR="$HOME/.config/waybar/configs"
WAYBAR_STYLE_DIR="$HOME/.config/waybar/style"

MINIMAL_CONFIG="[BOT] i3-Minimal"
MINIMAL_STYLE="[i3] Minimal.css"

STATE_FILE="$HOME/.cache/hypr-minimal-mode"
BACKUP_CONFIG="$HOME/.cache/hypr-waybar-config-backup"
BACKUP_STYLE="$HOME/.cache/hypr-waybar-style-backup"
BACKUP_WALLPAPER="$HOME/.cache/hypr-wallpaper-backup"

MINIMAL_WALLPAPER="$HOME/Pictures/wallpapers/gruvbox.jpg"

SCRIPTSDIR="$HOME/.config/hypr/scripts"

restart_waybar() {
    pkill -x waybar 2>/dev/null
    sleep 0.5
    waybar &>/dev/null &
    disown
}

activate_minimal() {
    # Save current symlink targets so we can restore them later
    readlink "$WAYBAR_CONFIG" > "$BACKUP_CONFIG"
    readlink "$WAYBAR_STYLE"  > "$BACKUP_STYLE"

    # Save current wallpaper (first monitor is enough — swww sets all)
    swww query 2>/dev/null | awk -F'image: ' 'NR==1 && NF>1 {print $2}' > "$BACKUP_WALLPAPER"

    # Switch waybar symlinks to minimal profile
    ln -sf "$WAYBAR_CONFIGS_DIR/$MINIMAL_CONFIG" "$WAYBAR_CONFIG"
    ln -sf "$WAYBAR_STYLE_DIR/$MINIMAL_STYLE"    "$WAYBAR_STYLE"

    # Apply decoration overrides at runtime (no file edits, reversible via hyprctl reload)
    hyprctl keyword decoration:rounding           0
    hyprctl keyword decoration:blur:enabled       false
    hyprctl keyword decoration:shadow:enabled     false
    hyprctl keyword decoration:dim_inactive       false
    hyprctl keyword decoration:active_opacity     1.0
    hyprctl keyword decoration:inactive_opacity   0.98
    hyprctl keyword general:border_size           1
    hyprctl keyword general:gaps_in               0
    hyprctl keyword general:gaps_out              0
    hyprctl keyword "general:col.active_border"   "rgba(fe8019ff)"
    hyprctl keyword "general:col.inactive_border" "rgba(504945ff)"

    # Override window-rule opacity for terminals — window rules beat global opacity settings,
    # so we append a higher-priority rule that forces kitty to 1.0 active / 0.98 inactive.
    # hyprctl reload (on deactivate) removes these keyword-injected rules.
    hyprctl keyword windowrulev2 "opacity 1.0 0.98, class:^(kitty|Alacritty|kitty-dropterm)$"

    # Set Gruvbox wallpaper on all monitors
    swww img "$HOME/Pictures/wallpapers/gruvbox.jpg" \
        --transition-type none 2>/dev/null || true

    echo "minimal" > "$STATE_FILE"
    restart_waybar
    notify-send -u low -i preferences-desktop "Hyprland" "Minimal profile activated" 2>/dev/null
}

activate_full() {
    # Restore previously saved waybar symlinks (or fall back to hardcoded defaults)
    if [[ -f "$BACKUP_CONFIG" && -s "$BACKUP_CONFIG" ]]; then
        prev_config=$(cat "$BACKUP_CONFIG")
        ln -sf "$prev_config" "$WAYBAR_CONFIG"
    else
        ln -sf "$WAYBAR_CONFIGS_DIR/[TOP] Default Laptop (old v3)" "$WAYBAR_CONFIG"
    fi

    if [[ -f "$BACKUP_STYLE" && -s "$BACKUP_STYLE" ]]; then
        prev_style=$(cat "$BACKUP_STYLE")
        ln -sf "$prev_style" "$WAYBAR_STYLE"
    else
        ln -sf "$WAYBAR_STYLE_DIR/[Dark] Purpl.css" "$WAYBAR_STYLE"
    fi

    # Reload hyprland — re-reads all config files, resetting every hyprctl keyword override
    hyprctl reload

    # Restore previous wallpaper
    if [[ -f "$BACKUP_WALLPAPER" && -s "$BACKUP_WALLPAPER" ]]; then
        prev_wallpaper=$(cat "$BACKUP_WALLPAPER")
        [[ -f "$prev_wallpaper" ]] && swww img "$prev_wallpaper" --transition-type none 2>/dev/null || true
    fi

    echo "full" > "$STATE_FILE"
    restart_waybar
    notify-send -u low -i preferences-desktop "Hyprland" "Full profile restored" 2>/dev/null
}

# --- Main ---
current_state="full"
if [[ -f "$STATE_FILE" ]]; then
    current_state=$(cat "$STATE_FILE")
fi

if [[ "$current_state" == "minimal" ]]; then
    activate_full
else
    activate_minimal
fi
