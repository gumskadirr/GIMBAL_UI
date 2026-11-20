pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Controls.Basic
import IDS_GIMBAL

// "Select a gimbal" (design page 6, corrected): one card per gimbal, one selection. The card frame, its radio,
// the highlighted version and the "Selected" line always show the same (gimbal, version) pair; only the selected
// card highlights a version. A click on a card picks its latest version, a click on a version picks that card
// too. Cancel / Esc change nothing; Continue emits accepted(). The choice changes the display only (top bar and
// 3D view), never pages or settings.
IdsPopup {
    id: dialog

    // GimbalLibrary entries: [{ id, name, versions: ["v1.0", ...], model: 3D files and axes or null }]
    property var gimbals: []
    property GimbalLibrary library: null // adds, edits and deletes; null hides those controls
    property string currentId: ""      // saved choice; "CURRENT" badge
    property string currentVersion: ""
    property bool onStart: true
    property string selectedId: ""
    property string selectedVersion: ""
    readonly property var selected: gimbals.find(g => g.id === selectedId) ?? null
    signal accepted(string id, string version, bool onStart)

    function select(id: string, version: string) {
        selectedId = id
        selectedVersion = version
    }
    // After an edit the selection stays valid: a removed version falls back to the last one.
    function reselect(id: string) {
        const g = gimbals.find(g => g.id === id)
        if (!g)
            select("", "")
        else if (!(selectedId === id && g.versions.includes(selectedVersion)))
            select(id, g.versions[g.versions.length - 1])
    }

    parent: T.Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: Math.min(parent ? parent.width - 64 : 1000, 1000)
    padding: 28
    onAboutToShow: {
        const saved = gimbals.find(g => g.id === currentId)
        if (saved && saved.versions.includes(currentVersion))
            select(currentId, currentVersion)
        else
            select("", "")
        onStartSwitch.checked = onStart
    }
    onOpened: (selected ? continueButton : cancelButton).forceActiveFocus()

    Text {
        Layout.fillWidth: true
        text: qsTr("Select a gimbal")
        font.family: Theme.fontSans
        font.pixelSize: 24
        font.weight: Font.Bold
        color: Theme.text
        Accessible.role: Accessible.Heading
        Accessible.name: text
    }
    Text {
        Layout.fillWidth: true
        Layout.topMargin: -6
        text: qsTr("Choose the pan-tilt gimbal you are working with. The 3D view shows the selected model; pages and settings do not change.")
        wrapMode: Text.WordWrap
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsBody
        color: Theme.muted
    }

    GimbalEditDialog {
        id: editDialog
        objectName: "gimbalEditDialog"
        library: dialog.library
        onSaved: id => dialog.reselect(id)
    }
    ConfirmDialog {
        id: deleteDialog
        objectName: "gimbalDeleteDialog"
        property var gimbal: null
        title: qsTr("Delete gimbal")
        text: gimbal ? qsTr("Delete %1? Its 3D model files are deleted too.").arg(gimbal.name) : ""
        danger: true
        acceptText: qsTr("Delete")
        onConfirmed: {
            const id = gimbal.id
            dialog.library.remove(id)
            if (dialog.selectedId === id)
                dialog.select("", "")
        }
    }

    // Four cards per row; scrolls when the rows do not fit the window.
    Flickable {
        id: cardScroller
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.preferredHeight: Math.min(cardGrid.implicitHeight, (dialog.parent ? dialog.parent.height : 800) - 300)
        contentHeight: cardGrid.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: ScrollBar {}

        GridLayout {
            id: cardGrid
            width: cardScroller.width
            columns: 4
            columnSpacing: 16
            rowSpacing: 16

            Repeater {
                model: dialog.gimbals
                Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool isSelected: dialog.selectedId === modelData.id
                    objectName: "gimbalCard-" + modelData.id
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1 // equal columns
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: cardColumn.implicitHeight + 36
                    radius: Theme.rCard
                    color: Theme.card
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? Theme.acc : Theme.line
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: modelData.name
                    Accessible.checked: isSelected

                    function pick() {
                        if (!isSelected)
                            dialog.select(modelData.id, modelData.versions[modelData.versions.length - 1])
                    }

                    TapHandler { onTapped: card.pick() }

                    ColumnLayout {
                        id: cardColumn
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.name
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                color: Theme.text
                            }
                            Badge {
                                visible: card.modelData.id === dialog.currentId
                                kind: "info"
                                text: qsTr("Current")
                            }
                            Rectangle { // radio
                                implicitWidth: 18; implicitHeight: 18; radius: 9
                                color: "transparent"
                                border.width: 1.5
                                border.color: card.isSelected ? Theme.acc : Theme.muted
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8; height: 8; radius: 4
                                    color: Theme.acc
                                    visible: card.isSelected
                                }
                            }
                        }

                        Rectangle { // picture: the gimbal's 3D model when there is one
                            Layout.fillWidth: true
                            Layout.preferredHeight: 160
                            radius: Theme.rInp
                            color: Theme.bg
                            border.width: 1
                            border.color: Theme.line2
                            GimbalView {
                                id: preview
                                anchors.fill: parent
                                model: card.modelData.model
                                interactive: false
                            }
                            Column {
                                anchors.centerIn: parent
                                visible: !preview.shown
                                spacing: 8
                                Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 32; height: 32
                                    path: Icons.cube
                                    color: Theme.muted
                                    strokeWidth: 1.5
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: card.modelData.model === null ? qsTr("No 3D model yet") : qsTr("No 3D view")
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fsSmall
                                    color: Theme.muted
                                }
                            }
                        }

                        Text {
                            text: qsTr("Version")
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fsOverline
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.overlineSpacing
                            font.capitalization: Font.AllUppercase
                            color: Theme.label
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Flow {
                                Layout.fillWidth: true
                                spacing: 8
                                Repeater {
                                    model: card.modelData.versions
                                    IdsButton {
                                        id: versionButton
                                        required property string modelData
                                        readonly property bool isSelected: card.isSelected && dialog.selectedVersion === modelData
                                        objectName: "version-" + card.modelData.id + "-" + modelData
                                        compact: true
                                        variant: isSelected ? "primary" : "secondary"
                                        text: modelData
                                        font.family: Theme.fontMono
                                        Accessible.name: card.modelData.name + " " + modelData
                                        Accessible.checked: isSelected
                                        onClicked: dialog.select(card.modelData.id, modelData)
                                    }
                                }
                            }
                            IdsButton {
                                objectName: "gimbalEdit-" + card.modelData.id
                                Layout.alignment: Qt.AlignBottom
                                visible: dialog.library !== null
                                compact: true
                                variant: "quiet"
                                iconPath: Icons.pencil
                                Accessible.name: qsTr("Edit %1").arg(card.modelData.name)
                                onClicked: editDialog.openFor(card.modelData)
                            }
                            IdsButton {
                                objectName: "gimbalDelete-" + card.modelData.id
                                Layout.alignment: Qt.AlignBottom
                                visible: dialog.library !== null
                                compact: true
                                variant: "quiet"
                                iconPath: Icons.trash
                                Accessible.name: qsTr("Delete %1").arg(card.modelData.name)
                                onClicked: {
                                    deleteDialog.gimbal = card.modelData
                                    deleteDialog.open()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { // "+ New gimbal"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumHeight: 120
                visible: dialog.library !== null
                radius: Theme.rCard
                color: "transparent"
                border.width: 1
                border.color: Theme.line2
                IdsButton {
                    objectName: "gimbalAdd"
                    anchors.centerIn: parent
                    iconPath: Icons.plus
                    text: qsTr("New gimbal")
                    onClicked: editDialog.openFor(null)
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        height: 1
        color: Theme.line
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ToggleRow {
            id: onStartSwitch
            objectName: "gimbalOnStart"
            text: qsTr("Open this gimbal on start")
        }
        Item { Layout.fillWidth: true }
        Text {
            objectName: "gimbalSelected"
            text: dialog.selected ? qsTr("Selected <b>%1 · %2</b>").arg(dialog.selected.name).arg(dialog.selectedVersion)
                                  : qsTr("No gimbal selected")
            textFormat: Text.StyledText
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: Theme.muted
        }
        IdsButton {
            id: cancelButton
            objectName: "gimbalCancel"
            variant: "quiet"
            text: qsTr("Cancel")
            onClicked: dialog.close()
        }
        IdsButton {
            id: continueButton
            objectName: "gimbalContinue"
            variant: "primary"
            text: qsTr("Continue")
            trailingIconPath: Icons.arrowRight
            enabled: dialog.selected !== null
            onClicked: {
                dialog.close()
                dialog.accepted(dialog.selectedId, dialog.selectedVersion, onStartSwitch.checked)
            }
        }
    }
}
