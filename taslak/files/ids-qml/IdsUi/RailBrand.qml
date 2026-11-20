import QtQuick
import IdsUi

// Logo + bağlantı noktası + başlık. connected=false → gri nokta.
Item {
    id: root

    property var rail: null
    property url logoSource: ""
    property string title: ""
    property string subtitle: ""
    property bool connected: true
    property string connectionLabel: connected ? qsTr("Connected") : qsTr("Disconnected")
    readonly property bool revealed: rail ? rail.expanded : true

    width: parent ? parent.width : 224
    implicitHeight: 50          // 40 + 10 alt boşluk

    Row {
        x: 6
        height: 40
        spacing: 12

        Item {
            width: logo.status === Image.Ready ? logo.width : 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            Image {
                id: logo
                height: 28
                fillMode: Image.PreserveAspectFit
                source: root.logoSource
                Accessible.name: root.title
            }
            Rectangle {
                visible: logo.status !== Image.Ready
                anchors.fill: parent
                radius: Theme.rSmall
                color: Theme.acc
            }
            Rectangle {
                x: parent.width - 4
                y: -3
                width: 10; height: 10; radius: 5
                color: root.connected ? Theme.dotOk : Theme.idle
                border.width: 2
                border.color: Theme.rail
                Accessible.role: Accessible.Indicator
                Accessible.name: root.connectionLabel
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.revealed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Text {
                text: root.title
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsH2
                font.weight: Font.Bold
                color: Theme.text
            }
            Text {
                text: root.subtitle
                visible: text !== ""
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsSmall
                color: Theme.label
            }
        }
    }
}
