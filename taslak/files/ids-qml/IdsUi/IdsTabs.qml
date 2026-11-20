import QtQuick
import QtQuick.Templates as T
import IdsUi

// Alt çizgili sekme çubuğu. model: ["Scope, 2 s", "FFT", "Bode sweep"]
Item {
    id: root

    property var model: []
    property int currentIndex: 0
    property bool compact: false          // 34 px
    property bool showBaseline: true
    signal activated(int index)

    implicitWidth: row.implicitWidth
    implicitHeight: compact ? 34 : 40

    Rectangle {
        visible: root.showBaseline
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 1
        color: Theme.line
    }

    Row {
        id: row
        height: parent.height
        spacing: 4
        Repeater {
            model: root.model
            delegate: T.AbstractButton {
                id: tab
                required property var modelData
                required property int index
                readonly property bool on: root.currentIndex === index
                height: row.height
                implicitWidth: label.implicitWidth + 28
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                text: modelData
                Accessible.role: Accessible.PageTab
                Accessible.name: text
                Accessible.selected: on
                onClicked: { root.currentIndex = index; root.activated(index) }

                contentItem: Item {}
                background: Item {
                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: tab.text
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsBody
                        font.weight: Font.DemiBold
                        color: tab.on || tab.hovered ? Theme.text : Theme.muted
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 2
                        color: tab.on ? Theme.acc : "transparent"
                    }
                    FocusRing { visible: tab.visualFocus; baseRadius: Theme.rSmall }
                }
            }
        }
    }
}
