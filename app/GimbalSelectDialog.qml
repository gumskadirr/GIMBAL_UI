pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import IDS_GIMBAL

// "Select a gimbal" (design page 6, corrected): one card per gimbal, one selection. The card frame, its radio,
// the highlighted version and the "Selected" line always show the same (gimbal, version) pair; only the selected
// card highlights a version. A click on a card picks its latest version, a click on a version picks that card
// too. Cancel / Esc change nothing; Continue emits accepted(). The choice changes the display only (top bar and
// 3D view), never pages or settings.
IdsPopup {
    id: dialog

    // [{ id, name, versions: ["v1.0", ...], model: Component or null (3D view) }]
    property var gimbals: []
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

    // shortcut: 3 cards per row and no scrolling, enough for the 3 known gimbals; scroll when the list grows.
    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        columns: Math.min(3, Math.max(1, dialog.gimbals.length))
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
                        Layout.preferredHeight: 200
                        radius: Theme.rInp
                        color: Theme.bg
                        border.width: 1
                        border.color: Theme.line2
                        Loader {
                            anchors.fill: parent
                            active: card.modelData.model !== null
                            sourceComponent: card.modelData.model
                        }
                        Column {
                            anchors.centerIn: parent
                            visible: card.modelData.model === null
                            spacing: 8
                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 32; height: 32
                                path: Icons.cube
                                color: Theme.muted
                                strokeWidth: 1.5
                            }
                            Text {
                                text: qsTr("No 3D model yet")
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
