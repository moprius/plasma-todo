#!/usr/bin/env bash
#
# Instala (ou atualiza) o plasmoide Plasma-ToDo no usuário atual.
# Uso:
#   ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/package"
PLASMOID_ID="Plasma-ToDo"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Erro: kpackagetool6 não encontrado. Instale o Plasma 6." >&2
    exit 1
fi

if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -qx "${PLASMOID_ID}"; then
    echo "Atualizando ${PLASMOID_ID}..."
    kpackagetool6 --type Plasma/Applet --upgrade "${PACKAGE_DIR}"
else
    echo "Instalando ${PLASMOID_ID}..."
    kpackagetool6 --type Plasma/Applet --install "${PACKAGE_DIR}"
fi

echo "Concluído. Adicione o widget pela bandeja do sistema ou pelo menu \"Adicionar Widgets\"."
echo "Pode ser necessário reiniciar o Plasma: kquitapp6 plasmashell && kstart plasmashell"
