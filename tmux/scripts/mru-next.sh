#!/bin/bash
# Cicla para a próxima janela na ordem MRU (mais recentemente usada).
# Chamado pelo Alt+Tab. Não atualiza a lista MRU durante o ciclo.

CURRENT=$(tmux display-message -p "#I")
SESSION=$(tmux display-message -p "#S")
KEY="@mru_$(echo "$SESSION" | tr -cd 'a-zA-Z0-9_')"

MRU=$(tmux show-option -gqv "$KEY" 2>/dev/null)

# Se a lista ainda não existe, inicializa com as janelas atuais por ordem sequencial
if [ -z "$MRU" ]; then
    MRU=$(tmux list-windows -F "#I" | tr '\n' ' ' | sed 's/ $//')
    tmux set-option -g "$KEY" "$MRU"
fi

# Filtra janelas que já não existem (fechadas entretanto)
ACTUAL=$(tmux list-windows -F "#I")
FILTERED=""
for W in $MRU; do
    echo "$ACTUAL" | grep -qx "$W" && FILTERED="$FILTERED $W"
done
MRU="${FILTERED# }"
tmux set-option -g "$KEY" "$MRU"

read -ra WINS <<< "$MRU"
[ ${#WINS[@]} -le 1 ] && exit 0

# Encontra a posição atual na lista MRU
POS=0
for i in "${!WINS[@]}"; do
    [ "${WINS[$i]}" = "$CURRENT" ] && POS=$i && break
done

# Avança para a próxima (com ciclo)
NEXT=$(( (POS + 1) % ${#WINS[@]} ))

# Marca que estamos em modo ciclo (o hook salta a atualização MRU)
tmux set-option -g "@mru_cycling" "1"
tmux select-window -t "${WINS[$NEXT]}"
