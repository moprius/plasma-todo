# Plasma-ToDo

Uma lista de tarefas para o **KDE Plasma 6** que vive na Área de Notificação do sistema. Cada tarefa pode ter subtarefas, um texto longo em Markdown, ser fixada no topo e ser reorganizada por arrastar e soltar. A pesquisa é instantânea e percorre tanto o título quanto o conteúdo em Markdown de cada item.


## Recursos

- **Subtarefas aninhadas**: cada tarefa abre sua própria lista, com um contador de concluídas (`2/5`) visível no item pai.
- **Fixar no topo**: tarefas fixadas formam um grupo separado e permanecem sempre acima das tarefas comuns.
- **Arrastar e soltar**: reorganização por uma alça dedicada, restrita ao mesmo grupo (fixadas ou comuns) para preservar a ordem.
- **Texto em Markdown por tarefa**: editor com abas de edição e pré-visualização, aceitando títulos, listas, links, imagens, tabelas, citações, código e formatação de texto.
- **Pesquisa instantânea**: filtra por título e por conteúdo Markdown, ignorando acentos e diferenças de maiúsculas.
- **Persistência local**: o estado é gravado via `QtQuick.LocalStorage`, sem depender de serviços externos.
- **Integração com a bandeja**: aparece na Área de Notificação com dica de ferramenta mostrando a contagem de tarefas.

## Requisitos

- KDE Plasma 6.0 ou superior
- Qt 6 com módulos QtQuick, QtQuick.Controls e QtQuick.LocalStorage
- Frameworks Kirigami (`org.kde.kirigami`)

A maioria das distribuições já fornece tudo isso junto com o Plasma 6.

## Instalação

### Opção 1: script de instalação

```bash
git clone https://github.com/moprius/plasma-todo.git
cd plasma-todo
./install.sh
```

O script usa `kpackagetool6` e detecta se deve instalar ou atualizar uma versão já presente.

### Opção 2: manual com kpackagetool6

```bash
# Instalar
kpackagetool6 --type Plasma/Applet --install package/

# Atualizar uma versão já instalada
kpackagetool6 --type Plasma/Applet --upgrade package/

# Remover
kpackagetool6 --type Plasma/Applet --remove Plasma-ToDo
```

Depois de instalar, adicione o widget pela própria Área de Notificação (em "Configurar" da bandeja) ou pelo menu "Adicionar Widgets". Se ele não aparecer de imediato, reinicie o shell:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Onde os dados ficam

As tarefas são armazenadas pelo mecanismo `LocalStorage` do Qt, no banco chamado `qtodo`, dentro do diretório de dados do Plasma do seu usuário (normalmente em `~/.local/share/plasma/`). Remover o plasmoide não apaga automaticamente esse banco.

## Desenvolvimento

Para testar mudanças sem reinstalar a cada edição, use o visualizador de plasmoides apontando para a pasta do pacote:

```bash
plasmoidviewer --applet package/
```

Estrutura do repositório:

```
plasma-todo/
├── package/
│   ├── metadata.json          # Metadados do applet (id, versão, licença)
│   └── contents/ui/
│       ├── main.qml           # Representações compacta e completa, persistência
│       ├── InputItem.qml      # Campo de entrada de novas tarefas
│       └── TodoList.qml       # Lista, delegate, pesquisa, drag-and-drop, Markdown
├── install.sh
├── uninstall.sh
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Licença

Distribuído sob a **GNU General Public License v3.0 ou posterior** (GPL-3.0-or-later). Veja o arquivo [LICENSE](LICENSE) para o texto completo.

## Créditos

Criado por **Moprius**.
