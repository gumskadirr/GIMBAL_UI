import QtQuick
import IDS_GIMBAL

// kind: "ok" | "warn" | "crit" | "info" | "neutral", e.g. Badge { kind: "ok"; text: "NORMAL" }
Rectangle {
    id: root

    property string kind: "info"
    property alias text: label.text
    readonly property var _t: Theme.tone(kind)

    implicitHeight: 22
    implicitWidth: label.implicitWidth + 18
    radius: Theme.rBtn
    color: _t.bg
    border.width: 1
    border.color: _t.border
    Accessible.role: Accessible.StaticText
    Accessible.name: label.text

    Text {
        id: label
        anchors.centerIn: parent
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: 0.44
        font.capitalization: Font.AllUppercase
        color: root._t.fg
    }
}
