import QtQuick
import QtQuick.Layouts
import IdsUi

// İkonlu açıklama satırı. kind: "info" | "warning"
RowLayout {
    id: root
    property string kind: "info"
    property alias text: label.text
    property color iconColor: Theme.muted

    spacing: 8

    Icon {
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: 2
        Layout.preferredWidth: 15
        Layout.preferredHeight: 15
        path: root.kind === "warning" ? Icons.warning : Icons.info
        color: root.iconColor
    }
    Text {
        id: label
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsSmall
        lineHeight: 1.5
        color: Theme.muted
    }
}
