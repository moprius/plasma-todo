import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ListView {
    id: todoList

    anchors.topMargin: Kirigami.Units.smallSpacing
    spacing: 0
    clip: true

    property var thisModel
    property string searchQuery: ""
    property int matchingItemCount: {
        let revision = root.dataRevision
        return todoList.countMatchingItems(todoList.thisModel, todoList.searchQuery)
    }
    property var parentModelList: []
    property var parentModelTitleList: []
    property bool itemDropped: false

    onSearchQueryChanged: positionViewAtBeginning()

    delegate: Item {
        id: itemWrapper

        width: ListView.view ? ListView.view.width * 0.9 : 270
        height: matchesSearch
                ? cardHeight + Kirigami.Units.smallSpacing
                : 0
        visible: matchesSearch
        enabled: matchesSearch
        anchors.horizontalCenter: parent.horizontalCenter

        property int modelIndex: index
        property bool matchesSearch: {
            let revision = root.dataRevision
            return todoList.itemMatchesSearch(itemWrapper.itemModel, todoList.searchQuery)
        }
        property real cardHeight: Math.max(contentColumn.implicitHeight,
                                           actionColumn.implicitHeight,
                                           checkbox.implicitHeight)
                                  + Kirigami.Units.largeSpacing * 2
        property var itemModel: model
        property int dragItemIndex: modelIndex
        property real originalY: y
        property bool dragging: dragHandleArea.drag.active
        property string markdownSource: typeof itemModel.markdown === "string" ? itemModel.markdown : ""
        property bool markdownExpanded: false

        z: dragging ? 100 : 1
        scale: dragging ? 1.015 : 1.0
        opacity: dragging ? 0.9 : 1.0

        onMarkdownSourceChanged: {
            if (markdownSource.length === 0) {
                markdownExpanded = false
            }
        }

        Behavior on scale {
            NumberAnimation { duration: 100 }
        }

        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }

        Drag.active: dragging
        Drag.source: itemWrapper
        Drag.hotSpot: Qt.point(width / 2, Math.min(itemWrapper.cardHeight / 2, height / 2))
        Drag.supportedActions: Qt.MoveAction

        DropArea {
            id: itemDropArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: itemWrapper.cardHeight
            enabled: todoList.searchQuery.trim().length === 0

            onDropped: function(drop) {
                if (!drop.source || drop.source === itemWrapper) {
                    return
                }

                let sourceIndex = drop.source.dragItemIndex
                let targetIndex = itemWrapper.modelIndex

                if (sourceIndex < 0 || sourceIndex >= todoList.thisModel.count
                        || targetIndex < 0 || targetIndex >= todoList.thisModel.count) {
                    return
                }

                let sourcePinned = Boolean(todoList.thisModel.get(sourceIndex).pinned)
                let targetPinned = Boolean(todoList.thisModel.get(targetIndex).pinned)

                // Fixed and regular tasks form separate groups. Reordering is only
                // allowed inside the same group so fixed tasks always stay on top.
                if (sourcePinned !== targetPinned) {
                    drop.source.y = drop.source.originalY
                    todoList.itemDropped = true
                    return
                }

                if (sourceIndex !== targetIndex) {
                    todoList.thisModel.move(sourceIndex, targetIndex, 1)
                    saveModelToJson("todoListModel", todoListModel)
                }

                todoList.itemDropped = true
                drop.acceptProposedAction()
            }
        }

        Rectangle {
            id: dropPositionIndicator
            z: 110
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 2
            visible: itemDropArea.containsDrag && !itemWrapper.dragging
            color: Kirigami.Theme.highlightColor
            radius: 1
        }

        Rectangle {
            id: cardBackground
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: itemWrapper.cardHeight
            radius: Kirigami.Units.smallSpacing * 2
            color: "black"
            opacity: itemWrapper.dragging ? 0.42 : 0.3
            border.width: itemWrapper.dragging ? 1 : 0
            border.color: Kirigami.Theme.highlightColor
        }

        Item {
            id: dragHandle
            z: 5
            width: Kirigami.Units.iconSizes.smallMedium
            height: itemWrapper.cardHeight
            anchors.left: parent.left
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.verticalCenter: cardBackground.verticalCenter
            enabled: todoList.searchQuery.trim().length === 0
            opacity: enabled ? (dragHandleArea.containsMouse || itemWrapper.dragging ? 1.0 : 0.62) : 0.28

            Column {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 3

                    Rectangle {
                        width: Kirigami.Units.smallSpacing * 1.8
                        height: 2
                        radius: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.9
                    }
                }
            }

            MouseArea {
                id: dragHandleArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                preventStealing: true
                drag.target: itemWrapper
                drag.axis: Drag.YAxis
                drag.threshold: Kirigami.Units.smallSpacing

                onPressed: {
                    itemWrapper.dragItemIndex = itemWrapper.modelIndex
                    itemWrapper.originalY = itemWrapper.y
                    todoList.itemDropped = false
                    todoList.interactive = false
                }

                onReleased: {
                    todoList.interactive = true
                    itemWrapper.Drag.drop()
                    if (!todoList.itemDropped) {
                        itemWrapper.y = itemWrapper.originalY
                    }
                    todoList.itemDropped = false
                    Qt.callLater(function() { todoList.forceLayout() })
                }

                onCanceled: {
                    todoList.interactive = true
                    itemWrapper.y = itemWrapper.originalY
                    todoList.itemDropped = false
                    Qt.callLater(function() { todoList.forceLayout() })
                }
            }

            ToolTip.visible: dragHandleArea.containsMouse
            ToolTip.text: enabled
                          ? qsTr("Arraste para reorganizar")
                          : qsTr("Limpe a pesquisa para reorganizar")
        }

        CheckBox {
            id: checkbox
            z: 2
            anchors.left: dragHandle.right
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.verticalCenter: cardBackground.verticalCenter
            checked: Boolean(itemWrapper.itemModel.checked)

            onToggled: {
                todoList.thisModel.setProperty(itemWrapper.modelIndex, "checked", checked)
                saveModelToJson("todoListModel", todoListModel)
            }
        }

        Column {
            id: contentColumn
            z: 2
            anchors.left: checkbox.right
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.right: actionColumn.left
            anchors.rightMargin: Kirigami.Units.largeSpacing
            anchors.verticalCenter: cardBackground.verticalCenter
            spacing: itemWrapper.markdownSource.length > 0 ? Kirigami.Units.smallSpacing : 0

            RowLayout {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    id: pinnedIndicator
                    visible: Boolean(itemWrapper.itemModel.pinned)
                    source: "window-pin"
                    Layout.preferredWidth: visible ? Kirigami.Units.iconSizes.small : 0
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    opacity: 0.9

                    ToolTip.visible: pinnedHover.hovered
                    ToolTip.text: qsTr("Tarefa fixada no topo")

                    HoverHandler {
                        id: pinnedHover
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }
                }

                Text {
                    id: todoText
                    Layout.fillWidth: true
                    text: itemWrapper.itemModel.text || ""
                    font.pixelSize: 16
                    color: "white"
                    wrapMode: Text.Wrap
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                visible: itemWrapper.markdownSource.length > 0
                color: "white"
                opacity: 0.18
            }

            Column {
                id: markdownDisplay
                width: parent.width
                visible: itemWrapper.markdownSource.length > 0
                spacing: Kirigami.Units.smallSpacing

                Column {
                    id: markdownSummaryColumn
                    width: parent.width
                    visible: !itemWrapper.markdownExpanded
                    spacing: 0

                    // The Markdown rich-text renderer may paint long, unbroken
                    // links outside the Text item's visual bounds. Keep the compact
                    // preview in a clipped viewport and render only the first line as
                    // plain text. The complete Markdown remains formatted below when
                    // the user presses More.
                    Item {
                        id: markdownSummaryViewport
                        width: parent.width
                        height: markdownSummary.implicitHeight
                        clip: true

                        Text {
                            id: markdownSummary
                            anchors.fill: parent
                            text: todoList.firstMarkdownLine(itemWrapper.markdownSource)
                            textFormat: Text.PlainText
                            color: "white"
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            clip: true
                        }
                    }

                    Item {
                        width: parent.width
                        height: moreButton.implicitHeight + Kirigami.Units.smallSpacing

                        ToolButton {
                            id: moreButton
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            text: qsTr("More")
                            display: AbstractButton.TextOnly
                            Accessible.name: qsTr("Mostrar texto completo")

                            onClicked: itemWrapper.markdownExpanded = true
                        }
                    }
                }

                Column {
                    id: expandedMarkdownColumn
                    width: parent.width
                    visible: itemWrapper.markdownExpanded
                    spacing: Kirigami.Units.smallSpacing

                    TextEdit {
                        id: markdownText
                        width: parent.width
                        height: visible ? contentHeight : 0
                        visible: expandedMarkdownColumn.visible
                        text: itemWrapper.markdownSource
                        textFormat: TextEdit.MarkdownText
                        color: "white"
                        wrapMode: TextEdit.Wrap
                        readOnly: true
                        selectByMouse: true
                        activeFocusOnPress: false
                        cursorVisible: false

                        onLinkActivated: function(link) {
                            Qt.openUrlExternally(link)
                        }
                    }

                    Item {
                        width: parent.width
                        height: hideButton.implicitHeight + Kirigami.Units.largeSpacing

                        ToolButton {
                            id: hideButton
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            text: qsTr("Hide")
                            display: AbstractButton.TextOnly
                            Accessible.name: qsTr("Ocultar texto completo")

                            onClicked: itemWrapper.markdownExpanded = false
                        }
                    }
                }
            }
        }

        Column {
            id: actionColumn
            z: 3
            anchors.right: parent.right
            anchors.rightMargin: Kirigami.Units.largeSpacing
            anchors.verticalCenter: cardBackground.verticalCenter
            spacing: Kirigami.Units.smallSpacing

            Row {
                spacing: Kirigami.Units.smallSpacing

                ToolButton {
                    id: detailButton
                    icon.name: "application-menu-symbolic"
                    display: AbstractButton.IconOnly
                    Accessible.name: qsTr("Detalhes")

                    onClicked: {
                        root.subModelTitle = itemWrapper.itemModel.text
                        todoList.parentModelList.push(root.currentModel)
                        todoList.parentModelTitleList.push(itemWrapper.itemModel.text)
                        root.currentModel = todoList.thisModel.get(itemWrapper.modelIndex).sublist
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Abrir subtarefas")
                }

                ToolButton {
                    id: dropdownButton
                    icon.name: "usermenu-down-symbolic"
                    display: AbstractButton.IconOnly
                    Accessible.name: qsTr("Ações")

                    onClicked: dropdownMenu.popup()

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Ações")
                }
            }

            Text {
                text: getCheckedItemCount(todoList.thisModel.get(itemWrapper.modelIndex).sublist)
                      + "/"
                      + todoList.thisModel.get(itemWrapper.modelIndex).sublist.count
                visible: todoList.thisModel.get(itemWrapper.modelIndex).sublist.count !== 0
                color: "white"
                anchors.right: parent.right
            }
        }

        Menu {
            id: dropdownMenu

            MenuItem {
                text: Boolean(itemWrapper.itemModel.pinned)
                      ? qsTr("unpin")
                      : qsTr("pin to top")
                icon.name: "window-pin"

                onTriggered: todoList.togglePinnedItem(itemWrapper.modelIndex)
            }

            MenuSeparator { }

            MenuItem {
                text: qsTr("remove")
                icon.name: "edit-delete"

                onTriggered: {
                    todoList.thisModel.remove(itemWrapper.modelIndex)
                    saveModelToJson("todoListModel", todoListModel)
                }
            }

            MenuItem {
                text: qsTr("edit")
                icon.name: "document-edit"

                onTriggered: editPopup.open()
            }

            MenuItem {
                text: itemWrapper.markdownSource.length > 0
                      ? qsTr("edit text")
                      : qsTr("add text")
                icon.name: "text-x-markdown"

                onTriggered: markdownPopup.open()
            }
        }

        Popup {
            id: editPopup
            parent: Overlay.overlay
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            width: Math.max(280, Math.min(520, parent.width - Kirigami.Units.largeSpacing * 2))
            height: Math.max(180, Math.min(320, parent.height - Kirigami.Units.largeSpacing * 2))
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            padding: Kirigami.Units.largeSpacing

            onOpened: {
                editTextArea.text = itemWrapper.itemModel.text || ""
                editTextArea.forceActiveFocus()
                editTextArea.selectAll()
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                TextArea {
                    id: editTextArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    wrapMode: TextArea.Wrap
                    placeholderText: qsTr("Editar tarefa")
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("Cancelar")
                        onClicked: editPopup.close()
                    }

                    Button {
                        text: qsTr("Salvar")
                        highlighted: true

                        onClicked: {
                            todoList.thisModel.setProperty(itemWrapper.modelIndex, "text", editTextArea.text)
                            saveModelToJson("todoListModel", todoListModel)
                            editPopup.close()
                        }
                    }
                }
            }
        }

        Popup {
            id: markdownPopup
            parent: Overlay.overlay
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            width: Math.max(300, Math.min(680, parent.width - Kirigami.Units.largeSpacing * 2))
            height: Math.max(340, Math.min(560, parent.height - Kirigami.Units.largeSpacing * 2))
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            padding: Kirigami.Units.largeSpacing

            onOpened: {
                markdownEditor.text = itemWrapper.markdownSource
                markdownTabs.currentIndex = 0
                markdownEditor.forceActiveFocus()
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Texto em Markdown")
                    font.bold: true
                    font.pixelSize: 18
                }

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Aceita títulos, listas, links, imagens, tabelas, citações, código, negrito, itálico e tachado.")
                    wrapMode: Text.Wrap
                    opacity: 0.75
                }

                TabBar {
                    id: markdownTabs
                    Layout.fillWidth: true

                    TabButton { text: qsTr("Editar") }
                    TabButton { text: qsTr("Visualizar") }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: markdownTabs.currentIndex

                    ScrollView {
                        id: editorScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextArea {
                            id: markdownEditor
                            width: editorScroll.availableWidth
                            wrapMode: TextArea.Wrap
                            placeholderText: qsTr("# Título\n\nEscreva aqui usando **Markdown**...")
                            selectByMouse: true

                            Keys.onPressed: function(event) {
                                if ((event.modifiers & Qt.ControlModifier)
                                        && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                    markdownPopup.saveMarkdown()
                                    event.accepted = true
                                }
                            }
                        }
                    }

                    ScrollView {
                        id: previewScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextEdit {
                            width: previewScroll.availableWidth
                            height: Math.max(previewScroll.availableHeight, contentHeight)
                            text: markdownEditor.text.length > 0
                                  ? markdownEditor.text
                                  : qsTr("*A pré-visualização aparecerá aqui.*")
                            textFormat: TextEdit.MarkdownText
                            color: Kirigami.Theme.textColor
                            wrapMode: TextEdit.Wrap
                            readOnly: true
                            selectByMouse: true
                            activeFocusOnPress: false
                            cursorVisible: false

                            onLinkActivated: function(link) {
                                Qt.openUrlExternally(link)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        text: qsTr("Remover texto")
                        enabled: itemWrapper.markdownSource.length > 0

                        onClicked: {
                            markdownEditor.text = ""
                            markdownPopup.saveMarkdown()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("Cancelar")
                        onClicked: markdownPopup.close()
                    }

                    Button {
                        text: qsTr("Salvar")
                        highlighted: true
                        onClicked: markdownPopup.saveMarkdown()
                    }
                }
            }

            function saveMarkdown() {
                todoList.thisModel.setProperty(itemWrapper.modelIndex, "markdown", markdownEditor.text)
                saveModelToJson("todoListModel", todoListModel)
                markdownPopup.close()
            }
        }
    }

    displaced: Transition {
        NumberAnimation {
            properties: "y"
            duration: 200
        }
    }


    function countPinnedItems(listModel) {
        if (!listModel || typeof listModel.count !== "number") {
            return 0
        }

        let count = 0
        for (let i = 0; i < listModel.count; i++) {
            if (Boolean(listModel.get(i).pinned)) {
                count++
            }
        }
        return count
    }

    function togglePinnedItem(itemIndex) {
        if (!todoList.thisModel
                || itemIndex < 0
                || itemIndex >= todoList.thisModel.count) {
            return
        }

        let shouldPin = !Boolean(todoList.thisModel.get(itemIndex).pinned)
        todoList.thisModel.setProperty(itemIndex, "pinned", shouldPin)

        if (shouldPin) {
            // The most recently pinned task becomes the first item.
            if (itemIndex !== 0) {
                todoList.thisModel.move(itemIndex, 0, 1)
            }
        } else {
            // Put the task immediately after the remaining pinned group.
            let firstRegularIndex = countPinnedItems(todoList.thisModel)
            if (itemIndex !== firstRegularIndex) {
                todoList.thisModel.move(itemIndex, firstRegularIndex, 1)
            }
        }

        saveModelToJson("todoListModel", todoListModel)
        todoList.positionViewAtBeginning()
    }

    function normalizeSearchText(value) {
        let normalized = value === undefined || value === null ? "" : String(value)

        try {
            normalized = normalized.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
        } catch (error) {
            // Qt 6 normally supports String.normalize; keep plain text as a safe fallback.
        }

        return normalized.toLowerCase()
            .replace(/[áàâãäå]/g, "a")
            .replace(/[éèêë]/g, "e")
            .replace(/[íìîï]/g, "i")
            .replace(/[óòôõö]/g, "o")
            .replace(/[úùûü]/g, "u")
            .replace(/[ç]/g, "c")
            .replace(/[ñ]/g, "n")
            .trim()
    }

    function itemMatchesSearch(item, query) {
        if (!item) {
            return false
        }

        let normalizedQuery = normalizeSearchText(query)
        if (normalizedQuery.length === 0) {
            return true
        }

        let searchableText = normalizeSearchText(
            (typeof item.text === "string" ? item.text : "")
            + "\n"
            + (typeof item.markdown === "string" ? item.markdown : "")
        )
        let terms = normalizedQuery.split(/\s+/)
        let ownItemMatches = true

        for (let termIndex = 0; termIndex < terms.length; termIndex++) {
            if (terms[termIndex].length > 0
                    && searchableText.indexOf(terms[termIndex]) === -1) {
                ownItemMatches = false
                break
            }
        }

        if (ownItemMatches) {
            return true
        }

        let children = item.sublist
        if (children && typeof children.count === "number") {
            for (let childIndex = 0; childIndex < children.count; childIndex++) {
                if (itemMatchesSearch(children.get(childIndex), normalizedQuery)) {
                    return true
                }
            }
        } else if (Array.isArray(children)) {
            for (let arrayIndex = 0; arrayIndex < children.length; arrayIndex++) {
                if (itemMatchesSearch(children[arrayIndex], normalizedQuery)) {
                    return true
                }
            }
        }

        return false
    }

    function countMatchingItems(listModel, query) {
        if (!listModel || typeof listModel.count !== "number") {
            return 0
        }

        if (normalizeSearchText(query).length === 0) {
            return listModel.count
        }

        let resultCount = 0
        for (let i = 0; i < listModel.count; i++) {
            if (itemMatchesSearch(listModel.get(i), query)) {
                resultCount++
            }
        }

        return resultCount
    }

    function firstMarkdownLine(markdown) {
        if (typeof markdown !== "string" || markdown.length === 0) {
            return ""
        }

        let lines = markdown.split(/\r?\n/)
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim()
            if (line.length > 0) {
                return line
            }
        }

        return ""
    }

    function getCheckedItemCount(model) {
        let count = 0
        for (let i = 0; i < model.count; i++) {
            if (model.get(i).checked) {
                count++
            }
        }
        return count
    }
}
