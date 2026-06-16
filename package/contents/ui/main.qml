import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.LocalStorage
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.icon: "checkbox"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.StandardBackground

    toolTipMainText: qsTr("QTodo")
    toolTipSubText: todoListModel.count === 1
        ? qsTr("1 tarefa na lista")
        : qsTr("%1 tarefas na lista").arg(todoListModel.count)

    property var mainModel: todoListModel
    property var currentModel: mainModel
    property bool subModel: mainModel !== currentModel
    property var subModelTitle
    property string searchQuery: ""
    property int dataRevision: 0

    compactRepresentation: MouseArea {
        id: compactRoot

        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: implicitWidth
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        Accessible.name: qsTr("Abrir QTodo")
        Accessible.role: Accessible.Button

        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            id: trayIcon
            anchors.fill: parent
            anchors.margins: Math.max(1, Math.round(parent.width * 0.12))
            source: root.Plasmoid.icon
            active: compactRoot.containsMouse
        }
    }

    fullRepresentation: Item {
        id: mainViewWrapper

        implicitWidth: 420
        implicitHeight: 520
        Layout.minimumWidth: 320
        Layout.minimumHeight: 400
        clip: true

        TodoList {
            id: mainTodoList
            width: parent.width
            anchors.top: mainInputItem.bottom
            anchors.bottom: parent.bottom
            model: root.currentModel
            thisModel: root.currentModel
            searchQuery: root.searchQuery
        }

        Label {
            z: 10
            anchors.centerIn: mainTodoList
            visible: root.searchQuery.trim().length > 0
                     && mainTodoList.matchingItemCount === 0
            text: qsTr("Nenhum resultado encontrado")
            color: Kirigami.Theme.textColor
            opacity: 0.65
            horizontalAlignment: Text.AlignHCenter
        }

        InputItem {
            id: mainInputItem
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.top: searchField.bottom
            thisModel: root.currentModel
        }

        Kirigami.SearchField {
            id: searchField
            width: parent.width * 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: topBarRectangle.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            placeholderText: qsTr("Pesquisar tarefas e textos…")
            Accessible.name: qsTr("Pesquisar tarefas e textos Markdown")

            onTextChanged: root.searchQuery = text

            Keys.onEscapePressed: function(event) {
                if (text.length > 0) {
                    text = ""
                    event.accepted = true
                }
            }
        }

        Rectangle {
            id: topBarRectangle
            visible: root.subModel
            width: parent.width
            height: root.subModel ? Math.max(title.contentHeight + 10, 40) : 0
            radius: 10
            anchors.top: parent.top
            color: "black"
            opacity: 0.3
        }

        Text {
            id: title
            width: parent.width * 0.75
            visible: root.subModel
            text: root.subModelTitle
            font.pixelSize: 18
            color: "white"
            anchors.verticalCenter: topBarRectangle.verticalCenter
            anchors.left: backButton.right
            anchors.leftMargin: 15
            wrapMode: Text.Wrap
        }

        Button {
            id: backButton
            visible: root.subModel
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.verticalCenter: topBarRectangle.verticalCenter

            onClicked: {
                var parentModel = mainTodoList.parentModelList[mainTodoList.parentModelList.length - 1]
                var parentModelTitle = mainTodoList.parentModelTitleList[mainTodoList.parentModelTitleList.length - 2]

                root.currentModel = parentModel
                root.subModelTitle = parentModelTitle
                mainTodoList.parentModelList.pop()
                mainTodoList.parentModelTitleList.pop()
            }

            background: Kirigami.Icon {
                id: backIcon
                source: "draw-arrow-back"
                width: Kirigami.Units.iconSizes.medium
                height: width
                anchors.centerIn: parent

                HoverHandler {
                    id: backButtonHoverHandler
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    cursorShape: Qt.PointingHandCursor
                }

                states: [
                    State {
                        when: backButtonHoverHandler.hovered
                        PropertyChanges {
                            target: backIcon
                            opacity: 0.4
                        }
                    }
                ]
            }
        }
    }

    ListModel {
        id: todoListModel

        Component.onCompleted: {
            loadModelFromJson("todoListModel", todoListModel)
        }
    }

    function modelToArray(listModel) {
        let jsonArray = []

        for (let i = 0; i < listModel.count; i++) {
            let item = listModel.get(i)
            let children = []

            if (item.sublist && typeof item.sublist.count === "number") {
                children = modelToArray(item.sublist)
            } else if (Array.isArray(item.sublist)) {
                for (let childIndex = 0; childIndex < item.sublist.length; childIndex++) {
                    children.push(normalizeItem(item.sublist[childIndex]))
                }
            }

            jsonArray.push({
                text: typeof item.text === "string" ? item.text : "",
                color: typeof item.color === "string" ? item.color : "white",
                checked: Boolean(item.checked),
                pinned: Boolean(item.pinned),
                markdown: typeof item.markdown === "string" ? item.markdown : "",
                sublist: children
            })
        }

        return jsonArray
    }

    function saveModelToJson(fileName, listModel) {
        root.dataRevision++
        let jsonString = JSON.stringify(modelToArray(listModel))
        let file = LocalStorage.openDatabaseSync("qtodo", "1.0", "StorageDatabase", 5000000)
        file.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS ListData (id TEXT UNIQUE, data TEXT)")
            tx.executeSql("INSERT OR REPLACE INTO ListData VALUES(?, ?)", [fileName, jsonString])
        })
    }

    function normalizeItem(item) {
        let normalized = {
            text: typeof item.text === "string" ? item.text : "",
            color: typeof item.color === "string" ? item.color : "white",
            checked: Boolean(item.checked),
            pinned: Boolean(item.pinned),
            markdown: typeof item.markdown === "string" ? item.markdown : "",
            sublist: []
        }

        if (Array.isArray(item.sublist)) {
            for (let i = 0; i < item.sublist.length; i++) {
                normalized.sublist.push(normalizeItem(item.sublist[i]))
            }
        }

        return normalized
    }

    function loadModelFromJson(fileName, listModel) {
        let file = LocalStorage.openDatabaseSync("qtodo", "1.0", "StorageDatabase", 5000000)
        let jsonString = ""

        file.transaction(function(tx) {
            let rs = tx.executeSql("SELECT data FROM ListData WHERE id=?", [fileName])
            if (rs.rows.length > 0) {
                jsonString = rs.rows.item(0).data
            }
        })

        if (jsonString !== "") {
            let jsonArray = JSON.parse(jsonString)
            listModel.clear()
            for (let i = 0; i < jsonArray.length; i++) {
                listModel.append(normalizeItem(jsonArray[i]))
            }
        }
    }
}
