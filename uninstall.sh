#!/usr/bin/env bash
#
# Remove o plasmoide Plasma-ToDo do usuário atual.
# Uso:
#   ./uninstall.sh

set -euo pipefail

PLASMOID_ID="Plasma-ToDo"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Erro: kpackagetool6 não encontrado. Instale o Plasma 6." >&2
    exit 1
fi

echo "Removendo ${PLASMOID_ID}..."
kpackagetool6 --type Plasma/Applet --remove "${PLASMOID_ID}"
echo "Concluído."
