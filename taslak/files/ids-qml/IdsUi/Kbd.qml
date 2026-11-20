import QtQuick
import IdsUi

// Klavye kısayolu ipucu. inverted: vurgu renkli butonun içinde.
Rectangle {
    id: root
    property alias text: label.text
    property bool inverted: false

    implicitHeight: 22
    implicitWidth: Math.max(22, label.implicitWidth + 12)
    radius: Theme.rSmall
    color: inverted ? "#29FFFFFF" : Theme.input
    border.width: 1
    border.color: inverted ? "#59FFFFFF" : Theme.line2

    Text {
        id: label
        anchors.centerIn: parent
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsOverline
        font.weight: Font.Medium
        color: root.inverted ? "#FFFFFF" : Theme.text2
    }
}
