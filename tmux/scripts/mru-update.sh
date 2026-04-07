#!/bin/bash
# Atualiza a lista MRU de janelas por sessão.
# Chamado pelo hook after-select-window.
# Salta a atualização se estiver em modo de ciclo Alt+Tab.

CYCLING=$(tmux show-option -gqv "@mru_cycling" 2>/dev/null)
if [ "$CYCLING" = "1" ]; then
    # Limpa o flag — a próxima navegação normal já atualiza o MRU
    tmux set-option -g "@mru_cycling" "0"
    exit 0
fi

CURRENT=$(tmux display-message -p "#I")
SESSION=$(tmux display-message -p "#S")
# Sanitiza nome de sessão para usar como chave de opção
KEY="@mru_$(echo "$SESSION" | tr -cd 'a-zA-Z0-9_')"

OLD=$(tmux show-option -gqv "$KEY" 2>/dev/null)

# Reconstrói a lista: janela atual primeiro, resto sem duplicar
NEW="$CURRENT"
for W in $OLD; do
    [ "$W" != "$CURRENT" ] && NEW="$NEW $W"
done

tmux set-option -g "$KEY" "$NEW"
