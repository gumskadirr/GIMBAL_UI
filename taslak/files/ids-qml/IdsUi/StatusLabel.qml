import QtQuick
import IdsUi

// Noktalı durum metni. framed: true → üst çubuktaki "Connected" hapı.
Rectangle {
    id: root

    property string status: "ok"
    property alias text: label.text
    property bool framed: false
    property int fontSize: Theme.fsBody
    property int fontWeight: Font.Medium
    property color textColor: framed ? _t.fg : Theme.text2
    readonly property var _t: Theme.tone(status === "idle" ? "neutral" : status)

    implicitHeight: framed ? Theme.controlHeightSm : row.implicitHeight
    implicitWidth: row.implicitWidth + (framed ? 24 : 0)
    radius: Theme.rBtn
    color: framed ? _t.bg : "transparent"
    border.width: framed ? 1 : 0
    border.color: _t.border
    Accessible.role: Accessible.StaticText
    Accessible.name: label.text

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        StatusDot {
            anchors.verticalCenter: parent.verticalCenter
            status: root.status
        }
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontSans
            font.pixelSize: root.fontSize
            font.weight: root.fontWeight
            color: root.textColor
        }
    }
}
