# /bin/bash

# # Script para iniciar aplicações em workspaces específicos
# # Dá tempo para o Hyprland inicializar completamente
# # Workspace 8 - Brave
# # Inicia o Brave em segundo plano
# brave-browser &
# brave-browser &
# code &
# # Aguarda o Brave inicializar e criar suas janelas
# sleep 1
# # Foca na janela do Brave pela classe e move para o workspace 8
# hyprctl dispatch focuswindow "class:brave-browser"
# hyprctl dispatch movetoworkspacesilent 9

# # Workspace 2 - VSCode
# # Inicia o VSCode em segundo plano
# # Aguarda o VSCode inicializar (pode demorar um pouco mais)
# # sleep 1
# # Foca na janela do VSCode pela classe e move para o workspace 2
# hyprctl dispatch focuswindow "class:code"
# hyprctl dispatch movetoworkspacesilent 2
# # flatpak run com.brave.Browser &




#!/bin/bash

# Workspace 8 - Brave
firefox &
code &

# Esperar o firefox criar janelas
sleep 2


code_addr=$(hyprctl clients -j | jq -r '.[] | select(.class == "code") | .address' | head -n1)
if [ -n "$code_addr" ]; then
  hyprctl dispatch focuswindow "address:$code_addr"
  hyprctl dispatch movetoworkspacesilent 2
fi


# kanata -c ~/.config/kanata/config.kbd


